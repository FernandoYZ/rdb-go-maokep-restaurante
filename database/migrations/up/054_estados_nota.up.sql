BEGIN;

-- Migración: estados_nota lookup + ALTER notas_credito + ALTER notas_debito
-- Creada el: 27/05/2026
-- Secuencia: 054
--
-- Propósito:
--   1. Crear tabla de lookup estados_nota con los cinco estados del ciclo de
--      vida de notas (crédito/débito).
--   2. Migrar notas_credito y notas_debito de VARCHAR(20) estado a INT FK
--      id_estado_nota referenciando estados_nota(id).
--
-- Estrategia de migración:
--   - Seed inline dentro de la misma transacción para que el UPDATE que
--     resuelve los ids pueda leerlos en el mismo bloque.
--   - COALESCE: si el valor de estado no coincide con ninguna fila (e.g. typo),
--     se usa el id de 'borrador' como fallback — nunca bloquea la migración.
--   - NOT NULL se aplica DESPUÉS del UPDATE para evitar violaciones transitorias
--     en tablas con filas existentes.
--
-- Dependencias: notas_credito (050), notas_debito (051), Phase 5 completa.

-- ──────────────────────────────────────────────────────────────────────────
-- 1. Tabla de lookup
-- ──────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS estados_nota (
    id      SERIAL       PRIMARY KEY,
    nombre  VARCHAR(20)  NOT NULL UNIQUE
);

-- ──────────────────────────────────────────────────────────────────────────
-- 2. Seed de los cinco estados canónicos
-- ──────────────────────────────────────────────────────────────────────────
INSERT INTO estados_nota (nombre) VALUES
    ('borrador'),
    ('emitido'),
    ('aceptado'),
    ('rechazado'),
    ('anulado')
ON CONFLICT (nombre) DO NOTHING;

-- ──────────────────────────────────────────────────────────────────────────
-- 3. notas_credito: agregar FK, migrar datos, eliminar VARCHAR
-- ──────────────────────────────────────────────────────────────────────────
ALTER TABLE notas_credito
    ADD COLUMN id_estado_nota INT REFERENCES estados_nota(id);

UPDATE notas_credito
   SET id_estado_nota = COALESCE(
       (SELECT id FROM estados_nota WHERE nombre = notas_credito.estado),
       (SELECT id FROM estados_nota WHERE nombre = 'borrador')
   );

ALTER TABLE notas_credito
    ALTER COLUMN id_estado_nota SET NOT NULL;

ALTER TABLE notas_credito
    DROP COLUMN estado;

-- ──────────────────────────────────────────────────────────────────────────
-- 4. notas_debito: misma transformación
-- ──────────────────────────────────────────────────────────────────────────
ALTER TABLE notas_debito
    ADD COLUMN id_estado_nota INT REFERENCES estados_nota(id);

UPDATE notas_debito
   SET id_estado_nota = COALESCE(
       (SELECT id FROM estados_nota WHERE nombre = notas_debito.estado),
       (SELECT id FROM estados_nota WHERE nombre = 'borrador')
   );

ALTER TABLE notas_debito
    ALTER COLUMN id_estado_nota SET NOT NULL;

ALTER TABLE notas_debito
    DROP COLUMN estado;

COMMIT;
