"""
Assessment engine.

Responsible for ONE thing at this stage: loading the question bank from
data/questions.json, validating it with Pydantic, and handing back the set
of questions used for a user's pre-assessment.

No adaptive logic lives here yet — that comes in Day 1 Step 3+ once we have
scores to work with.
"""

import json
from pathlib import Path
from typing import List

from models.schemas import Question

# data/questions.json lives one level up from this file (backend/data/)
DATA_PATH = Path(__file__).resolve().parent.parent / "data" / "questions.json"


def load_question_bank(path: Path = DATA_PATH) -> List[Question]:
    """
    Load and validate every question in the bank.

    Raises a pydantic.ValidationError immediately if any question is
    malformed — we want bad data to fail loudly at startup, not silently
    during a live assessment.
    """
    with open(path, "r", encoding="utf-8") as f:
        raw_questions = json.load(f)

    return [Question(**q) for q in raw_questions]


def get_pre_assessment_questions() -> List[Question]:
    """
    Return the full question set used for the pre-assessment.

    For the MVP this is simply every question in the bank (40 questions:
    10 per skill). Later this could be randomized, capped, or balanced by
    difficulty — but for Day 1 we keep it simple and predictable so it's
    easy to test.
    """
    return load_question_bank()


def get_questions_by_skill(skill: str) -> List[Question]:
    """Convenience filter, useful for testing and for the /assessment/start endpoint."""
    return [q for q in load_question_bank() if q.skill == skill]


if __name__ == "__main__":
    # Quick manual sanity check: run `python -m assessment.assessment` from
    # the backend/ folder to confirm the question bank loads cleanly.
    questions = get_pre_assessment_questions()
    print(f"Loaded {len(questions)} questions.")

    from collections import Counter
    print("Per skill:", dict(Counter(q.skill.value for q in questions)))
    print("Per difficulty:", dict(Counter(q.difficulty.value for q in questions)))

    print("\nSample question:")
    print(questions[0].model_dump_json(indent=2))