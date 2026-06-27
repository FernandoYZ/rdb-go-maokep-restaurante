BEGIN;

-- Rollback: restaurar tipo_orden VARCHAR en ordenes y eliminar tipos_orden
-- Secuencia: 033 (DOWN)

-- Agregar columna vieja (nullable para migración de datos inversa)
ALTER TABLE ordenes ADD COLUMN tipo_orden VARCHAR(20);

-- Migrar datos inversos: ID → codigo string
UPDATE ordenes o
SET tipo_orden = t.codigo
FROM tipos_orden t
WHERE t.id_tipo_orden = o.id_tipo_orden;

-- Eliminar FK y columna nueva
ALTER TABLE ordenes
  DROP CONSTRAINT fk_ordenes_tipo_orden,
  DROP COLUMN id_tipo_orden;

-- Eliminar índice
DROP INDEX IF EXISTS idx_ordenes_tipo_orden;

-- Aplicar NOT NULL a la columna restaurada
ALTER TABLE ordenes ALTER COLUMN tipo_orden SET NOT NULL;

-- Eliminar tabla lookup
DROP TABLE IF EXISTS tipos_orden;

COMMIT;
