from fastapi import FastAPI, HTTPException, Depends
from pydantic import BaseModel, Field
from typing import List, Optional
import os
import warnings
import requests
import uuid
import json
import hashlib

from dotenv import load_dotenv

from sqlalchemy import create_engine, Column, Integer, String, Text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session

from transformers import pipeline


warnings.filterwarnings("ignore")


# ==========================================
# TEMEL PROJE YOLLARI
# ==========================================

# Bu dosyanın bulunduğu klasör:
# attachment_style_application/backend/
BASE_DIR = os.path.dirname(os.path.abspath(__file__))

# Ana proje klasörü:
# attachment_style_application/
PROJECT_DIR = os.path.abspath(
    os.path.join(BASE_DIR, "..")
)


# ==========================================
# .ENV DOSYASINI YÜKLE
# ==========================================

ENV_PATH = os.path.join(BASE_DIR, ".env")

load_dotenv(ENV_PATH)

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")

gemini_aktif = bool(GEMINI_API_KEY)

if gemini_aktif:
    print("✅ Gemini API anahtarı yüklendi.")
else:
    print("⚠️ Gemini API anahtarı bulunamadı.")


# ==========================================
# 1. VERİTABANI KURULUMU
# ==========================================

DATABASE_PATH = os.path.join(BASE_DIR, "topluluk.db")

SQLALCHEMY_DATABASE_URL = (
    f"sqlite:///{DATABASE_PATH.replace(os.sep, '/')}"
)

engine = create_engine(
    SQLALCHEMY_DATABASE_URL,
    connect_args={"check_same_thread": False}
)

SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine
)

Base = declarative_base()


class DBUser(Base):
    __tablename__ = "users"

    id = Column(
        String,
        primary_key=True,
        index=True
    )

    name = Column(String)

    email = Column(
        String,
        unique=True,
        index=True
    )

    password_hash = Column(String)


class DBPost(Base):
    __tablename__ = "posts"

    id = Column(
        String,
        primary_key=True,
        index=True
    )

    author = Column(String)

    content = Column(Text)

    likes = Column(
        Integer,
        default=0
    )

    comments = Column(
        Text,
        default="[]"
    )


Base.metadata.create_all(
    bind=engine
)


def get_db():

    db = SessionLocal()

    try:
        yield db

    finally:
        db.close()


def hash_password(
    password: str
):

    return hashlib.sha256(
        password.encode()
    ).hexdigest()


# ==========================================
# 2. YAPAY ZEKA MODELİ
# ==========================================

# Model klasörü:
# attachment_style_application/llm_model/

MODEL_KLASORU = os.path.join(
    PROJECT_DIR,
    "llm_model"
)


try:

    if os.path.exists(MODEL_KLASORU):

        nlp_model = pipeline(
            "text-classification",
            model=MODEL_KLASORU,
            tokenizer=MODEL_KLASORU,
            max_length=512,
            truncation=True
        )

        print(
            "✅ RoBERTa-Large Pro Yüklendi!"
        )

    else:

        nlp_model = None

        print(
            "⚠️ Model klasörü bulunamadı:"
        )

        print(
            MODEL_KLASORU
        )


except Exception as e:

    nlp_model = None

    print(
        "⚠️ Model yüklenirken hata oluştu:"
    )

    print(e)


SINIF_ISIMLERI = {

    "LABEL_0":
        "Güvenli Bağlanma",

    "LABEL_1":
        "Kaygılı Bağlanma",

    "LABEL_2":
        "Kaçıngan Bağlanma",

    "LABEL_3":
        "Korkulu Bağlanma"
}


# ==========================================
# FASTAPI
# ==========================================

app = FastAPI(
    title=
    "Kusursuz Koç - Bağlanma Stili Analiz Sistemi"
)


# ==========================================
# 3. VERİ MODELLERİ
# ==========================================

class UserRegister(BaseModel):

    name: str

    email: str

    password: str


class UserLogin(BaseModel):

    email: str

    password: str


class TestVerisi(BaseModel):

    email: str

    kaygi_puani: float

    kacinma_puani: float


class MesajGecmisi(BaseModel):

    role: str

    parts: List[str]


class SohbetIstegi(BaseModel):

    kullanici_id: str

    yeni_mesaj: str

    mevcut_stil: Optional[str] = None

    gecmis_konusma: List[MesajGecmisi] = (
        Field(default_factory=list)
    )


class SohbetCevabi(BaseModel):

    durum: str

    tespit_edilen_stil: str

    asistan_cevabi: str


class Comment(BaseModel):

    author: str

    text: str


class Post(BaseModel):

    id: Optional[str] = None

    author: str

    content: str

    likes: int = 0

    comments: List[Comment] = (
        Field(default_factory=list)
    )


# ==========================================
# 4. KULLANICI KAYIT
# ==========================================

@app.post("/auth/kayit")
def kayit_ol(
    user: UserRegister,
    db: Session = Depends(get_db)
):

    mevcut_kullanici = (
        db.query(DBUser)
        .filter(
            DBUser.email == user.email
        )
        .first()
    )


    if mevcut_kullanici:

        raise HTTPException(
            status_code=400,
            detail=
            "Bu e-posta adresi zaten kayıtlı."
        )


    yeni_kullanici = DBUser(

        id=str(
            uuid.uuid4()
        ),

        name=user.name,

        email=user.email,

        password_hash=
        hash_password(
            user.password
        )
    )


    db.add(
        yeni_kullanici
    )

    db.commit()


    return {

        "mesaj":
            "Kayıt başarılı!",

        "name":
            yeni_kullanici.name,

        "email":
            yeni_kullanici.email
    }


# ==========================================
# KULLANICI GİRİŞ
# ==========================================

@app.post("/auth/giris")
def giris_yap(
    user: UserLogin,
    db: Session = Depends(get_db)
):

    db_kullanici = (

        db.query(DBUser)

        .filter(
            DBUser.email ==
            user.email
        )

        .first()
    )


    if not db_kullanici:

        raise HTTPException(
            status_code=404,
            detail=
            "Kullanıcı bulunamadı."
        )


    if (
        db_kullanici.password_hash
        !=
        hash_password(
            user.password
        )
    ):

        raise HTTPException(
            status_code=401,
            detail=
            "Hatalı şifre."
        )


    return {

        "mesaj":
            "Giriş başarılı!",

        "name":
            db_kullanici.name,

        "email":
            db_kullanici.email
    }


# ==========================================
# 5. TEST ANALİZİ
# ==========================================

@app.post("/testi-analiz-et")
async def testi_analiz_et(
    data: TestVerisi
):

    kaygi = (
        data.kaygi_puani
    )

    kacinma = (
        data.kacinma_puani
    )


    if (
        kaygi >= 3.0
        and
        kacinma >= 3.0
    ):

        karar = (
            "Korkulu Bağlanma"
        )


    elif (
        kaygi >= 3.0
        and
        kacinma < 3.0
    ):

        karar = (
            "Kaygılı Bağlanma"
        )


    elif (
        kaygi < 3.0
        and
        kacinma >= 3.0
    ):

        karar = (
            "Kaçıngan Bağlanma"
        )


    else:

        karar = (
            "Güvenli Bağlanma"
        )


    return {

        "sistem_karari":
            karar
    }


# ==========================================
# 6. SOHBET / GEMINI
# ==========================================

@app.post(
    "/mesaj-gonder",
    response_model=SohbetCevabi
)
def mesaj_gonder(
    istek: SohbetIstegi
):

    tespit_edilen_stil = (
        istek.mevcut_stil
    )


    try:

        # ------------------------------
        # Bağlanma stili modeli
        # ------------------------------

        if (
            not tespit_edilen_stil
            and
            nlp_model
        ):

            sonuc = (
                nlp_model(
                    istek.yeni_mesaj
                )[0]
            )


            tespit_edilen_stil = (
                SINIF_ISIMLERI.get(
                    str(
                        sonuc["label"]
                    ),
                    "Bilinmeyen"
                )
            )


        # ------------------------------
        # Gemini
        # ------------------------------

        if gemini_aktif:

            url = (
                "https://generativelanguage."
                "googleapis.com/v1beta/models/"
                "gemini-2.5-flash:"
                "generateContent"
                f"?key={GEMINI_API_KEY}"
            )


            contents = [

                {

                    "role":
                        msg.role,

                    "parts": [

                        {
                            "text": p
                        }

                        for p
                        in msg.parts

                    ]

                }

                for msg
                in istek.gecmis_konusma

            ]


            contents.append(
                {

                    "role":
                        "user",

                    "parts": [

                        {

                            "text":
                                istek.yeni_mesaj

                        }

                    ]

                }
            )


            payload = {

                "systemInstruction": {

                    "parts": [

                        {

                            "text":
                                (
                                    "Kullanıcıda "
                                    f"'{tespit_edilen_stil}' "
                                    "tespit edildi. "
                                    "Şefkatli cevap ver."
                                )

                        }

                    ]

                },

                "contents":
                    contents

            }


            res = requests.post(
                url,
                json=payload,
                headers={
                    "Content-Type":
                        "application/json"
                },
                timeout=30
            )


            res.raise_for_status()

            response_json = (
                res.json()
            )


            asistan_cevabi = (

                response_json[
                    "candidates"
                ][0][
                    "content"
                ][
                    "parts"
                ][0][
                    "text"
                ]

                .strip()

            )


        else:

            asistan_cevabi = (
                "Yapay zeka bağlantısı yok."
            )


        return SohbetCevabi(

            durum=
            "başarılı",

            tespit_edilen_stil=
            (
                tespit_edilen_stil
                or
                "Belirsiz"
            ),

            asistan_cevabi=
            asistan_cevabi
        )


    except Exception as e:

        print(
            "Gemini / sohbet hatası:",
            e
        )


        return SohbetCevabi(

            durum=
            "hata",

            tespit_edilen_stil=
            (
                tespit_edilen_stil
                or
                "Belirsiz"
            ),

            asistan_cevabi=
            "Bağlantı hatası."
        )


# ==========================================
# 7. TOPLULUK
# ==========================================

@app.get(
    "/topluluk/gonderiler",
    response_model=List[Post]
)
async def get_posts(
    db: Session = Depends(get_db)
):

    db_posts = (
        db.query(DBPost)
        .all()
    )


    sonuclar = []


    for post in reversed(
        db_posts
    ):

        try:

            parsed_comments = (
                json.loads(
                    post.comments
                    or
                    "[]"
                )
            )

        except Exception:

            parsed_comments = []


        sonuclar.append(

            Post(

                id=
                post.id,

                author=
                post.author,

                content=
                post.content,

                likes=
                post.likes,

                comments=[

                    Comment(**c)

                    for c
                    in parsed_comments

                ]

            )

        )


    return sonuclar


# ==========================================
# GÖNDERİ PAYLAŞ
# ==========================================

@app.post(
    "/topluluk/paylas"
)
async def create_post(
    post: Post,
    db: Session = Depends(get_db)
):

    yeni_id = str(
        uuid.uuid4()
    )


    yeni_gonderi = DBPost(

        id=
        yeni_id,

        author=
        post.author,

        content=
        post.content,

        likes=
        0,

        comments=
        "[]"
    )


    db.add(
        yeni_gonderi
    )

    db.commit()


    return {

        "mesaj":
            "Gönderi paylaşıldı",

        "post_id":
            yeni_id
    }


# ==========================================
# GÖNDERİ BEĞEN
# ==========================================

@app.post(
    "/topluluk/{post_id}/begen"
)
async def like_post(
    post_id: str,
    db: Session = Depends(get_db)
):

    post = (

        db.query(DBPost)

        .filter(
            DBPost.id ==
            post_id
        )

        .first()

    )


    if not post:

        raise HTTPException(
            status_code=404,
            detail=
            "Gönderi bulunamadı."
        )


    post.likes += 1

    db.commit()


    return {

        "mesaj":
            "Beğenildi"
    }


# ==========================================
# YORUM EKLE
# ==========================================

@app.post(
    "/topluluk/{post_id}/yorum"
)
async def add_comment(
    post_id: str,
    comment: Comment,
    db: Session = Depends(get_db)
):

    post = (

        db.query(DBPost)

        .filter(
            DBPost.id ==
            post_id
        )

        .first()

    )


    if not post:

        raise HTTPException(
            status_code=404,
            detail=
            "Gönderi bulunamadı."
        )


    try:

        mevcut_yorumlar = (
            json.loads(
                post.comments
                or
                "[]"
            )
        )

    except Exception:

        mevcut_yorumlar = []


    mevcut_yorumlar.append(
        {

            "author":
                comment.author,

            "text":
                comment.text

        }
    )


    post.comments = (
        json.dumps(
            mevcut_yorumlar,
            ensure_ascii=False
        )
    )


    db.commit()


    return {

        "mesaj":
            "Yorum eklendi"
    }