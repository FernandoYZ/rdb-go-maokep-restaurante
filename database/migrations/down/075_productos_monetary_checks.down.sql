BEGIN;

-- Rollback: eliminar CHECK constraints monetarios para productos
-- Secuencia: 075 down

ALTER TABLE productos DROP CONSTRAINT IF EXISTS chk_productos_precio_venta_positive;
ALTER TABLE productos DROP CONSTRAINT IF EXISTS chk_productos_precio_costo_positive;

COMMIT;
