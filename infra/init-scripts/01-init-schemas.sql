-- Solve-for-X (SFX) Unified Basecamp Database Initialization
-- Creates isolated schemas and unified tables for each application under the single relational database instance

-- 1. Create distinct schemas for multi-tenant isolation
CREATE SCHEMA IF NOT EXISTS sfx_core;
CREATE SCHEMA IF NOT EXISTS moon_whisper;
CREATE SCHEMA IF NOT EXISTS sfx_imjong_care;
CREATE SCHEMA IF NOT EXISTS sfx_memento_mori;
CREATE SCHEMA IF NOT EXISTS sfx_legacy_vault;

-- 2. Schema comments for documentation and traceability
COMMENT ON SCHEMA sfx_core IS 'Solve-for-X Central Core, Analytics & SSO Schema';
COMMENT ON SCHEMA moon_whisper IS 'Moon Whisper Application isolated schema';
COMMENT ON SCHEMA sfx_imjong_care IS 'SFX Imjong Care isolated schema';
COMMENT ON SCHEMA sfx_memento_mori IS 'SFX Memento Mori isolated schema';
COMMENT ON SCHEMA sfx_legacy_vault IS 'SFX Legacy Vault isolated schema';

-- 3. Core SSO User and Application schemas
CREATE TABLE IF NOT EXISTS sfx_core.users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    nickname VARCHAR(100),
    avatar_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS sfx_core.applications (
    app_id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    api_key_hash VARCHAR(255) UNIQUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS sfx_core.user_applications (
    user_id UUID REFERENCES sfx_core.users(id) ON DELETE CASCADE,
    app_id VARCHAR(50) REFERENCES sfx_core.applications(app_id) ON DELETE CASCADE,
    tier VARCHAR(30) DEFAULT 'free',
    activated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, app_id)
);

-- 4. Moon Whisper schema tables
CREATE TABLE IF NOT EXISTS moon_whisper.diaries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES sfx_core.users(id) ON DELETE CASCADE,
    title VARCHAR(200),
    content TEXT NOT NULL,
    voice_record_path TEXT,
    emotion_score NUMERIC(5, 2),
    theme_neon_color VARCHAR(10) DEFAULT '#00FF66',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS moon_whisper.emotions (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES sfx_core.users(id) ON DELETE CASCADE,
    mood_tag VARCHAR(50) NOT NULL,
    intensity INTEGER CHECK (intensity BETWEEN 1 AND 10),
    logged_date DATE DEFAULT CURRENT_DATE
);

-- 5. SFX Imjong Care schema tables
CREATE TABLE IF NOT EXISTS sfx_imjong_care.wills (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES sfx_core.users(id) ON DELETE CASCADE,
    encrypted_content TEXT NOT NULL,
    card_neon_theme VARCHAR(20) DEFAULT 'HOT_PINK',
    signature_svg TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 6. SFX Memento Mori schema tables
CREATE TABLE IF NOT EXISTS sfx_memento_mori.life_grids (
    user_id UUID PRIMARY KEY REFERENCES sfx_core.users(id) ON DELETE CASCADE,
    birth_date DATE NOT NULL,
    target_age INTEGER DEFAULT 80 CHECK (target_age BETWEEN 1 AND 150),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
