BEGIN;

-- Rollback: eliminar índices parciales y columnas idempotency_key de
-- comprobantes y envios_sunat.
--
-- Orden: DROP INDEX antes de DROP COLUMN (limpieza explícita aunque
-- PostgreSQL elimina índices automáticamente al DROP COLUMN — ser explícito
-- evita sorpresas si el índice fue creado como UNIQUE constraint en el futuro).

-- ──────────────────────────────────────────────────────────────────────────
-- comprobantes
-- ──────────────────────────────────────────────────────────────────────────
DROP INDEX IF EXISTS uk_comprobantes_idempotency_key;

ALTER TABLE comprobantes
    DROP COLUMN IF EXISTS idempotency_key;

-- ──────────────────────────────────────────────────────────────────────────
-- envios_sunat
-- ──────────────────────────────────────────────────────────────────────────
DROP INDEX IF EXISTS uk_envios_sunat_idempotency_key;

ALTER TABLE envios_sunat
    DROP COLUMN IF EXISTS idempotency_key;

COMMIT;
