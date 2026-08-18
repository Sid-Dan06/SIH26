"""
Adaptive engine (the "CORE" of the project — spec section 7).

Takes the highest-priority skill gap (from adaptive/skill_gap.py) and decides:
    1. What difficulty level to teach at
    2. What type of content to generate
    3. Why this recommendation was made

This module does NOT talk to any AI model. It only makes the DECISION.
The AI (Qwen, built in ai/qwen.py on Day 2) will later take this decision's
OUTPUT as its input, and generate the actual lesson/MCQ content requested.
That separation is deliberate — per your spec, the LLM must never make this
decision itself.
"""

from typing import Dict

from adaptive.skill_gap import get_top_priority, explain_priority

# --- Difficulty thresholds (spec section 8) — configurable ---------------
DIFFICULTY_THRESHOLDS = [
    (40, "Beginner"),
    (70, "Intermediate"),
    (85, "Advanced"),
    (101, "Challenge"),  # 85%+ (101 as upper bound so 100% still matches)
]

# --- Content type thresholds (spec section 9) — configurable --------------
CONTENT_TYPE_THRESHOLDS = [
    (40, "Explanation + Lesson + Easy MCQs"),
    (60, "Lesson + MCQs + Guided Exercise"),
    (80, "Practical Exercise + Medium/Hard MCQs"),
    (101, "Advanced Challenge / Mini Project"),
]


def decide_difficulty(mastery: float) -> str:
    """
    Map a mastery score to a difficulty level using configurable thresholds.
    Spec section 8:
        < 40%      -> Beginner
        40-70%     -> Intermediate
        70-85%     -> Advanced
        85%+       -> Challenge / Mini Project
    """
    for threshold, label in DIFFICULTY_THRESHOLDS:
        if mastery < threshold:
            return label
    return DIFFICULTY_THRESHOLDS[-1][1]  # fallback, shouldn't normally hit this


def decide_content_type(mastery: float) -> str:
    """
    Map a mastery score to a content type using configurable thresholds.
    Spec section 9.
    """
    for threshold, label in CONTENT_TYPE_THRESHOLDS:
        if mastery < threshold:
            return label
    return CONTENT_TYPE_THRESHOLDS[-1][1]


def _build_reason(gap: dict) -> str:
    """
    Plain-English reason string, matching the style of your spec's example
    (section 7): "Low mastery, repeated incorrect responses, and high
    response time."
    """
    reasons = []

    if gap["mastery"] < 40:
        reasons.append("low mastery")
    elif gap["mastery"] < 70:
        reasons.append("moderate mastery with room to improve")

    if gap["error_frequency"] >= 50:
        reasons.append("repeated incorrect responses")
    elif gap["error_frequency"] > 0:
        reasons.append("some incorrect responses")

    if gap["response_time_penalty"] >= 50:
        reasons.append("high response time")

    if not reasons:
        reasons.append("performance trending well, ready for a harder challenge")

    return ", ".join(reasons).capitalize() + "."


def recommend_next_step(profile: Dict[str, Dict[str, dict]]) -> dict:
    """
    The main adaptive engine function.

    Takes a full topic-level skill profile and returns the single next
    recommendation: topic, difficulty, content type, and reason.

    This is what spec section 7's example output maps to:
        Topic: SQL JOIN
        Difficulty: Beginner
        Content: Lesson + MCQ
        Reason: Low mastery, repeated incorrect responses, and high response time.
    """
    top_gap = get_top_priority(profile)

    if top_gap is None:
        return None

    difficulty = decide_difficulty(top_gap["mastery"])
    content_type = decide_content_type(top_gap["mastery"])
    reason = _build_reason(top_gap)

    return {
        "skill": top_gap["skill"],
        "topic": top_gap["topic"],
        "mastery": top_gap["mastery"],
        "difficulty": difficulty,
        "content_type": content_type,
        "reason": reason,
        "priority_score": top_gap["priority_score"],
    }


def print_recommendation(recommendation: dict) -> None:
    """Pretty-print a recommendation matching the spec's example format."""
    print(f"Topic:\n{recommendation['skill']} {recommendation['topic']}\n")
    print(f"Mastery:\n{recommendation['mastery']}%\n")
    print(f"Difficulty:\n{recommendation['difficulty']}\n")
    print(f"Content:\n{recommendation['content_type']}\n")
    print(f"Reason:\n{recommendation['reason']}\n")


if __name__ == "__main__":
    # Manual sanity check: two simulated users with DIFFERENT weak spots,
    # to prove the engine reacts differently per user — this is the whole
    # point of "adaptive" (spec section 10: two users, same goal, different paths).
    import random
    from assessment.Assessment import get_pre_assessment_questions
    from assessment.scoring import score_submission
    from models.schemas import AssessmentSubmission, QuestionResponse

    def simulate_user(strong_skills, weak_skills, seed):
        random.seed(seed)
        questions = get_pre_assessment_questions()
        responses = []
        for q in questions:
            is_correct = random.random() < (0.85 if q.skill.value in strong_skills else 0.30)
            answer = q.correct_answer if is_correct else random.choice(
                [o for o in q.options if o != q.correct_answer]
            )
            responses.append(QuestionResponse(
                question_id=q.question_id,
                selected_answer=answer,
                time_taken_seconds=random.uniform(10, 70),
            ))
        submission = AssessmentSubmission(user_id="sim_user", responses=responses)
        return score_submission(submission, questions)

    print("=" * 60)
    print("USER A: strong in Python & Git, weak in SQL & Linux")
    print("=" * 60)
    profile_a = simulate_user(["Python", "Git"], ["SQL", "Linux"], seed=42)
    rec_a = recommend_next_step(profile_a)
    print_recommendation(rec_a)

    print("=" * 60)
    print("USER B: strong in SQL & Linux, weak in Python & Git")
    print("=" * 60)
    profile_b = simulate_user(["SQL", "Linux"], ["Python", "Git"], seed=7)
    rec_b = recommend_next_step(profile_b)
    print_recommendation(rec_b)