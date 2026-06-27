BEGIN;

-- Rollback: eliminar tablas lookup de caja
-- Secuencia: 037 (DOWN)
--
-- NOTA: la migración 038 (aperturas_caja, movimientos_caja) debe hacerse rollback
-- primero porque referencia estas tablas.

DROP TABLE IF EXISTS tipos_movimiento_caja;
DROP TABLE IF EXISTS estados_caja;

COMMIT;
