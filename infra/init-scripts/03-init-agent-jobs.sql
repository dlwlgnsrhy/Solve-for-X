-- Create Central Agent Tasks Queue inside Central Basecamp Database
CREATE TABLE IF NOT EXISTS sfx_core.agent_jobs (
    job_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    command_text TEXT NOT NULL,
    target_app VARCHAR(50),
    status VARCHAR(20) DEFAULT 'QUEUED',            -- 'QUEUED', 'RUNNING', 'SUCCESS', 'FAILED'
    log_file_path TEXT,
    walkthrough_md TEXT,
    screenshot_path TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_agent_jobs_status ON sfx_core.agent_jobs(status);
