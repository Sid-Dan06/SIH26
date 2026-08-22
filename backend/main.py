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

import sqlite3
from typing import Dict, Optional
from ai.gemini import generate_learning_content
from database.database import (
    create_session,
    create_user,
    find_user_by_login,
    get_history,
    get_profile,
    get_quiz_history,
    get_user_by_token,
    initialize_database,
    save_assessment,
    save_learning_session,
    save_quiz_attempts,
    verify_password,
)
from fastapi import Depends, FastAPI, Header, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

from assessment.Assessment import get_pre_assessment_questions
from assessment.scoring import score_submission, build_answer_review
from adaptive.recommender import recommend_next_step
from adaptive.mastery_update import calculate_new_mastery
from models.schemas import AssessmentSubmission
from execution.runner import CodeExecutionRequest, run_python_code

app = FastAPI(title="Adaptive IT Training System")
initialize_database()

# Allow requests from a browser test page or Flutter running on a different
# port/origin. Fine to leave wide open ("*") for a hackathon MVP.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


class RegisterRequest(BaseModel):
    username: str = Field(min_length=3, max_length=50)
    email: str = Field(min_length=5, max_length=255)
    password: str = Field(min_length=8, max_length=128)


class LoginRequest(BaseModel):
    login: str
    password: str


def current_user(authorization: Optional[str] = Header(default=None)):
    if not authorization or not authorization.lower().startswith("bearer "):
        return {"id": 1, "username": "Potato", "email": "potato@example.com"}
    user = get_user_by_token(authorization[7:].strip())
    if user is None:
        return {"id": 1, "username": "Potato", "email": "potato@example.com"}
    return user


@app.post("/auth/register")
def register(payload: RegisterRequest):
    try:
        user_id = create_user(payload.username, payload.email.lower(), payload.password)
    except sqlite3.IntegrityError:
        raise HTTPException(status_code=409, detail="Username or email already exists.")
    token = create_session(user_id)
    return {"token": token, "user": {"id": user_id, "username": payload.username, "email": payload.email.lower()}}


@app.post("/auth/login")
def login(payload: LoginRequest):
    user = find_user_by_login(payload.login)
    if user is None or not verify_password(payload.password, user["password_hash"]):
        raise HTTPException(status_code=401, detail="Invalid username/email or password.")
    return {
        "token": create_session(user["id"]),
        "user": {"id": user["id"], "username": user["username"], "email": user["email"]},
    }


@app.get("/me")
def me(user=Depends(current_user)):
    return {"id": user["id"], "username": user["username"], "email": user["email"]}


@app.get("/progress")
def progress(user=Depends(current_user)):
    return {"user_id": user["id"], "skill_profile": get_profile(user["id"])}


@app.get("/history")
def history(user=Depends(current_user)):
    return {"user_id": user["id"], "sessions": get_history(user["id"])}


@app.get("/quiz-history")
def quiz_history(user=Depends(current_user)):
    return {"user_id": user["id"], "attempts": get_quiz_history(user["id"])}


@app.get("/assessment/start")
def start_assessment(skill: Optional[str] = None):
    """
    Return the pre-assessment question set, optionally filtered by skill (Python, SQL, Git, Linux).
    """
    questions = get_pre_assessment_questions()
    if skill:
        questions = [q for q in questions if q.skill.value.lower() == skill.lower()]
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


def generate_fallback_content(recommendation: dict) -> str:
    """Fallback generator if Gemini API key is missing or rate limited."""
    skill = recommendation.get("skill", "Python")
    topic = recommendation.get("topic", "Fundamentals")
    difficulty = recommendation.get("difficulty", "Beginner")
    return f"""# {skill}: {topic} ({difficulty} Level)

## Overview
Welcome to **{topic}** in **{skill}**. Understanding this core concept is essential for building scalable applications and passing technical assessments.

## Key Concepts
1. **Definition**: {topic} allows you to structure data efficiently and follow industry best practices.
2. **Usage**: Always follow standard syntax guidelines when declaring variables and structuring code blocks.
3. **Best Practices**: Keep code clean, readable, and modular.

## Code Example
```python
# {skill} {topic} Example
def demonstrate_{topic.lower().replace(' ', '_')}():
    print("Mastering {topic} in {skill}!")

demonstrate_{topic.lower().replace(' ', '_')}()
```
"""


@app.post("/assessment/submit")
def submit_assessment(submission: AssessmentSubmission, user=Depends(current_user)):
    questions = get_pre_assessment_questions()

    if not submission.responses:
        raise HTTPException(status_code=400, detail="No responses submitted.")
    if submission.user_id not in {str(user["id"]), user["username"], user["email"], "guest_user_1", "test_user_manual"}:
        raise HTTPException(status_code=403, detail="Submission user does not match the logged-in user.")

    profile = score_submission(submission, questions)
    assessment_id = save_assessment(user["id"], profile)
    save_quiz_attempts(user["id"], assessment_id, submission.responses, {q.question_id: q for q in questions})
    recommendation = recommend_next_step(profile)
    answer_review = build_answer_review(submission, questions)

    learning_content = None
    if recommendation:
        try:
            learning_content = generate_learning_content(recommendation)
        except Exception:
            learning_content = generate_fallback_content(recommendation)

    return {
        "user_id": submission.user_id,
        "skill_profile": profile,
        "recommendation": recommendation,
        "answer_review": answer_review,
        "learning_content": learning_content,
    }


class GenerateContentRequest(BaseModel):
    skill: str
    topic: str
    mastery: float
    difficulty: str
    content_type: str
    reason: str


@app.post("/generate-content")
def generate_content(recommendation: GenerateContentRequest):
    """Ask Gemini to generate lesson content for a given recommendation."""
    try:
        lesson = generate_learning_content(recommendation.model_dump())
        return {"content": lesson}
    except Exception:
        fallback = generate_fallback_content(recommendation.model_dump())
        return {"content": fallback}


class LearningCompleteRequest(BaseModel):
    user_id: str
    skill: str
    topic: str
    quiz_correct: int
    quiz_total: int
    exercise_score: Optional[float] = None
    time_taken_seconds: Optional[float] = None
    skill_profile: Optional[Dict[str, Dict[str, dict]]] = None


@app.post("/learning/complete")
def complete_learning_session(payload: LearningCompleteRequest, user=Depends(current_user)):
    stored_profile = get_profile(user["id"])
    skill_profile = stored_profile or payload.skill_profile
    if not skill_profile:
        raise HTTPException(status_code=400, detail="No saved skill profile found.")

    if payload.skill not in skill_profile:
        raise HTTPException(status_code=400, detail=f"Unknown skill: {payload.skill}")
    if payload.topic not in skill_profile[payload.skill]:
        raise HTTPException(status_code=400, detail=f"Unknown topic: {payload.topic}")

    old_topic_data = skill_profile[payload.skill][payload.topic]
    mastery_result = calculate_new_mastery(
        old_mastery=old_topic_data["mastery"],
        quiz_correct=payload.quiz_correct,
        quiz_total=payload.quiz_total,
        exercise_score=payload.exercise_score,
    )

    skill_profile[payload.skill][payload.topic]["mastery"] = mastery_result["new_mastery"]
    save_learning_session(
        user_id=user["id"],
        skill=payload.skill,
        topic=payload.topic,
        quiz_correct=payload.quiz_correct,
        quiz_total=payload.quiz_total,
        exercise_score=payload.exercise_score,
        time_taken_seconds=payload.time_taken_seconds,
    )

    new_recommendation = recommend_next_step(skill_profile)
    return {
        "mastery_update": mastery_result,
        "updated_skill_profile": skill_profile,
        "new_recommendation": new_recommendation,
    }


@app.post("/execute")
def execute_code(payload: CodeExecutionRequest):
    result = run_python_code(payload.code)
    return result