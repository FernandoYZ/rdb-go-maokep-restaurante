BEGIN;

-- Rollback: eliminar tablas operativas de caja y funciones asociadas
-- Secuencia: 038 (DOWN)

-- Eliminar triggers primero
DROP TRIGGER IF EXISTS trg_movimiento_actualiza_monto_cierre ON movimientos_caja;
DROP FUNCTION IF EXISTS actualizar_monto_cierre_caja();

DROP TRIGGER IF EXISTS trg_actualizado_en_aperturas_caja ON aperturas_caja;

-- Eliminar tablas en orden inverso de dependencias
DROP TABLE IF EXISTS arqueos_caja;
DROP TABLE IF EXISTS movimientos_caja;
DROP TABLE IF EXISTS aperturas_caja;

COMMIT;
