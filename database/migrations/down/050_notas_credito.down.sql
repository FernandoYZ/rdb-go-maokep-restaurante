BEGIN;

-- Rollback: 050_notas_credito
-- Secuencia de DROP: detalles primero (FK hacia notas_credito), luego fact.

DROP TABLE IF EXISTS notas_credito_detalles;
DROP TABLE IF EXISTS notas_credito;

COMMIT;
