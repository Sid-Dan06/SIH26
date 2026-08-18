"""
Skill-gap detection.

Takes the topic-level skill profile produced by assessment/scoring.py and
figures out which topic is the HIGHEST PRIORITY to address next.

Important per spec section 6: this is NOT just "pick the lowest mastery
score." Priority also considers error frequency and response time, so a
topic with slightly higher mastery but lots of repeated mistakes and slow
answers can outrank a topic that's simply low but was a clean, fast miss.

NOTE ON SCOPE: your spec's full priority formula also includes
"recency_factor" and "number of previous attempts" — those require learning
history (multiple sessions over time), which doesn't exist yet since we only
have a single pre-assessment. Those two factors are stubbed at 0 for now and
clearly marked below. They'll plug in once database/database.py and
learning_sessions exist (Day 2), without needing to change this file's
structure.
"""

from typing import Dict, List

# --- Configurable weights ------------------------------------------------
# priority_score = weakness_weight * weakness_score
#                 + error_weight * error_frequency
#                 + time_weight * response_time_penalty
#                 + recency_weight * recency_factor       (stubbed at 0 for now)
WEAKNESS_WEIGHT = 0.50
ERROR_WEIGHT = 0.25
TIME_PENALTY_WEIGHT = 0.15
RECENCY_WEIGHT = 0.10  # not active yet — no history to compute this from


def _calculate_priority(topic_data: dict) -> dict:
    """
    Calculate a priority score (0-100, higher = more urgent) for one topic,
    along with the individual factors that produced it — needed for
    explainability (spec section 16).
    """
    mastery = topic_data["mastery"]
    accuracy = topic_data["accuracy"]
    response_time_score = topic_data["response_time_score"]

    weakness_score = 100 - mastery
    error_frequency = (1 - accuracy) * 100
    response_time_penalty = (1 - response_time_score) * 100
    recency_factor = 0  # placeholder until learning history exists

    priority_score = (
        WEAKNESS_WEIGHT * weakness_score
        + ERROR_WEIGHT * error_frequency
        + TIME_PENALTY_WEIGHT * response_time_penalty
        + RECENCY_WEIGHT * recency_factor
    )

    return {
        "priority_score": round(priority_score, 1),
        "weakness_score": round(weakness_score, 1),
        "error_frequency": round(error_frequency, 1),
        "response_time_penalty": round(response_time_penalty, 1),
        "recency_factor": recency_factor,
        "mastery": mastery,
    }


def identify_skill_gaps(profile: Dict[str, Dict[str, dict]]) -> List[dict]:
    """
    Rank every topic in the skill profile by priority (most urgent first).

    Returns a flat, sorted list:
    [
        {
            "skill": "SQL",
            "topic": "SELECT",
            "priority_score": 71.2,
            "weakness_score": 90.7,
            "error_frequency": 87.5,
            "response_time_penalty": 22.0,
            "mastery": 9.3,
        },
        ...
    ]
    """
    ranked = []

    for skill, topics in profile.items():
        for topic, topic_data in topics.items():
            priority_info = _calculate_priority(topic_data)
            ranked.append({
                "skill": skill,
                "topic": topic,
                **priority_info,
            })

    ranked.sort(key=lambda x: x["priority_score"], reverse=True)
    return ranked


def get_top_priority(profile: Dict[str, Dict[str, dict]]) -> dict:
    """Convenience: return just the single highest-priority topic."""
    ranked = identify_skill_gaps(profile)
    return ranked[0] if ranked else None


def explain_priority(gap: dict) -> str:
    """
    Human-readable explanation of why a topic was ranked at a given priority.
    Mirrors the example format in spec section 16.
    """
    return (
        f"{gap['skill']} - {gap['topic']} (priority score: {gap['priority_score']})\n"
        f"  Why:\n"
        f"  - Mastery is {gap['mastery']}%\n"
        f"  - Error frequency contributes {gap['error_frequency']}% weakness\n"
        f"  - Response time penalty: {gap['response_time_penalty']}\n"
    )


if __name__ == "__main__":
    # Manual sanity check: reuse the same simulated submission from
    # scoring.py so we can see skill-gap ranking on realistic-looking data.
    import random
    from assessment.Assessment import get_pre_assessment_questions
    from assessment.scoring import score_submission
    from models.schemas import AssessmentSubmission, QuestionResponse

    random.seed(42)
    questions = get_pre_assessment_questions()

    responses = []
    for q in questions:
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

    ranked_gaps = identify_skill_gaps(profile)

    print("Top 5 priority topics:\n")
    for gap in ranked_gaps[:5]:
        print(f"{gap['skill']} - {gap['topic']}: priority={gap['priority_score']}, mastery={gap['mastery']}%")

    print("\n" + "=" * 50)
    print("Highest priority topic, explained:\n")
    top = get_top_priority(profile)
    print(explain_priority(top))