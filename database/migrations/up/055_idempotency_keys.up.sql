BEGIN;

-- Migración: idempotency_key UUID nullable en comprobantes y envios_sunat
-- Creada el: 27/05/2026
-- Secuencia: 055
--
-- Propósito: agregar infraestructura de idempotencia para el futuro handler
-- layer de Go. La columna es nullable (NULL = sin clave de idempotencia),
-- y el índice parcial garantiza unicidad solo para valores no-NULL.
--
-- Elección de índice parcial sobre UNIQUE constraint regular:
--   - UNIQUE constraint trata cada NULL como igual a otros NULLs en algunos
--     dialectos, pero PostgreSQL los trata como distintos por SQL estándar.
--   - El índice parcial WHERE IS NOT NULL expresa la intención con más claridad:
--     "solo quiero unicidad cuando el cliente provee una clave".
--   - Permite múltiples filas con NULL coexistir sin restricción.
--
-- Dependencias: comprobantes (043), envios_sunat (045), Phase 5 completa.

-- ──────────────────────────────────────────────────────────────────────────
-- comprobantes
-- ──────────────────────────────────────────────────────────────────────────
ALTER TABLE comprobantes
    ADD COLUMN idempotency_key VARCHAR(100) NULL;

CREATE UNIQUE INDEX IF NOT EXISTS uk_comprobantes_idempotency_key
    ON comprobantes(idempotency_key)
 WHERE idempotency_key IS NOT NULL;

-- ──────────────────────────────────────────────────────────────────────────
-- envios_sunat
-- ──────────────────────────────────────────────────────────────────────────
ALTER TABLE envios_sunat
    ADD COLUMN idempotency_key VARCHAR(100) NULL;

CREATE UNIQUE INDEX IF NOT EXISTS uk_envios_sunat_idempotency_key
    ON envios_sunat(idempotency_key)
 WHERE idempotency_key IS NOT NULL;

COMMIT;
