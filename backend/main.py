"""
FastAPI application — the bridge between any frontend (a test HTML page,
Flutter, Postman, whatever) and the Python "brain" we've already built.

This file does NOT contain any scoring/adaptive logic itself. It only:
    1. Exposes our existing functions as HTTP endpoints
    2. Converts incoming JSON -> Pydantic models -> back to JSON

Run with (from inside backend/):
    uvicorn main:app --reload

Then visit http://127.0.0.1:8000/docs for interactive API docs (FastAPI
generates this automatically — useful for testing endpoints by hand).
"""

from typing import Dict, Optional
from ai.gemini import generate_learning_content
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

from assessment.Assessment import get_pre_assessment_questions
from assessment.scoring import score_submission, build_answer_review
from adaptive.recommender import recommend_next_step
from adaptive.mastery_update import calculate_new_mastery
from models.schemas import AssessmentSubmission

app = FastAPI(title="Adaptive IT Training System")

# Allow requests from a browser test page or Flutter running on a different
# port/origin. Fine to leave wide open ("*") for a hackathon MVP.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/assessment/start")
def start_assessment():
    """
    Return the full pre-assessment question set.

    NOTE: we strip out `correct_answer` before sending to the frontend —
    no reason to hand the answer key to whatever is displaying the quiz.
    """
    questions = get_pre_assessment_questions()
    return [
        {
            "question_id": q.question_id,
            "skill": q.skill.value,
            "topic": q.topic,
            "difficulty": q.difficulty.value,
            "question": q.question,
            "options": q.options,
        }
        for q in questions
    ]


@app.post("/assessment/submit")
def submit_assessment(submission: AssessmentSubmission):
    questions = get_pre_assessment_questions()

    if not submission.responses:
        raise HTTPException(status_code=400, detail="No responses submitted.")

    profile = score_submission(submission, questions)
    recommendation = recommend_next_step(profile)
    answer_review = build_answer_review(submission, questions)

    learning_content = None
    if recommendation:
        learning_content = generate_learning_content(recommendation)

    return {
        "user_id": submission.user_id,
        "skill_profile": profile,
        "recommendation": recommendation,
        "answer_review": answer_review,
        "learning_content": learning_content,
    }


class GenerateContentRequest(BaseModel):
    """What the frontend sends to request AI-generated lesson content.
    Matches the exact shape recommend_next_step() already returns, so the
    frontend can pass the recommendation straight through unchanged."""
    skill: str
    topic: str
    mastery: float
    difficulty: str
    content_type: str
    reason: str


@app.post("/generate-content")
def generate_content(recommendation: GenerateContentRequest):
    """
    Ask Gemini to generate lesson content for a given recommendation.
    """
    try:
        lesson = generate_learning_content(recommendation.model_dump())
        return {"content": lesson}
    except Exception as e:
        raise HTTPException(status_code=502, detail=str(e))


class LearningCompleteRequest(BaseModel):
    """
    Submitted when a user finishes a lesson (quiz + optional exercise).

    NOTE ON STATELESSNESS: we don't have a database yet (that's Phase 3),
    so the client sends back the skill_profile it already has, and this
    endpoint updates just the one topic and recalculates the recommendation
    from that. Once database/database.py exists, this profile will be
    loaded from and saved back to the DB instead of round-tripped by the
    client — the rest of this endpoint's logic won't need to change.
    """
    user_id: str
    skill: str
    topic: str
    quiz_correct: int
    quiz_total: int
    exercise_score: Optional[float] = None
    skill_profile: Dict[str, Dict[str, dict]]


@app.post("/learning/complete")
def complete_learning_session(payload: LearningCompleteRequest):
    """
    Close the adaptive feedback loop (spec section 15):
        1. Recalculate mastery for the topic just studied
        2. Update that topic in the skill profile
        3. Re-run the adaptive engine to get the NEXT recommendation

    This proves the loop: mastery goes up -> next recommendation changes.
    """
    if payload.skill not in payload.skill_profile:
        raise HTTPException(status_code=400, detail=f"Unknown skill: {payload.skill}")
    if payload.topic not in payload.skill_profile[payload.skill]:
        raise HTTPException(status_code=400, detail=f"Unknown topic: {payload.topic}")

    old_topic_data = payload.skill_profile[payload.skill][payload.topic]

    mastery_result = calculate_new_mastery(
        old_mastery=old_topic_data["mastery"],
        quiz_correct=payload.quiz_correct,
        quiz_total=payload.quiz_total,
        exercise_score=payload.exercise_score,
    )

    # Update just this topic's mastery in the profile; keep its other
    # stored fields (accuracy, difficulty_performance, etc.) as-is since
    # they describe the ORIGINAL assessment, not this new session.
    updated_profile = payload.skill_profile.copy()
    updated_profile[payload.skill] = updated_profile[payload.skill].copy()
    updated_profile[payload.skill][payload.topic] = {
        **old_topic_data,
        "mastery": mastery_result["new_mastery"],
    }

    new_recommendation = recommend_next_step(updated_profile)

    return {
        "user_id": payload.user_id,
        "mastery_update": mastery_result,
        "updated_skill_profile": updated_profile,
        "new_recommendation": new_recommendation,
    }



@app.get("/")
def root():
    return {"status": "Adaptive IT Training backend is running."}