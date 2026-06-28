BEGIN;

-- Migración: índices compuestos POS + columna protegido + trigger inmutabilidad items_orden
-- Creada el: 26/05/2026
-- Secuencia: 039
--
-- Propósito:
-- 1. Agregar ordenes.protegido para marcar órdenes cuyo detalle no puede modificarse.
-- 2. Trigger BEFORE UPDATE/DELETE en items_orden que bloquea cambios en órdenes protegidas.
-- 3. Índices compuestos para queries POS de alta frecuencia (empresa+estado+fecha).

-- Agregar columna protegido en ordenes
ALTER TABLE ordenes ADD COLUMN IF NOT EXISTS protegido BOOLEAN NOT NULL DEFAULT FALSE;

-- Función: validar que la orden padre no está protegida antes de UPDATE/DELETE en items_orden
CREATE OR REPLACE FUNCTION validar_items_orden_protegido()
RETURNS TRIGGER AS $$
DECLARE
  v_protegido BOOLEAN;
BEGIN
  SELECT protegido INTO v_protegido
  FROM ordenes
  WHERE id_orden = OLD.id_orden;

  IF v_protegido THEN
    RAISE EXCEPTION 'items_orden: orden % está protegida — no se permite UPDATE/DELETE', OLD.id_orden;
  END IF;

  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Trigger: BEFORE UPDATE OR DELETE en items_orden
DROP TRIGGER IF EXISTS trg_items_orden_protegido ON items_orden;
CREATE TRIGGER trg_items_orden_protegido
  BEFORE UPDATE OR DELETE ON items_orden
  FOR EACH ROW EXECUTE FUNCTION validar_items_orden_protegido();

-- Índice compuesto para consultas POS de órdenes (empresa + estado + fecha desc)
CREATE INDEX IF NOT EXISTS idx_ordenes_empresa_estado_fecha
  ON ordenes(id_empresa, id_estado_orden, creado_en DESC);

-- Índice compuesto para consultas de aperturas de caja (empresa + estado + fecha desc)
CREATE INDEX IF NOT EXISTS idx_aperturas_caja_empresa_estado_fecha
  ON aperturas_caja(id_empresa, id_estado_caja, fecha_apertura DESC);

COMMIT;
