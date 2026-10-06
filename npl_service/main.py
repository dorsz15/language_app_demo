from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List, Optional
from lingua import LanguageDetectorBuilder, Language
import spacy

app = FastAPI(title="Language App NLP Engine")

# 1. Inicjalizacja Lingua (Wykrywanie języków)
detector = LanguageDetectorBuilder.from_all_languages().build()

# 2. Ładowanie modeli spaCy dla obsługiwanych języków
nlp_models = {
    "en": spacy.load("en_core_web_sm"),
    "es": spacy.load("es_core_news_sm"),
    # dodaj kolejne języki
}

# Symulacja bazy danych poziomów CEFR dla lematów (w produkcji: baza danych / plik JSON)
CEFR_DICTIONARY = {
    "en": {
        "run": "A1",
        "ambiguous": "B2",
        "phenomenon": "C1"
    }
}

class AnalysisRequest(BaseModel):
    text: str
    target_language: Optional[str] = None

class TokenResult(BaseModel):
    token: str
    lemma: str
    pos: str
    cefr_level: str

class AnalysisResponse(BaseModel):
    detected_language: str
    tokens: List[TokenResult]

@app.post("/analyze", response_model=AnalysisResponse)
async def analyze_text(request: AnalysisRequest):
    # 1. Detekcja języka (Lingua)
    detected_lang = detector.detect_language_of(request.text)
    lang_code = detected_lang.iso_code_639_1.name.lower() if detected_lang else "en"

    # Użycie wykrytego lub wymuszonego języka docelowego
    active_lang = request.target_language or lang_code
    
    if active_lang not in nlp_models:
        raise HTTPException(status_code=400, detail=f"Language {active_lang} is not supported.")

    # 2. Lematyzacja i POS Tagging (spaCy)
    nlp = nlp_models[active_lang]
    doc = nlp(request.text)

    parsed_tokens = []
    lang_cefr_dict = CEFR_DICTIONARY.get(active_lang, {})

    for token in doc:
        # Odfiltrowanie interpunkcji i spacji
        if token.is_punct or token.is_space:
            continue
        
        lemma = token.lemma_.lower()
        
        # 3. Przypisanie poziomu CEFR na podstawie lematu
        cefr_level = lang_cefr_dict.get(lemma, "Unknown")

        parsed_tokens.append(TokenResult(
            token=token.text,
            lemma=lemma,
            pos=token.pos_,
            cefr_level=cefr_level
        ))

    # 4. (Opcjonalnie) Tutaj możesz dodać wywołanie OpenAI/Claude API 
    # w celu ujednoznacznienia homonimów na podstawie kontekstu całego zdania.

    return AnalysisResponse(
        detected_language=active_lang,
        tokens=parsed_tokens
    )