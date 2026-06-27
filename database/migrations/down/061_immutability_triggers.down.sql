BEGIN;

-- Rollback: elimina triggers y funciones de immutability

DROP TRIGGER IF EXISTS trg_comprobante_detalles_no_update ON comprobante_detalles;
DROP TRIGGER IF EXISTS trg_comprobante_detalles_no_delete ON comprobante_detalles;
DROP FUNCTION IF EXISTS fn_comprobante_detalles_immutable();
DROP FUNCTION IF EXISTS fn_comprobante_detalles_no_delete();

DROP TRIGGER IF EXISTS trg_notas_credito_detalles_no_update ON notas_credito_detalles;
DROP TRIGGER IF EXISTS trg_notas_credito_detalles_no_delete ON notas_credito_detalles;
DROP FUNCTION IF EXISTS fn_notas_credito_detalles_immutable();
DROP FUNCTION IF EXISTS fn_notas_credito_detalles_no_delete();

DROP TRIGGER IF EXISTS trg_notas_debito_detalles_no_update ON notas_debito_detalles;
DROP TRIGGER IF EXISTS trg_notas_debito_detalles_no_delete ON notas_debito_detalles;
DROP FUNCTION IF EXISTS fn_notas_debito_detalles_immutable();
DROP FUNCTION IF EXISTS fn_notas_debito_detalles_no_delete();

COMMIT;
