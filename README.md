# Attachment Style Application

A mobile application developed to analyze attachment styles and provide AI-assisted responses based on the detected attachment style.

The project consists of a Flutter mobile application, a FastAPI backend, a fine-tuned RoBERTa text classification model, and Gemini API integration.

## Features

- User registration and login
- Attachment style test
- Four attachment style classifications:
  - Secure Attachment
  - Anxious Attachment
  - Avoidant Attachment
  - Fearful Attachment
- AI-based text classification
- Gemini-powered assistant
- Community posts
- Like and comment functionality
- SQLite database
- Flutter mobile interface

## Technologies

### Mobile

- Flutter
- Dart

### Backend

- Python
- FastAPI
- SQLAlchemy
- SQLite
- Pydantic
- Requests

### Artificial Intelligence

- Hugging Face Transformers
- RoBERTa
- Fine-tuned text classification model
- Gemini API

## Project Structure

```text
attachment_style_application/
│
├── backend/
│   ├── main.py
│   ├── requirements.txt
│   └── .env.example
│
├── llm_model/
│   ├── config.json
│   ├── tokenizer.json
│   └── tokenizer_config.json
│
├── mobile_app/
│   ├── lib/
│   ├── android/
│   ├── ios/
│   ├── web/
│   └── pubspec.yaml
│
├── .gitignore
└── README.md
