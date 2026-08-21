import hashlib
import secrets
import sqlite3
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional

DATABASE_PATH = Path(__file__).resolve().parent.parent / "training.db"


def _utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def get_connection() -> sqlite3.Connection:
    connection = sqlite3.connect(DATABASE_PATH)
    connection.row_factory = sqlite3.Row
    connection.execute("PRAGMA foreign_keys = ON")
    return connection


def initialize_database() -> None:
    with get_connection() as connection:
        connection.executescript(
            """
            CREATE TABLE IF NOT EXISTS users (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                username TEXT NOT NULL UNIQUE,
                email TEXT NOT NULL UNIQUE,
                password_hash TEXT NOT NULL,
                created_at TEXT NOT NULL
            );

            INSERT OR IGNORE INTO users (id, username, email, password_hash, created_at) 
            VALUES (1, 'Potato', 'potato@example.com', 'dummy_hash', '2026-08-21T00:00:00Z');

            CREATE TABLE IF NOT EXISTS sessions (
                token TEXT PRIMARY KEY,
                user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                created_at TEXT NOT NULL,
                expires_at TEXT
            );

            CREATE TABLE IF NOT EXISTS mastery_profiles (
                user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                skill TEXT NOT NULL,
                topic TEXT NOT NULL,
                mastery REAL NOT NULL,
                accuracy REAL NOT NULL,
                difficulty_performance REAL NOT NULL,
                response_time_score REAL NOT NULL,
                correct INTEGER NOT NULL,
                total INTEGER NOT NULL,
                last_practiced_at TEXT,
                attempts INTEGER NOT NULL DEFAULT 0,
                PRIMARY KEY (user_id, skill, topic)
            );

            CREATE TABLE IF NOT EXISTS assessment_attempts (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                submitted_at TEXT NOT NULL,
                score_profile TEXT NOT NULL
            );

            CREATE TABLE IF NOT EXISTS quiz_attempts (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                assessment_id INTEGER REFERENCES assessment_attempts(id) ON DELETE CASCADE,
                question_id TEXT NOT NULL,
                selected_answer TEXT NOT NULL,
                is_correct INTEGER NOT NULL,
                time_taken_seconds REAL NOT NULL,
                attempted_at TEXT NOT NULL
            );

            CREATE TABLE IF NOT EXISTS learning_sessions (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                skill TEXT NOT NULL,
                topic TEXT NOT NULL,
                quiz_correct INTEGER NOT NULL,
                quiz_total INTEGER NOT NULL,
                exercise_score REAL,
                time_taken_seconds REAL,
                completed_at TEXT NOT NULL
            );
            """
        )


def _hash_password(password: str, salt: bytes) -> str:
    digest = hashlib.pbkdf2_hmac("sha256", password.encode(), salt, 210_000)
    return f"{salt.hex()}${digest.hex()}"


def hash_password(password: str) -> str:
    return _hash_password(password, secrets.token_bytes(16))


def verify_password(password: str, stored_hash: str) -> bool:
    try:
        salt_hex, digest_hex = stored_hash.split("$", 1)
        expected = _hash_password(password, bytes.fromhex(salt_hex))
        return secrets.compare_digest(expected.split("$", 1)[1], digest_hex)
    except (ValueError, TypeError):
        return False


def create_user(username: str, email: str, password: str) -> int:
    with get_connection() as connection:
        cursor = connection.execute(
            "INSERT INTO users (username, email, password_hash, created_at) VALUES (?, ?, ?, ?)",
            (username, email, hash_password(password), _utc_now()),
        )
        return cursor.lastrowid


def find_user_by_login(login: str) -> Optional[sqlite3.Row]:
    with get_connection() as connection:
        return connection.execute(
            "SELECT * FROM users WHERE username = ? OR email = ?", (login, login)
        ).fetchone()


def find_user(user_id: int) -> Optional[sqlite3.Row]:
    with get_connection() as connection:
        return connection.execute("SELECT * FROM users WHERE id = ?", (user_id,)).fetchone()


def create_session(user_id: int) -> str:
    token = secrets.token_urlsafe(32)
    with get_connection() as connection:
        connection.execute(
            "INSERT INTO sessions (token, user_id, created_at) VALUES (?, ?, ?)",
            (token, user_id, _utc_now()),
        )
    return token


def get_user_by_token(token: str) -> Optional[sqlite3.Row]:
    with get_connection() as connection:
        return connection.execute(
            "SELECT users.* FROM sessions JOIN users ON users.id = sessions.user_id "
            "WHERE sessions.token = ?",
            (token,),
        ).fetchone()


def save_assessment(user_id: int, profile: dict) -> int:
    now = _utc_now()
    import json

    with get_connection() as connection:
        cursor = connection.execute(
            "INSERT INTO assessment_attempts (user_id, submitted_at, score_profile) VALUES (?, ?, ?)",
            (user_id, now, json.dumps(profile)),
        )
        assessment_id = cursor.lastrowid
        for skill, topics in profile.items():
            for topic, data in topics.items():
                connection.execute(
                    """INSERT INTO mastery_profiles
                    (user_id, skill, topic, mastery, accuracy, difficulty_performance,
                     response_time_score, correct, total, last_practiced_at, attempts)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1)
                    ON CONFLICT(user_id, skill, topic) DO UPDATE SET
                      mastery=excluded.mastery, accuracy=excluded.accuracy,
                      difficulty_performance=excluded.difficulty_performance,
                      response_time_score=excluded.response_time_score,
                      correct=excluded.correct, total=excluded.total,
                      last_practiced_at=excluded.last_practiced_at,
                      attempts=mastery_profiles.attempts + 1""",
                    (user_id, skill, topic, data["mastery"], data["accuracy"],
                     data["difficulty_performance"], data["response_time_score"],
                     data["correct"], data["total"], now),
                    )
        return assessment_id


def save_quiz_attempts(user_id: int, assessment_id: int, responses: list, questions_by_id: dict) -> None:
    with get_connection() as connection:
        now = _utc_now()
        for response in responses:
            question = questions_by_id.get(response.question_id)
            if question is None:
                continue
            connection.execute(
                """INSERT INTO quiz_attempts
                (user_id, assessment_id, question_id, selected_answer, is_correct,
                 time_taken_seconds, attempted_at) VALUES (?, ?, ?, ?, ?, ?, ?)""",
                (user_id, assessment_id, response.question_id, response.selected_answer,
                 response.selected_answer == question.correct_answer,
                 response.time_taken_seconds, now),
            )


def get_profile(user_id: int) -> dict:
    with get_connection() as connection:
        rows = connection.execute(
            "SELECT * FROM mastery_profiles WHERE user_id = ?", (user_id,)
        ).fetchall()
    profile = {}
    for row in rows:
        profile.setdefault(row["skill"], {})[row["topic"]] = {
            "mastery": row["mastery"],
            "accuracy": row["accuracy"],
            "difficulty_performance": row["difficulty_performance"],
            "response_time_score": row["response_time_score"],
            "correct": row["correct"],
            "total": row["total"],
            "last_practiced_at": row["last_practiced_at"],
            "attempts": row["attempts"],
        }
    return profile


def save_learning_session(user_id: int, skill: str, topic: str, quiz_correct: int,
                           quiz_total: int, exercise_score: Optional[float],
                           time_taken_seconds: Optional[float], profile: dict) -> None:
    now = _utc_now()
    with get_connection() as connection:
        connection.execute(
            """INSERT INTO learning_sessions
            (user_id, skill, topic, quiz_correct, quiz_total, exercise_score,
             time_taken_seconds, completed_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)""",
            (user_id, skill, topic, quiz_correct, quiz_total, exercise_score,
             time_taken_seconds, now),
        )
        data = profile[skill][topic]
        connection.execute(
            """UPDATE mastery_profiles SET mastery = ?, last_practiced_at = ?,
            attempts = attempts + 1 WHERE user_id = ? AND skill = ? AND topic = ?""",
            (data["mastery"], now, user_id, skill, topic),
        )


def get_history(user_id: int) -> list[dict]:
    with get_connection() as connection:
        rows = connection.execute(
            "SELECT * FROM learning_sessions WHERE user_id = ? ORDER BY completed_at DESC",
            (user_id,),
        ).fetchall()
    return [dict(row) for row in rows]


def get_quiz_history(user_id: int) -> list[dict]:
    with get_connection() as connection:
        rows = connection.execute(
            "SELECT * FROM quiz_attempts WHERE user_id = ? ORDER BY attempted_at DESC, id DESC",
            (user_id,),
        ).fetchall()
    return [dict(row) for row in rows]
