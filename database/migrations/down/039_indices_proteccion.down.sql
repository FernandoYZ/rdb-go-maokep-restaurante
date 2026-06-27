BEGIN;

-- Rollback: eliminar índices, trigger y columna protegido
-- Secuencia: 039 (DOWN)

-- Eliminar índices compuestos
DROP INDEX IF EXISTS idx_aperturas_caja_empresa_estado_fecha;
DROP INDEX IF EXISTS idx_ordenes_empresa_estado_fecha;

-- Eliminar trigger e función de protección
DROP TRIGGER IF EXISTS trg_items_orden_protegido ON items_orden;
DROP FUNCTION IF EXISTS validar_items_orden_protegido();

-- Eliminar columna protegido
ALTER TABLE ordenes DROP COLUMN IF EXISTS protegido;

COMMIT;
