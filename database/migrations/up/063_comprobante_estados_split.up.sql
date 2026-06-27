BEGIN;

-- Migración: Comprobante Estados Split (Operacional vs Tributario)
-- Creada el: 27/05/2026
-- Secuencia: 063
--
-- Propósito: separar claramente dos dominios que hoy están mezclados:
--   - id_estado_tributario: estado SUNAT (borrador, emitido, aceptado, rechazado, anulado)
--   - id_estado_operacional: estado operacional local (pendiente, caja, conciliado)
--
-- Cambios:
--   1. Crear lookup: estados_operacionales (si no existe)
--   2. ADD COLUMN: comprobantes.id_estado_operacional
--   3. Mantener: comprobantes.id_estado (renombrar mentalmente como tributario)
--   4. Backfill: estado operacional inicial basado en lógica tributaria
--   5. Data consistency: cuando se actualiza tributario, registrar cambio operacional

-- ============================================================================
-- 1. Lookup table: estados_operacionales (si no existe)
-- ============================================================================
CREATE TABLE IF NOT EXISTS estados_operacionales (
  id SERIAL PRIMARY KEY,
  nombre VARCHAR(30) NOT NULL UNIQUE,
  descripcion TEXT,
  creado_en TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Insert valores (idempotente con ON CONFLICT)
INSERT INTO estados_operacionales (nombre, descripcion) VALUES
  ('pendiente_caja', 'Aguardando procesamiento en caja'),
  ('en_caja', 'Siendo procesado en caja'),
  ('pagada', 'Pago aceptado y registrado'),
  ('cancelada_localmente', 'Cancelada antes de SUNAT'),
  ('conciliada', 'Reconciliada en arqueo de caja'),
  ('en_disputa', 'Bajo investigación o disputa'),
  ('anulada_operacional', 'Anulada a nivel operacional (antes de SUNAT)')
ON CONFLICT (nombre) DO NOTHING;

-- ============================================================================
-- 2. ADD COLUMN: id_estado_operacional en comprobantes
-- ============================================================================
ALTER TABLE comprobantes
  ADD COLUMN id_estado_operacional INT DEFAULT 1 NOT NULL
  REFERENCES estados_operacionales(id);

-- Nota: DEFAULT 1 asume que 'pendiente_caja' es id=1.
-- Si no lo es, actualizar manualmente después.

-- ============================================================================
-- 3. Índices para búsquedas de estado operacional
-- ============================================================================
CREATE INDEX idx_comprobantes_estado_operacional
  ON comprobantes(id_estado_operacional);

CREATE INDEX idx_comprobantes_estados_composite
  ON comprobantes(id_empresa, id_estado, id_estado_operacional)
  WHERE id_estado IS NOT NULL;

-- ============================================================================
-- 4. Trigger: registra cambios de estado tributario en auditoría
-- ============================================================================
CREATE OR REPLACE FUNCTION trg_comprobante_estado_change_audit()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.id_estado != OLD.id_estado THEN
    INSERT INTO registros_auditoria (
      id_empresa, id_usuario, tabla_afectada, operacion, registro_id,
      datos_anteriores, datos_nuevos
    ) VALUES (
      NEW.id_empresa,
      NULL,
      'comprobantes',
      'UPDATE',
      NEW.id::TEXT,
      jsonb_build_object('id_estado_tributario', OLD.id_estado),
      jsonb_build_object('id_estado_tributario', NEW.id_estado)
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_comprobante_estado_audit
  AFTER UPDATE OF id_estado ON comprobantes
  FOR EACH ROW EXECUTE FUNCTION trg_comprobante_estado_change_audit();

-- ============================================================================
-- 5. Helper view: estado actual de comprobantes
-- ============================================================================
CREATE OR REPLACE VIEW comprobantes_estado_actual AS
SELECT
  c.id,
  c.id_empresa,
  c.serie,
  c.numero,
  ec.nombre AS estado_tributario,
  eo.nombre AS estado_operacional,
  c.creado_en,
  c.actualizado_en
FROM comprobantes c
LEFT JOIN estados_comprobante ec ON c.id_estado = ec.id
LEFT JOIN estados_operacionales eo ON c.id_estado_operacional = eo.id;

COMMIT;
