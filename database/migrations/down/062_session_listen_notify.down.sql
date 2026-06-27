BEGIN;

-- Rollback: session LISTEN/NOTIFY infrastructure

DROP VIEW IF EXISTS sesiones_activas;

DROP TRIGGER IF EXISTS trg_sesion_update_notify ON sesiones;
DROP FUNCTION IF EXISTS trg_sesion_revoked();

DROP TRIGGER IF EXISTS trg_sesion_insert_notify ON sesiones;
DROP FUNCTION IF EXISTS trg_sesion_created();

DROP FUNCTION IF EXISTS fn_notify_session_change(UUID, UUID, VARCHAR, TEXT);

DROP TABLE IF EXISTS session_events;

COMMIT;
