"""
Mastery update logic (spec section 14).

After a user completes a lesson (quiz + optional exercise), this recalculates
their mastery for that ONE topic — blending their previous mastery with how
they just performed, rather than throwing away prior history completely.

This formula was checked directly against your spec's own worked example
(section 14): mastery 31% -> quiz 4/5 -> exercise 80% -> new mastery 55%.
This implementation produces 55.5%, an effective match.
"""

# --- Configurable weights ------------------------------------------------
OLD_MASTERY_WEIGHT = 0.5       # how much prior mastery still counts
NEW_PERFORMANCE_WEIGHT = 0.5   # how much this session's performance counts

QUIZ_WEIGHT_WITHIN_PERFORMANCE = 0.6      # when an exercise score is also given
EXERCISE_WEIGHT_WITHIN_PERFORMANCE = 0.4


def calculate_new_mastery(
    old_mastery: float,
    quiz_correct: int,
    quiz_total: int,
    exercise_score: float = None,
) -> dict:
    """
    Calculate updated mastery for a topic after a learning session.

    exercise_score: 0-100, or None if no exercise was part of this session
    (in which case new_performance is based on the quiz alone).

    Returns a dict with the new mastery plus the components that produced
    it, so this stays explainable (spec section 16) rather than a black box.
    """
    quiz_accuracy_pct = (quiz_correct / quiz_total) * 100 if quiz_total else 0

    if exercise_score is not None:
        new_performance = (
            QUIZ_WEIGHT_WITHIN_PERFORMANCE * quiz_accuracy_pct
            + EXERCISE_WEIGHT_WITHIN_PERFORMANCE * exercise_score
        )
    else:
        new_performance = quiz_accuracy_pct

    new_mastery = (
        OLD_MASTERY_WEIGHT * old_mastery
        + NEW_PERFORMANCE_WEIGHT * new_performance
    )

    new_mastery = max(0.0, min(100.0, new_mastery))  # keep within bounds

    return {
        "old_mastery": round(old_mastery, 1),
        "quiz_accuracy_pct": round(quiz_accuracy_pct, 1),
        "exercise_score": exercise_score,
        "new_performance": round(new_performance, 1),
        "new_mastery": round(new_mastery, 1),
    }


if __name__ == "__main__":
    # Sanity check against your spec's own worked example (section 14):
    # SQL JOIN: 31% -> quiz 4/5 -> exercise 80% -> should land near 55%
    result = calculate_new_mastery(old_mastery=31, quiz_correct=4, quiz_total=5, exercise_score=80)
    print("Spec example check:")
    print(result)
    assert 53 <= result["new_mastery"] <= 57, "Doesn't match spec's expected ~55%"
    print("\nMatches spec's worked example (~55%). ✅")

    # Poor performance case: mastery should stay low / drop
    print("\nPoor performance example:")
    result2 = calculate_new_mastery(old_mastery=42, quiz_correct=1, quiz_total=5, exercise_score=20)
    print(result2)