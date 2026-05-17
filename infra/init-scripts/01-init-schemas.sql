-- Solve-for-X (SFX) Unified Basecamp Database Initialization
-- Creates isolated schemas for each application under the single relational database instance

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
