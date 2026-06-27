BEGIN;

-- Rollback: restaurar estado VARCHAR(20) en notas_credito y notas_debito,
-- luego eliminar la tabla estados_nota.
--
-- Orden crítico: las columnas FK (id_estado_nota) deben eliminarse ANTES de
-- hacer DROP TABLE estados_nota para evitar FK dependency error.
-- Los datos se restauran desde estados_nota.nombre antes de eliminar la FK.

-- ──────────────────────────────────────────────────────────────────────────
-- 1. notas_credito: restaurar VARCHAR, poblar desde estados_nota, eliminar FK
-- ──────────────────────────────────────────────────────────────────────────
ALTER TABLE notas_credito
    ADD COLUMN estado VARCHAR(20) DEFAULT 'borrador';

UPDATE notas_credito
   SET estado = (
       SELECT nombre
         FROM estados_nota
        WHERE id = notas_credito.id_estado_nota
   );

ALTER TABLE notas_credito
    DROP COLUMN id_estado_nota;

-- ──────────────────────────────────────────────────────────────────────────
-- 2. notas_debito: misma restauración
-- ──────────────────────────────────────────────────────────────────────────
ALTER TABLE notas_debito
    ADD COLUMN estado VARCHAR(20) DEFAULT 'borrador';

UPDATE notas_debito
   SET estado = (
       SELECT nombre
         FROM estados_nota
        WHERE id = notas_debito.id_estado_nota
   );

ALTER TABLE notas_debito
    DROP COLUMN id_estado_nota;

-- ──────────────────────────────────────────────────────────────────────────
-- 3. Eliminar tabla de lookup (solo después de que se eliminaron las FKs)
-- ──────────────────────────────────────────────────────────────────────────
DROP TABLE IF EXISTS estados_nota;

COMMIT;
