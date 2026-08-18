"""
Scoring engine.

Takes a user's submitted answers (AssessmentSubmission) and turns them into
a topic-level skill profile with an explainable mastery score per topic.

This does NOT decide what to recommend next — that's the adaptive engine's
job (adaptive/skill_gap.py, adaptive/recommender.py), built after this.
This module only answers one question: "how well does the user currently
know each topic?"
"""

from collections import defaultdict
from typing import Dict, List

from models.schemas import AssessmentSubmission, Question

# --- Configurable weights (spec section 5) -----------------------------
# mastery_score = 0.60 * accuracy + 0.25 * difficulty_performance + 0.15 * response_time_score
ACCURACY_WEIGHT = 0.60
DIFFICULTY_WEIGHT = 0.25
RESPONSE_TIME_WEIGHT = 0.15

# Used to weight harder questions more heavily in difficulty_performance
DIFFICULTY_POINTS = {"Easy": 1, "Medium": 2, "Hard": 3}

# A response taken longer than this (seconds) scores 0 on response_time_score.
# Configurable — tune this once you see real timing data.
MAX_EXPECTED_TIME_SECONDS = 60


def _response_time_score(avg_time_seconds: float) -> float:
    """
    Simple explainable scoring: faster average response time -> higher score.
    Capped at 0 for anything at/above MAX_EXPECTED_TIME_SECONDS.
    """
    score = 1 - (avg_time_seconds / MAX_EXPECTED_TIME_SECONDS)
    return max(0.0, min(1.0, score))


def score_submission(
    submission: AssessmentSubmission,
    question_bank: List[Question],
) -> Dict[str, Dict[str, dict]]:
    """
    Score a user's assessment submission and return a topic-level skill profile.

    Returns a nested dict:
    {
        "Python": {
            "OOP": {
                "mastery": 42.0,
                "accuracy": 0.33,
                "difficulty_performance": 0.5,
                "response_time_score": 0.8,
                "correct": 1,
                "total": 3,
            },
            ...
        },
        "SQL": {...},
        ...
    }
    """
    # Quick lookup: question_id -> Question object
    questions_by_id = {q.question_id: q for q in question_bank}

    # Group raw responses by (skill, topic)
    grouped = defaultdict(list)  # key: (skill, topic) -> list of (response, question)

    for response in submission.responses:
        question = questions_by_id.get(response.question_id)
        if question is None:
            # Defensive: skip responses that don't match a known question
            # rather than crashing the whole scoring run.
            continue
        grouped[(question.skill.value, question.topic)].append((response, question))

    # Build the topic-level profile
    profile: Dict[str, Dict[str, dict]] = defaultdict(dict)

    for (skill, topic), items in grouped.items():
        total = len(items)
        correct = sum(1 for r, q in items if r.selected_answer == q.correct_answer)

        accuracy = correct / total

        # Difficulty performance: correct points earned / total points possible
        points_earned = sum(
            DIFFICULTY_POINTS[q.difficulty.value]
            for r, q in items
            if r.selected_answer == q.correct_answer
        )
        points_possible = sum(DIFFICULTY_POINTS[q.difficulty.value] for r, q in items)
        difficulty_performance = points_earned / points_possible if points_possible else 0.0

        avg_time = sum(r.time_taken_seconds for r, q in items) / total
        response_time_score = _response_time_score(avg_time)

        mastery = (
            ACCURACY_WEIGHT * accuracy
            + DIFFICULTY_WEIGHT * difficulty_performance
            + RESPONSE_TIME_WEIGHT * response_time_score
        ) * 100  # express as a percentage, matching spec examples like "OOP -> 42%"

        profile[skill][topic] = {
            "mastery": round(mastery, 1),
            "accuracy": round(accuracy, 2),
            "difficulty_performance": round(difficulty_performance, 2),
            "response_time_score": round(response_time_score, 2),
            "correct": correct,
            "total": total,
        }

    return dict(profile)


def explain_topic_score(skill: str, topic: str, topic_data: dict) -> str:
    """
    Human-readable explanation of how a topic's mastery score was calculated.
    This is what section 16 (Explainability) asks for.
    """
    return (
        f"{skill} - {topic}: {topic_data['mastery']}% mastery "
        f"({topic_data['correct']}/{topic_data['total']} correct, "
        f"accuracy={topic_data['accuracy']}, "
        f"difficulty_performance={topic_data['difficulty_performance']}, "
        f"response_time_score={topic_data['response_time_score']})"
    )


if __name__ == "__main__":
    # Manual sanity check: simulate a user submitting answers to the real
    # question bank, with a deliberate mix of correct/incorrect answers so
    # we can see the topic profile come out differently per topic.
    import random
    from assessment.Assessment import get_pre_assessment_questions
    from models.schemas import QuestionResponse

    random.seed(42)
    questions = get_pre_assessment_questions()

    responses = []
    for q in questions:
        # Simulate: user gets Python and Git mostly right, SQL and Linux mostly wrong.
        if q.skill.value in ("Python", "Git"):
            is_correct = random.random() < 0.85
        else:
            is_correct = random.random() < 0.30

        if is_correct:
            answer = q.correct_answer
        else:
            wrong_options = [o for o in q.options if o != q.correct_answer]
            answer = random.choice(wrong_options)

        responses.append(
            QuestionResponse(
                question_id=q.question_id,
                selected_answer=answer,
                time_taken_seconds=random.uniform(10, 70),
            )
        )

    submission = AssessmentSubmission(user_id="test_user_1", responses=responses)
    profile = score_submission(submission, questions)

    print("Topic-level skill profile:\n")
    for skill, topics in profile.items():
        print(f"{skill}:")
        for topic, data in topics.items():
            print(f"    {topic} -> {data['mastery']}%")
    print()

    print("Explainability example:\n")
    # Print one full explanation as an example
    first_skill = next(iter(profile))
    first_topic = next(iter(profile[first_skill]))
    print(explain_topic_score(first_skill, first_topic, profile[first_skill][first_topic]))