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

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware

from assessment.Assessment import get_pre_assessment_questions
from assessment.scoring import score_submission
from adaptive.recommender import recommend_next_step
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
    """
    Accept a user's completed assessment, score it, and return:
        - the full topic-level skill profile
        - the top recommendation (topic, difficulty, content type, reason)

    FastAPI + Pydantic automatically validate the incoming JSON against
    AssessmentSubmission — if the frontend sends malformed data, this
    endpoint rejects it before our code even runs.
    """
    questions = get_pre_assessment_questions()

    if not submission.responses:
        raise HTTPException(status_code=400, detail="No responses submitted.")

    profile = score_submission(submission, questions)
    recommendation = recommend_next_step(profile)

    return {
        "user_id": submission.user_id,
        "skill_profile": profile,
        "recommendation": recommendation,
    }


@app.get("/")
def root():
    return {"status": "Adaptive IT Training backend is running."}