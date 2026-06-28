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

-- ============================================================================
-- 7. Trigger: protege cabecera de comprobantes contra modificaciones fiscales
-- ============================================================================
-- Evita modificar datos clave de facturación una vez que el comprobante 
-- ha salido del estado inicial 'borrador' (id_estado != 1).
CREATE OR REPLACE FUNCTION fn_comprobantes_header_immutable()
RETURNS TRIGGER AS $$
BEGIN
  -- 1 es el ID canónico para 'borrador' en la tabla lookup estados_comprobante
  IF OLD.id_estado != 1 THEN
    IF NEW.id_empresa != OLD.id_empresa OR
       NEW.id_tipo_comprobante != OLD.id_tipo_comprobante OR
       NEW.serie != OLD.serie OR
       NEW.numero != OLD.numero OR
       NEW.fecha_emision != OLD.fecha_emision OR
       NEW.total_gravado != OLD.total_gravado OR
       NEW.total_exonerado != OLD.total_exonerado OR
       NEW.total_inafecto != OLD.total_inafecto OR
       NEW.total_igv != OLD.total_igv OR
       NEW.monto_total != OLD.monto_total OR
       NEW.codigo_moneda != OLD.codigo_moneda THEN
      RAISE EXCEPTION 'Fiscal data in comprobantes header is immutable. Cannot modify core fields (serie, numero, totals, currency, dates, etc.) once issued.';
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_comprobantes_header_immutable
  BEFORE UPDATE ON comprobantes
  FOR EACH ROW EXECUTE FUNCTION fn_comprobantes_header_immutable();

COMMIT;
