# Code Review Rules

## Database (PostgreSQL)
- Use UPPERCASE for SQL keywords (SELECT, INSERT, UPDATE, DELETE, CREATE, ALTER).
- Use Snake Case for table and column names.
- Always implement Row Level Security (RLS) on tenant-scoped tables.
- Use explicit check constraints for financial amounts (check values >= 0).
- Keep primary keys as UUID or composite keys depending on context.
- Keep migration scripts idempotent using IF NOT EXISTS or DROP IF EXISTS where applicable.
- Make all changes within a BEGIN/COMMIT block.
