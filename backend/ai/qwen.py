"""
Qwen (via Ollama) integration.

This file talks to your LOCAL Ollama server and asks Qwen to generate
lesson content for whatever topic/difficulty the adaptive engine decided.

It does NOT make any teaching decisions itself — see ai/prompts.py's
docstring for why that separation matters (spec section 27).

Requires Ollama running locally (default: http://localhost:11434) with the
model already pulled, e.g.:
    ollama pull qwen3:8b
"""

import json
import re

import requests
from pydantic import ValidationError

from ai.prompts import build_content_prompt
from models.schemas import GeneratedLesson

OLLAMA_URL = "http://localhost:11434/api/generate"
MODEL_NAME = "qwen3:8b"   # matches `ollama list` on this machine
MAX_ATTEMPTS = 3           # spec section 12: regenerate on validation failure


class ContentGenerationError(Exception):
    """Raised when Qwen fails to produce valid content after MAX_ATTEMPTS."""
    pass


def _call_ollama(prompt: str) -> str:
    """
    Send a prompt to the local Ollama server and return the raw text response.
    Raises requests.RequestException if Ollama isn't reachable.
    """
    response = requests.post(
        OLLAMA_URL,
        json={
            "model": MODEL_NAME,
            "prompt": prompt,
            "stream": False,
            # Lower temperature = more consistent, structured output.
            # We want reliable JSON, not creative variation, here.
            "options": {"temperature": 0.3},
        },
        timeout=120,
    )
    response.raise_for_status()
    return response.json()["response"]


def _extract_json(raw_text: str) -> dict:
    """
    Qwen sometimes wraps JSON in markdown fences or adds stray text before/
    after it despite instructions. This pulls out the first {...} block and
    parses it, rather than assuming the whole response is clean JSON.
    """
    match = re.search(r"\{.*\}", raw_text, re.DOTALL)
    if not match:
        raise ValueError("No JSON object found in model response.")

    # strict=False allows literal control characters (like raw newlines)
    # inside JSON string values. Local LLMs frequently emit these even when
    # told not to (e.g. a real line break inside "explanation": "...").
    # Strict JSON forbids this; we relax it here since we only care that
    # the DATA is usable, not that it's byte-perfect JSON.
    return json.loads(match.group(0), strict=False)


def generate_lesson_content(recommendation: dict) -> GeneratedLesson:
    """
    Main entry point: takes the adaptive engine's recommendation, asks Qwen
    to generate content, validates it, and retries (regenerates) up to
    MAX_ATTEMPTS times if validation fails — per spec section 12.

    Returns a validated GeneratedLesson. Raises ContentGenerationError if
    every attempt fails.
    """
    prompt = build_content_prompt(recommendation)
    last_error = None

    for attempt in range(1, MAX_ATTEMPTS + 1):
        try:
            raw_text = _call_ollama(prompt)
            parsed = _extract_json(raw_text)
            lesson = GeneratedLesson(**parsed)
            return lesson  # success — validated and ready to use

        except (ValueError, json.JSONDecodeError, ValidationError) as e:
            last_error = e
            print(f"[attempt {attempt}/{MAX_ATTEMPTS}] Validation failed: {e}")
            continue

        except requests.RequestException as e:
            # Ollama not running / unreachable — no point retrying blindly.
            raise ContentGenerationError(
                f"Could not reach Ollama at {OLLAMA_URL}. "
                f"Is it running? (ollama serve). Original error: {e}"
            )

    raise ContentGenerationError(
        f"Qwen failed to produce valid content after {MAX_ATTEMPTS} attempts. "
        f"Last error: {last_error}"
    )


if __name__ == "__main__":
    # Manual test: run this file directly (from backend/) to confirm Qwen
    # is reachable and produces valid, parseable content.
    #
    #   python -m ai.qwen
    #
    # Uses a hardcoded sample recommendation instead of running the full
    # pipeline, so this can be tested independently of everything else.
    sample_recommendation = {
        "skill": "SQL",
        "topic": "GROUP BY",
        "mastery": 3.1,
        "difficulty": "Beginner",
        "content_type": "Explanation + Lesson + Easy MCQs",
        "reason": "Low mastery, repeated incorrect responses, high response time.",
    }

    print("Sending request to Qwen... (this may take a moment)\n")
    lesson = generate_lesson_content(sample_recommendation)

    print("SUCCESS — validated lesson content:\n")
    print(lesson.model_dump_json(indent=2))