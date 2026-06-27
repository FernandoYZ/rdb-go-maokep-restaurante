BEGIN;

-- Rollback: comprobante estados split

DROP VIEW IF EXISTS comprobantes_estado_actual;

DROP TRIGGER IF EXISTS trg_comprobante_estado_audit ON comprobantes;
DROP FUNCTION IF EXISTS trg_comprobante_estado_change_audit();

DROP INDEX IF EXISTS idx_comprobantes_estados_composite;
DROP INDEX IF EXISTS idx_comprobantes_estado_operacional;

ALTER TABLE comprobantes
  DROP COLUMN id_estado_operacional;

DROP TABLE IF EXISTS estados_operacionales;

COMMIT;
