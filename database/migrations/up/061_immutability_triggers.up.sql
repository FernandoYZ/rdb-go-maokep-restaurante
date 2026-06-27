BEGIN;

-- Migración: Immutability Enforcement Triggers
-- Creada el: 27/05/2026
-- Secuencia: 061
--
-- Propósito: proteger snapshots tributarios contra modificaciones accidentales
-- implementando restricciones a nivel DB (RAISE EXCEPTION).
--
-- Tablas protegidas:
--   - comprobante_detalles: snapshot histórico de líneas de facturación
--   - notas_credito_detalles: snapshot de líneas de nota crédito
--   - notas_debito_detalles: snapshot de líneas de nota débito
--
-- Política: estas tablas son APPEND-ONLY. UPDATE/DELETE aborta con excepción.
-- Si hay error, correción se hace vía nueva nota o comprobante.

-- ============================================================================
-- 1. Trigger: bloquea UPDATE en comprobante_detalles
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_comprobante_detalles_immutable()
RETURNS TRIGGER AS $$
BEGIN
  RAISE EXCEPTION
    'comprobante_detalles is immutable. '
    'Cannot update row id=%. To correct, issue a nota_credito or nota_debito.',
    OLD.id;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_comprobante_detalles_no_update
  BEFORE UPDATE ON comprobante_detalles
  FOR EACH ROW EXECUTE FUNCTION fn_comprobante_detalles_immutable();

-- ============================================================================
-- 2. Trigger: bloquea DELETE en comprobante_detalles
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_comprobante_detalles_no_delete()
RETURNS TRIGGER AS $$
BEGIN
  RAISE EXCEPTION
    'comprobante_detalles is immutable. '
    'Cannot delete row id=%. To correct, issue a nota_credito or nota_debito.',
    OLD.id;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_comprobante_detalles_no_delete
  BEFORE DELETE ON comprobante_detalles
  FOR EACH ROW EXECUTE FUNCTION fn_comprobante_detalles_no_delete();

-- ============================================================================
-- 3. Trigger: bloquea UPDATE en notas_credito_detalles
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_notas_credito_detalles_immutable()
RETURNS TRIGGER AS $$
BEGIN
  RAISE EXCEPTION
    'notas_credito_detalles is immutable. '
    'Cannot update row id=%. Anular y crear nueva nota si es necesario.',
    OLD.id;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_notas_credito_detalles_no_update
  BEFORE UPDATE ON notas_credito_detalles
  FOR EACH ROW EXECUTE FUNCTION fn_notas_credito_detalles_immutable();

-- ============================================================================
-- 4. Trigger: bloquea DELETE en notas_credito_detalles
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_notas_credito_detalles_no_delete()
RETURNS TRIGGER AS $$
BEGIN
  RAISE EXCEPTION
    'notas_credito_detalles is immutable. '
    'Cannot delete row id=%. Anular y crear nueva nota si es necesario.',
    OLD.id;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_notas_credito_detalles_no_delete
  BEFORE DELETE ON notas_credito_detalles
  FOR EACH ROW EXECUTE FUNCTION fn_notas_credito_detalles_no_delete();

-- ============================================================================
-- 5. Trigger: bloquea UPDATE en notas_debito_detalles
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_notas_debito_detalles_immutable()
RETURNS TRIGGER AS $$
BEGIN
  RAISE EXCEPTION
    'notas_debito_detalles is immutable. '
    'Cannot update row id=%. Anular y crear nueva nota si es necesario.',
    OLD.id;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_notas_debito_detalles_no_update
  BEFORE UPDATE ON notas_debito_detalles
  FOR EACH ROW EXECUTE FUNCTION fn_notas_debito_detalles_immutable();

-- ============================================================================
-- 6. Trigger: bloquea DELETE en notas_debito_detalles
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_notas_debito_detalles_no_delete()
RETURNS TRIGGER AS $$
BEGIN
  RAISE EXCEPTION
    'notas_debito_detalles is immutable. '
    'Cannot delete row id=%. Anular y crear nueva nota si es necesario.',
    OLD.id;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_notas_debito_detalles_no_delete
  BEFORE DELETE ON notas_debito_detalles
  FOR EACH ROW EXECUTE FUNCTION fn_notas_debito_detalles_no_delete();

COMMIT;
