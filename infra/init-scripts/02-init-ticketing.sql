-- Solve-for-X (SFX) Support Ticketing Database Extension
-- Extends the unified basecamp PostgreSQL database to support autonomous customer ticket tracking

CREATE TABLE IF NOT EXISTS sfx_core.support_tickets (
    ticket_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    app_id VARCHAR(50) NOT NULL,                    -- 'imjong_care', 'memento_mori', 'moon_whisper', etc.
    source VARCHAR(20) NOT NULL,                    -- 'EMAIL', 'PLAY_STORE', 'APP_STORE'
    raw_identifier VARCHAR(255),                    -- Google Play Review ID or Email Message-ID
    user_id UUID REFERENCES sfx_core.users(id) ON DELETE SET NULL, -- SSO User matching
    subject VARCHAR(255),
    content TEXT NOT NULL,
    urgency VARCHAR(20) DEFAULT 'MEDIUM',          -- 'CRITICAL', 'HIGH', 'MEDIUM', 'LOW'
    intent VARCHAR(30),                             -- 'BUG_REPORT', 'FEATURE_REQUEST', 'BILLING', 'SSO_INQUIRY'
    sentiment VARCHAR(20) DEFAULT 'NEUTRAL',        -- 'ANGRY', 'NEUTRAL', 'HAPPY'
    status VARCHAR(20) DEFAULT 'OPEN',              -- 'OPEN', 'APPROVED', 'DISPATCHED', 'CLOSED'
    assigned_agent VARCHAR(50) DEFAULT 'HERMES',
    ai_draft_response TEXT,
    is_buffered BOOLEAN DEFAULT FALSE,              -- True if received during sleeping hours (23:00 - 08:00)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indexing for high-performance SRE queries
CREATE INDEX IF NOT EXISTS idx_tickets_app_urgency ON sfx_core.support_tickets(app_id, urgency);
CREATE INDEX IF NOT EXISTS idx_tickets_status_buffered ON sfx_core.support_tickets(status, is_buffered);
CREATE INDEX IF NOT EXISTS idx_tickets_created ON sfx_core.support_tickets(created_at);

COMMENT ON TABLE sfx_core.support_tickets IS 'Store unified customer support inquiries from emails and App/Play store reviews.';
