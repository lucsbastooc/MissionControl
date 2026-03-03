-- Movement History Trigger
-- DB-005: Create trigger to automatically record task status changes

-- Function to record task status changes
CREATE OR REPLACE FUNCTION record_movement_history()
RETURNS TRIGGER AS $$
BEGIN
    -- Only record if status changed
    IF OLD.status IS DISTINCT FROM NEW.status THEN
        INSERT INTO movement_history (task_id, from_status, to_status, moved_by, moved_by_role)
        VALUES (
            NEW.id,
            OLD.status,
            NEW.status,
            COALESCE(NEW.owner, 'system'),
            NEW.execution_role
        );
    END IF;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger to record movement history on task updates
DROP TRIGGER IF EXISTS record_task_movement ON tasks;
CREATE TRIGGER record_task_movement
    AFTER UPDATE ON tasks
    FOR EACH ROW
    EXECUTE FUNCTION record_movement_history();
