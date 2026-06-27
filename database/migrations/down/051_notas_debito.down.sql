BEGIN;

-- Rollback: 051_notas_debito
-- Secuencia de DROP: detalles primero (FK hacia notas_debito), luego fact.

DROP TABLE IF EXISTS notas_debito_detalles;
DROP TABLE IF EXISTS notas_debito;

COMMIT;
