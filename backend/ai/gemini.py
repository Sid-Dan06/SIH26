import os
from pathlib import Path
from dotenv import load_dotenv
from google import genai

# Correctly resolves path to backend/.env relative to this file
env_path = Path(__file__).resolve().parent.parent / ".env"
load_dotenv(env_path)

api_key = os.getenv("GEMINI_API_KEY")


def generate_learning_content(recommendation: dict) -> str:
    if not api_key:
        raise RuntimeError("GEMINI_API_KEY is not configured in backend/.env")
    client = genai.Client(api_key=api_key)
    prompt = f"""
You are an adaptive learning assistant.

Generate personalized learning content based ONLY on the recommendation
provided by the adaptive engine.

Student learning recommendation:

Skill: {recommendation['skill']}
Topic: {recommendation['topic']}
Mastery: {recommendation['mastery']}%
Difficulty: {recommendation['difficulty']}
Content Type: {recommendation['content_type']}
Reason: {recommendation['reason']}

Your job is to generate the requested learning material.

Rules:
- Match the requested difficulty exactly.
- Focus specifically on the given topic.
- Do not change the recommended topic.
- Do not decide a different difficulty.
- Explain concepts clearly and simply.
- Generate content appropriate for the student's mastery level.

Return the content in a clear structured format.
"""

    response = client.models.generate_content(
        model="gemini-2.5-flash",
        contents=prompt
    )

    return response.text
