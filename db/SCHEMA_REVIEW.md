# Database Schema Review - DB-006

## Supabase Compatibility ✅

**Verified Compatible:**
- PostgreSQL 16 (Supabase uses 15+) ✅
- UUID primary keys with `gen_random_uuid()` ✅
- ENUM types supported by Supabase ✅
- JSONB column type supported ✅
- Triggers and functions work in Supabase ✅

**Supabase-Specific Notes:**
- Connection pooling handled by Supabase (PgBouncer)
- Use Supabase's connection string format: `postgresql://postgres:[YOUR-PASSWORD]@db.[YOUR-PROJECT].supabase.co:5432/postgres`
- Supabase provides built-in auth - consider adding `auth_id` column to users table

---

## Row Level Security (RLS) Considerations

**Current State:** RLS is NOT enabled (needs to be added for Supabase)

**Recommendations for Production:**

```sql
-- Enable RLS
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE acceptance_criteria ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;

-- Create policies (example for team-based access)
CREATE POLICY "Team members can view all tasks" ON tasks
    FOR SELECT USING (true);

CREATE POLICY "Team members can insert tasks" ON tasks
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Team members can update tasks" ON tasks
    FOR UPDATE USING (true);

-- For acceptance_criteria and comments, cascade from tasks
```

**Supabase Auth Integration:**
- Add `auth_id` UUID column to link to Supabase auth.users
- Create RLS policies based on `auth_id = auth.uid()`

---

## Performance Indexes Review ✅

**Existing Indexes (15 total):**
- Primary keys on all tables ✅
- `idx_tasks_status` - for filtering by status ✅
- `idx_tasks_execution_role` - for role filtering ✅
- `idx_tasks_owner` - for owner queries ✅
- `idx_tasks_status_role` - composite for role+status queries ✅
- `idx_tasks_status_order` - for board ordering ✅
- `idx_acceptance_criteria_task_position` - composite ✅
- `idx_comments_task_id` - for task comments ✅
- `idx_movement_history_task_id` - for task history ✅

**Additional Recommendations:**
- Consider adding index on `tasks.owner, tasks.status` if querying by owner frequently
- Consider index on `comments.author` if filtering by author

---

## Security Review ✅

**Implemented:**
- UUID primary keys (non-sequential, not guessable) ✅
- Immutable tables (movement_history, audit_logs) with triggers ✅
- Optimistic locking via `version` column ✅
- Foreign keys with CASCADE deletes ✅
- Timestamps with `TIMESTAMPTZ` (timezone-aware) ✅

**Security Recommendations:**
1. **Enable RLS** before production deployment
2. **Rotate credentials** - use environment variables, not hardcoded
3. **Connection pooling** - limit max connections to prevent exhaustion
4. **SSL/TLS** - ensure `sslmode=require` in production connection strings
5. **Audit** - review audit_logs table usage for compliance

---

## Migration Files

| File | Description |
|------|-------------|
| `001_initial_schema.sql` | Initial, enums, schema with all tables indexes |
| `002_movement_history_trigger.sql` | Trigger for automatic movement recording |
| `003_fix_constraints.sql` | Fixed constraint issues with rules → triggers |

---

## API Connection

**Connection String Format:**
```
postgresql://mission_control:mission_control_dev@localhost:5432/mission_control
```

**Environment Variable:** `DATABASE_URL`

**Pool Configuration:**
- Max connections: 10
- Idle timeout: 30s
- Connection timeout: 5s

---

Reviewed: 2026-03-03
