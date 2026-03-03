-- Mission Control Database Schema
-- Version: 1.0.0
-- Description: Initial schema for Mission Control task management
-- Compatible with: PostgreSQL 14+, Supabase

-- ============================================
-- ENUMS
-- ============================================

CREATE TYPE task_status AS ENUM (
    'backlog',
    'in_progress',
    'review',
    'done',
    'blocked'
);

CREATE TYPE execution_role AS ENUM (
    'ARCHITECT',
    'EXECUTOR',
    'DATA_ENGINEER',
    'REVIEWER'
);

CREATE TYPE comment_type AS ENUM (
    'info',
    'issue',
    'decision',
    'fix',
    'note'
);

-- ============================================
-- CORE TABLES
-- ============================================

-- Tasks table
CREATE TABLE tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(500) NOT NULL,
    description TEXT,
    status task_status NOT NULL DEFAULT 'backlog',
    execution_role execution_role NOT NULL,
    owner VARCHAR(255),
    order_index NUMERIC(10, 2) NOT NULL DEFAULT 0,
    version INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);

-- Acceptance Criteria table
CREATE TABLE acceptance_criteria (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    position INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Comments table
CREATE TABLE comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    author VARCHAR(255) NOT NULL,
    type comment_type NOT NULL DEFAULT 'info',
    message TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Movement History table (Immutable)
CREATE TABLE movement_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    from_status task_status,
    to_status task_status NOT NULL,
    moved_by VARCHAR(255),
    moved_by_role execution_role,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Audit Logs table (Immutable)
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_type VARCHAR(100) NOT NULL,
    entity_id UUID NOT NULL,
    action VARCHAR(100) NOT NULL,
    performed_by VARCHAR(255),
    payload JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================
-- INDEXES
-- ============================================

-- Task indexes
CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_tasks_execution_role ON tasks(execution_role);
CREATE INDEX idx_tasks_owner ON tasks(owner);
CREATE INDEX idx_tasks_status_role ON tasks(status, execution_role);
CREATE INDEX idx_tasks_updated_at ON tasks(updated_at DESC);
CREATE INDEX idx_tasks_status_order ON tasks(status, order_index);

-- Acceptance Criteria indexes
CREATE INDEX idx_acceptance_criteria_task_position ON acceptance_criteria(task_id, position);

-- Comments indexes
CREATE INDEX idx_comments_task_id ON comments(task_id);
CREATE INDEX idx_comments_created_at ON comments(created_at DESC);

-- Movement History indexes
CREATE INDEX idx_movement_history_task_id ON movement_history(task_id);
CREATE INDEX idx_movement_history_created_at ON movement_history(created_at DESC);

-- Audit Logs indexes
CREATE INDEX idx_audit_logs_entity ON audit_logs(entity_type, entity_id);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at DESC);

-- ============================================
-- CONSTRAINTS & RULES
-- ============================================

-- Prevent updates to movement_history (append-only)
CREATE RULE movement_history_no_update AS ON UPDATE TO movement_history DO INSTEAD NOTHING;

-- Prevent deletes from movement_history
CREATE RULE movement_history_no_delete AS ON DELETE TO movement_history DO INSTEAD NOTHING;

-- Prevent updates to audit_logs (append-only)
CREATE RULE audit_logs_no_update AS ON UPDATE TO audit_logs DO INSTEAD NOTHING;

-- Prevent deletes from audit_logs
CREATE RULE audit_logs_no_delete AS ON DELETE TO audit_logs DO INSTEAD NOTHING;

-- ============================================
-- FUNCTIONS
-- ============================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger to auto-update updated_at
CREATE TRIGGER update_tasks_updated_at
    BEFORE UPDATE ON tasks
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Function to set completed_at when status changes to done
CREATE OR REPLACE FUNCTION set_completed_at()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'done' AND OLD.status != 'done' THEN
        NEW.completed_at = NOW();
    END IF;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER set_tasks_completed_at
    BEFORE UPDATE ON tasks
    FOR EACH ROW
    EXECUTE FUNCTION set_completed_at();

-- ============================================
-- SEED DATA (Optional)
-- ============================================

-- Insert sample tasks for testing
-- INSERT INTO tasks (title, description, status, execution_role, order_index) VALUES
--     ('Create database schema', 'Design and implement initial PostgreSQL schema', 'backlog', 'ARCHITECT', 1),
--     ('Set up Docker Compose', 'Configure local PostgreSQL with Docker', 'backlog', 'EXECUTOR', 2);
