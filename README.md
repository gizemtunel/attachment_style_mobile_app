# Attachment Style Application

An AI-powered mobile application developed to analyze attachment styles, provide personalized AI-assisted responses, and offer a simple community environment for users.

The application combines a **Flutter mobile interface**, **FastAPI backend**, a **fine-tuned RoBERTa-based text classification model**, and **Google Gemini API** integration.

---

## About the Project

This project focuses on identifying attachment styles in human relationships using artificial intelligence.

The system works with four main attachment styles:

- Secure Attachment
- Anxious Attachment
- Avoidant Attachment
- Fearful Attachment

Users can complete an attachment-style test, interact with an AI assistant, and use the community section to create posts, like posts, and leave comments.

The AI assistant can use the detected attachment style as contextual information while generating responses.

---

## Features

- User registration
- User login
- Attachment style questionnaire
- Attachment style analysis
- Four-class attachment style classification
- AI-based text classification
- Gemini-powered conversational assistant
- Personalized responses based on attachment style
- Community page
- Post creation
- Like functionality
- Comment functionality
- Local SQLite database
- Flutter-based mobile interface
- FastAPI REST API

---

## Attachment Styles

The application works with the following four attachment-style categories:

| Label | Attachment Style |
|---|---|
| LABEL_0 | Secure Attachment |
| LABEL_1 | Anxious Attachment |
| LABEL_2 | Avoidant Attachment |
| LABEL_3 | Fearful Attachment |

The application also contains a questionnaire-based decision mechanism that evaluates anxiety and avoidance scores.

---

## Technologies

### Mobile Application

- Flutter
- Dart

### Backend

- Python
- FastAPI
- Pydantic
- SQLAlchemy
- SQLite
- Requests

### Artificial Intelligence

- Hugging Face Transformers
- RoBERTa
- Text Classification
- Natural Language Processing
- Google Gemini API

---

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
│   ├── android/
│   ├── ios/
│   ├── lib/
│   ├── linux/
│   ├── macos/
│   ├── test/
│   ├── web/
│   ├── windows/
│   ├── pubspec.yaml
│   └── pubspec.lock
│
├── .gitignore
└── README.md
```

---

## Artificial Intelligence Model

The project uses a fine-tuned **RoBERTa-based text classification model** to classify user text into one of four attachment-style categories.

The model is loaded using the Hugging Face `transformers` library.

Example:

```python
pipeline(
    "text-classification",
    model=MODEL_PATH,
    tokenizer=MODEL_PATH,
    max_length=512,
    truncation=True
)
```

### Model File

The trained model file:

```text
model.safetensors
```

is not included in this GitHub repository because of its large file size.

To use the trained model locally, place the model file inside the `llm_model` directory.

The expected structure is:

```text
llm_model/
├── model.safetensors
├── config.json
├── tokenizer.json
└── tokenizer_config.json
```

The model weight file is excluded from Git using `.gitignore`.

---

## Gemini API

The application uses the **Google Gemini API** to generate conversational responses.

The Gemini API key is not stored directly inside the source code.

Instead, it is loaded from an environment file.

Create the following file:

```text
backend/.env
```

Then add your Gemini API key:

```env
GEMINI_API_KEY=your_gemini_api_key_here
```

An example environment file is included as:

```text
backend/.env.example
```

The real `.env` file is excluded from Git and should never be committed to the repository.

---

## Backend Setup

### 1. Navigate to the backend directory

```bash
cd backend
```

### 2. Create a virtual environment

Windows:

```bash
python -m venv venv
venv\Scripts\activate
```

macOS / Linux:

```bash
python3 -m venv venv
source venv/bin/activate
```

### 3. Install dependencies

```bash
pip install -r requirements.txt
```

### 4. Create the environment file

Create:

```text
.env
```

inside the `backend` directory.

Add:

```env
GEMINI_API_KEY=your_gemini_api_key_here
```

### 5. Run the FastAPI server

```bash
uvicorn main:app --reload
```

The backend will normally run at:

```text
http://127.0.0.1:8000
```

---

## FastAPI Documentation

After starting the backend, interactive Swagger documentation can be accessed at:

```text
http://127.0.0.1:8000/docs
```

Alternative ReDoc documentation:

```text
http://127.0.0.1:8000/redoc
```

---

## Flutter Setup

Make sure Flutter is installed and configured correctly.

### 1. Navigate to the mobile application directory

```bash
cd mobile_app
```

### 2. Install Flutter dependencies

```bash
flutter pub get
```

### 3. Check connected devices

```bash
flutter devices
```

### 4. Run the application

```bash
flutter run
```

---

## API Endpoints

The backend currently provides endpoints for authentication, attachment-style analysis, AI chat, and community features.

### Authentication

Register a user:

```http
POST /auth/kayit
```

Login:

```http
POST /auth/giris
```

### Attachment Style Test

Analyze questionnaire scores:

```http
POST /testi-analiz-et
```

### AI Assistant

Send a message:

```http
POST /mesaj-gonder
```

### Community

Get community posts:

```http
GET /topluluk/gonderiler
```

Create a post:

```http
POST /topluluk/paylas
```

Like a post:

```http
POST /topluluk/{post_id}/begen
```

Add a comment:

```http
POST /topluluk/{post_id}/yorum
```

---

## Database

The backend uses **SQLite** with **SQLAlchemy**.

The local database file is:

```text
topluluk.db
```

The database stores information such as:

- Users
- Community posts
- Likes
- Comments

The local database file is excluded from Git to prevent local or user data from being uploaded to the repository.

---

## Environment Variables

The project currently uses the following environment variable:

| Variable | Description |
|---|---|
| `GEMINI_API_KEY` | Google Gemini API key |

Example:

```env
GEMINI_API_KEY=your_gemini_api_key_here
```

---

## Files Excluded from Git

Sensitive, generated, local, or very large files are excluded using `.gitignore`.

Examples include:

```text
backend/.env
*.db
llm_model/model.safetensors
llm_model/training_args.bin
__pycache__/
.dart_tool/
build/
venv/
.venv/
```

This prevents API keys, local databases, generated files, and large model weights from being accidentally committed.

---

## Security

API keys and other credentials should never be written directly into source code or committed to a public repository.

This project uses environment variables for sensitive configuration.

Before publishing changes, it is recommended to verify staged files using:

```bash
git status
```

---

## Running the Complete Project

The general startup process is:

### Start the backend

```bash
cd backend
uvicorn main:app --reload
```

### Start the Flutter application

Open another terminal:

```bash
cd mobile_app
flutter pub get
flutter run
```

The mobile application can then communicate with the FastAPI backend.

---

## Main Workflow

The general application workflow is:

```text
User
   ↓
Flutter Mobile Application
   ↓
FastAPI Backend
   ↓
Attachment Style Analysis
   ↓
RoBERTa Model
   ↓
Detected Attachment Style
   ↓
Gemini API
   ↓
Personalized AI Response
```

The community features are also handled through the FastAPI backend and SQLite database.

---

## Purpose

The aim of this project is to combine:

- Mobile application development
- Natural language processing
- Machine learning
- REST API development
- Database management
- Generative artificial intelligence

into a single application focused on attachment-style analysis.

---

## Future Improvements

Possible future improvements include:

- JWT-based authentication
- Stronger password hashing
- Cloud database integration
- Model hosting
- Backend deployment
- Mobile application deployment
- Improved community moderation
- User profile management
- Password reset functionality
- Email verification
- Push notifications
- More detailed attachment-style statistics
- Improved AI conversation context
- Model performance monitoring

---

## Disclaimer

This application is an educational and experimental artificial intelligence project.

Attachment-style predictions and AI-generated responses should not be considered professional psychological diagnosis, medical advice, or a substitute for professional mental health services.

---

## Author

Developed as a mobile application and artificial intelligence project focused on attachment-style analysis.

---

## License

This project is currently intended for educational and portfolio purposes.
