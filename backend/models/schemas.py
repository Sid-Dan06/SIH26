"""
Pydantic models for the Adaptive IT Training System.

Keeping these in one place means every part of the backend (assessment,
adaptive engine, AI content generator) agrees on the exact shape of the data.
"""

from enum import Enum
from typing import List, Optional
from pydantic import BaseModel, Field, field_validator


class Skill(str, Enum):
    PYTHON = "Python"
    SQL = "SQL"
    GIT = "Git"
    LINUX = "Linux"


class Difficulty(str, Enum):
    EASY = "Easy"
    MEDIUM = "Medium"
    HARD = "Hard"


class Question(BaseModel):
    question_id: str
    skill: Skill
    topic: str
    difficulty: Difficulty
    question: str
    options: List[str] = Field(min_length=4, max_length=4)
    correct_answer: str

    @field_validator("correct_answer")
    @classmethod
    def correct_answer_must_be_in_options(cls, v, info):
        options = info.data.get("options")
        if options is not None and v not in options:
            raise ValueError(f"correct_answer '{v}' is not one of the options {options}")
        return v

    @field_validator("options")
    @classmethod
    def options_must_be_unique(cls, v):
        if len(set(v)) != len(v):
            raise ValueError("options contain duplicates")
        return v


class QuestionResponse(BaseModel):
    """A single answer submitted by a user during the assessment."""
    question_id: str
    selected_answer: str
    time_taken_seconds: float = Field(ge=0)


class AssessmentSubmission(BaseModel):
    """Payload the frontend sends when the user finishes the pre-assessment."""
    user_id: str
    responses: List[QuestionResponse]


class GeneratedMCQ(BaseModel):
    """
    One AI-generated multiple choice question.

    Same validation rules as the pre-assessment Question model (exactly 4
    options, correct_answer must be one of them, no duplicates) — spec
    section 12 requires this before showing AI content to the user.
    """
    question: str
    options: List[str] = Field(min_length=4, max_length=4)
    correct_answer: str

    @field_validator("correct_answer")
    @classmethod
    def correct_answer_must_be_in_options(cls, v, info):
        options = info.data.get("options")
        if options is not None and v not in options:
            raise ValueError(f"correct_answer '{v}' is not one of the options {options}")
        return v

    @field_validator("options")
    @classmethod
    def options_must_be_unique(cls, v):
        if len(set(v)) != len(v):
            raise ValueError("options contain duplicates")
        return v


class GeneratedLesson(BaseModel):
    """
    Full AI-generated learning content for one topic (spec section 11):
    explanation, examples, MCQs, a practical exercise, and an optional
    mini-project for high performers.
    """
    topic: str
    difficulty: str
    explanation: str
    examples: List[str] = Field(min_length=1)
    mcqs: List[GeneratedMCQ] = Field(min_length=1)
    exercise: str
    mini_project: Optional[str] = None