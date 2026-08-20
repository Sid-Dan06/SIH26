# 🚀 AI-Based Adaptive IT Training System


An AI-powered personalized IT training platform that adapts the learning experience according to an individual's existing knowledge, skill gaps, and performance.


## 🎯 Problem


Traditional IT training provides the same course and learning path to everyone, even though employees have different knowledge levels and learning speeds.


## 💡 Solution


Our system first performs a **pre-assessment** to understand the learner's current skills. It then identifies weak areas and creates a personalized training path.


The system can generate:


- 📚 Personalized Lessons
- 📝 MCQ Quizzes
- 💻 Practical Exercises
- 🚀 Mini Projects


After each learning activity, the learner's performance is analyzed and the learning path is adapted accordingly.


## 🔄 Core Workflow

Pre-Assessment
      ↓
Skill Analysis
      ↓
Skill Gap Detection
      ↓
Personalized Learning Path
      ↓
AI Generated Content
      ↓
Performance Analysis
      ↓
Updated Skill Profile
      ↓
Adaptive Next Step
      ↺
🛠️ Planned Tech Stack
Frontend: Flutter
Backend: FastAPI + Python
AI: Qwen + Ollama
Database: SQLite
🎯 Initial Scope

The MVP will focus on software development skills:

Python
SQL
Git
Linux

The initial goal is to demonstrate that two learners with the same learning goal can receive different training paths based on their individual skill profiles.

🚧 Status

Currently in development

## Local Backend Setup

The backend uses SQLite for user accounts, saved mastery profiles, assessment
attempts, and lesson history. The database is created automatically at
`backend/training.db` on first startup.

```powershell
cd backend
python -m pip install -r requirements.txt
python -m uvicorn main:app --reload
```

Register or log in through `/docs`, then send the returned bearer token as an
`Authorization: Bearer <token>` header. Use `/progress` to load saved mastery
and `/history` to load completed learning sessions. Configure
`GEMINI_API_KEY` in `backend/.env` only when AI lesson generation is needed.
