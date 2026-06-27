BEGIN;

-- Reversión de migración 049: eliminar tabla puente ordenes_comprobantes
-- Los índices se eliminan automáticamente con la tabla.

DROP TABLE IF EXISTS ordenes_comprobantes;

COMMIT;
