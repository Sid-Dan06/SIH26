# Adaptive Intelligence Flutter UI — separated structure

The UI is now split into screens, reusable widgets, and theme files.

## Structure

lib/
├── main.dart
├── theme/
│   └── app_theme.dart
├── screens/
│   ├── home_screen.dart
│   ├── skills_screen.dart
│   ├── quiz_screen.dart
│   └── path_screen.dart
└── widgets/
    ├── app_bottom_nav.dart
    ├── app_header.dart
    ├── home_widgets.dart
    ├── path_widgets.dart
    ├── pill.dart
    ├── primary_button.dart
    ├── progress_bar.dart
    ├── quiz_widgets.dart
    ├── section_title.dart
    └── skill_widgets.dart

## Run

flutter pub get
flutter run

The UI currently uses demo/local values. It is ready to connect to FastAPI + Qwen/Ollama + SQLite.
