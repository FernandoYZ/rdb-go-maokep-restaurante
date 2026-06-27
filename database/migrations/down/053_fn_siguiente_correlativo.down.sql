BEGIN;

-- Rollback: migración 053 — elimina fn_siguiente_correlativo
-- IF EXISTS garantiza idempotencia si la función no existe.
DROP FUNCTION IF EXISTS fn_siguiente_correlativo(UUID, INT, VARCHAR);

COMMIT;
