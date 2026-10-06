-- init.sql

-- Enable UUID extension for secure, non-sequential user IDs
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Define the CEFR language level enum
CREATE TYPE cefr_level AS ENUM ('A1', 'A2', 'B1', 'B2', 'C1', 'C2');

-- 1. USERS TABLE
-- Stores Google OAuth profile information
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    google_id VARCHAR(255) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    full_name VARCHAR(255),
    avatar_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Index for rapid user lookups during OAuth authentication
CREATE INDEX idx_users_google_id ON users(google_id);

-- 2. LANGUAGES TABLE
-- Languages matching Google ML Kit Translate codes
CREATE TABLE languages (
    code VARCHAR(10) PRIMARY KEY, -- BCP 47 language tags (e.g., 'en', 'es', 'ja')
    name VARCHAR(100) NOT NULL
);

-- 3. USER COURSES TABLE
-- Links users to target languages, source languages, and target levels
CREATE TABLE user_courses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    target_language_code VARCHAR(10) NOT NULL REFERENCES languages(code),
    source_language_code VARCHAR(10) NOT NULL REFERENCES languages(code),
    target_level cefr_level NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Ensure source and target languages are not identical
    CONSTRAINT chk_different_languages CHECK (target_language_code <> source_language_code),
    -- Prevent a user from enrolling in the exact same language pair & level combination twice
    CONSTRAINT uq_user_course UNIQUE (user_id, target_language_code, source_language_code, target_level)
);

-- Indexes for performance on user dashboard queries
CREATE INDEX idx_user_courses_user ON user_courses(user_id);

-- Common Google ML Kit Translate languages pre-populated
INSERT INTO languages (code, name) VALUES
    ('af', 'Afrikaans'), ('sq', 'Albanian'), ('ar', 'Arabic'), ('be', 'Belarusian'),
    ('bn', 'Bengali'), ('bg', 'Bulgarian'), ('ca', 'Catalan'), ('zh', 'Chinese'),
    ('hr', 'Croatian'), ('cs', 'Czech'), ('da', 'Danish'), ('nl', 'Dutch'),
    ('en', 'English'), ('eo', 'Esperanto'), ('et', 'Estonian'), ('fi', 'Finnish'),
    ('fr', 'French'), ('gl', 'Galician'), ('ka', 'Georgian'), ('de', 'German'),
    ('el', 'Greek'), ('gu', 'Gujarati'), ('ht', 'Haitian Creole'), ('he', 'Hebrew'),
    ('hi', 'Hindi'), ('hu', 'Hungarian'), ('is', 'Icelandic'), ('id', 'Indonesian'),
    ('ga', 'Irish'), ('it', 'Italian'), ('ja', 'Japanese'), ('kn', 'Kannada'),
    ('ko', 'Korean'), ('lv', 'Latvian'), ('lt', 'Lithuanian'), ('mk', 'Macedonian'),
    ('ms', 'Malay'), ('mt', 'Maltese'), ('mr', 'Marathi'), ('no', 'Norwegian'),
    ('fa', 'Persian'), ('pl', 'Polish'), ('pt', 'Portuguese'), ('ro', 'Romanian'),
    ('ru', 'Russian'), ('sk', 'Slovak'), ('sl', 'Slovenian'), ('es', 'Spanish'),
    ('sw', 'Swahili'), ('sv', 'Swedish'), ('tl', 'Tagalog'), ('ta', 'Tamil'),
    ('te', 'Telugu'), ('th', 'Thai'), ('tr', 'Turkish'), ('uk', 'Ukrainian'),
    ('ur', 'Urdu'), ('vi', 'Vietnamese'), ('cy', 'Welsh');