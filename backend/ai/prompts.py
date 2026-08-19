"""
Prompt construction for the AI content generator.

IMPORTANT (spec section 11 & 27): the adaptive engine has ALREADY decided
what topic, difficulty, and content type to use (see adaptive/recommender.py).
This file does NOT make any of those decisions — it only turns that decision
into a clear instruction for Qwen, and asks for STRUCTURED JSON back instead
of free-form text, so we can validate it before showing it to the user.
"""

import json


def build_content_prompt(recommendation: dict) -> str:
    """
    Build the prompt sent to Qwen, based on the adaptive engine's decision.

    `recommendation` is the exact dict returned by
    adaptive.recommender.recommend_next_step(), e.g.:
        {
            "skill": "SQL",
            "topic": "GROUP BY",
            "mastery": 3.1,
            "difficulty": "Beginner",
            "content_type": "Explanation + Lesson + Easy MCQs",
            "reason": "Low mastery, repeated incorrect responses...",
        }
    """
    skill = recommendation["skill"]
    topic = recommendation["topic"]
    difficulty = recommendation["difficulty"]
    mastery = recommendation["mastery"]

    # We ask for a consistent JSON shape every time, regardless of
    # content_type — the frontend can choose which pieces to display based
    # on content_type. Keeping generation consistent makes validation simpler.
    schema_description = {
        "topic": "string - repeat the topic name back exactly as given",
        "difficulty": "string - repeat the difficulty back exactly as given",
        "explanation": "string - a clear, beginner-friendly explanation of the concept, 3-6 sentences",
        "examples": "array of 2-3 short strings, each a concrete example illustrating the concept",
        "mcqs": (
            "array of exactly 5 objects, each with: "
            "'question' (string), 'options' (array of exactly 4 strings), "
            "'correct_answer' (string that exactly matches one of the options)"
        ),
        "exercise": "string - one small hands-on practice task the learner can attempt",
        "mini_project": "string or null - only include a real value if difficulty is Advanced or Challenge, otherwise null",
    }

    prompt = f"""You are generating educational content for an adaptive IT training system.

A Python adaptive engine has ALREADY decided the following — do not change or second-guess it:

Skill: {skill}
Topic: {topic}
Learner's current mastery: {mastery}%
Difficulty to teach at: {difficulty}

Your ONLY job is to generate learning content for this exact topic and difficulty.

Return ONLY a single valid JSON object, with no markdown code fences, no explanation
text before or after it, and no comments. The JSON must match this exact shape:

{json.dumps(schema_description, indent=2)}

Rules:
- Exactly 5 items in "mcqs"
- Exactly 4 options per MCQ
- "correct_answer" must be an exact string match to one of that MCQ's options
- No duplicate options within an MCQ
- Keep the explanation appropriate for a "{difficulty}" learner
- Output raw JSON only — your entire response must be parseable by json.loads()
"""
    return prompt