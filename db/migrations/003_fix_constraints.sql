-- Fix for movement_history and audit_logs delete constraints
-- The rules were causing issues with foreign key checks

-- Drop the problematic rules
DROP RULE IF EXISTS movement_history_no_delete ON movement_history;
DROP RULE IF EXISTS movement_history_no_update ON movement_history;
DROP RULE IF EXISTS audit_logs_no_delete ON audit_logs;
DROP RULE IF EXISTS audit_logs_no_update ON audit_logs;

-- Recreate with proper CASCADE handling
-- movement_history should cascade from tasks automatically due to ON DELETE CASCADE
-- But let's add a trigger to ensure immutability instead of using rules
CREATE OR REPLACE FUNCTION prevent_movement_history_update()
RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'movement_history is immutable - updates not allowed';
END;
$$ language 'plpgsql';

CREATE TRIGGER prevent_movement_history_update
    BEFORE UPDATE ON movement_history
    FOR EACH ROW
    EXECUTE FUNCTION prevent_movement_history_update();

CREATE OR REPLACE FUNCTION prevent_movement_history_delete()
RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'movement_history is immutable - deletes not allowed';
END;
$$ language 'plpgsql';

CREATE TRIGGER prevent_movement_history_delete
    BEFORE DELETE ON movement_history
    FOR EACH ROW
    EXECUTE FUNCTION prevent_movement_history_delete();

-- Same for audit_logs
CREATE OR REPLACE FUNCTION prevent_audit_logs_update()
RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'audit_logs is immutable - updates not allowed';
END;
$$ language 'plpgsql';

CREATE TRIGGER prevent_audit_logs_update
    BEFORE UPDATE ON audit_logs
    FOR EACH ROW
    EXECUTE FUNCTION prevent_audit_logs_update();

CREATE OR REPLACE FUNCTION prevent_audit_logs_delete()
RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'audit_logs is immutable - deletes not allowed';
END;
$$ language 'plpgsql';

CREATE TRIGGER prevent_audit_logs_delete
    BEFORE DELETE ON audit_logs
    FOR EACH ROW
    EXECUTE FUNCTION prevent_audit_logs_delete();
