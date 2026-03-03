# Mission Control Database

Local PostgreSQL setup for Mission Control v2.0 development.

## Quick Start

```bash
# Start PostgreSQL
cd MissionControl/db
docker-compose up -d

# Verify it's running
docker-compose ps

# Connect to check (requires migration first)
docker exec -it mission-control-db psql -U mission_control -d mission_control
```

## Files

- `docker-compose.yml` - PostgreSQL container configuration
- `migrations/001_initial_schema.sql` - Initial database schema
- `tasks.md` - Implementation task breakdown

## Connection Details

| Property | Value |
|----------|-------|
| Host | localhost |
| Port | 5432 |
| Database | mission_control |
| User | mission_control |
| Password | mission_control_dev |

## Environment Variables

```bash
export DATABASE_URL="postgresql://mission_control:mission_control_dev@localhost:5432/mission_control"
```

## Migration

The schema is in `migrations/001_initial_schema.sql`. To apply:

```bash
docker exec -i mission-control-db psql -U mission_control -d mission_control < migrations/001_initial_schema.sql
```

## Stop

```bash
docker-compose down        # Stop container
docker-compose down -v     # Stop and remove data volume
```
