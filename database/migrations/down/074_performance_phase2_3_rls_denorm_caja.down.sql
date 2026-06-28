BEGIN;

-- Rollback: Performance Phase 2/3 - RLS Denormalization + Caja Optimization
-- Versión: 074

-- ============================================================================
-- Eliminar materialized view y recrear trigger
-- ============================================================================
DROP MATERIALIZED VIEW IF EXISTS caja_saldos CASCADE;

-- Recrear trigger costoso (rollback a estado anterior)
CREATE OR REPLACE FUNCTION actualizar_monto_cierre_caja()
RETURNS TRIGGER AS $$
DECLARE
    v_id_apertura UUID;
BEGIN
    v_id_apertura := COALESCE(NEW.id_apertura_caja, OLD.id_apertura_caja);

    UPDATE aperturas_caja
    SET monto_cierre = monto_inicial + (
        SELECT COALESCE(SUM(monto), 0)
        FROM movimientos_caja
        WHERE id_apertura_caja = v_id_apertura
    )
    WHERE id = v_id_apertura;

    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_movimiento_actualiza_monto_cierre
    AFTER INSERT OR UPDATE OR DELETE ON movimientos_caja
    FOR EACH ROW EXECUTE FUNCTION actualizar_monto_cierre_caja();

-- ============================================================================
-- Revertir denormalización en movimientos_caja
-- ============================================================================

-- Restaurar RLS policy original (EXISTS join)
DROP POLICY movimientos_caja_tenant_isolation ON movimientos_caja;

CREATE POLICY movimientos_caja_tenant_isolation ON movimientos_caja
    USING (
        EXISTS (
            SELECT 1 FROM aperturas_caja ac
            WHERE ac.id = movimientos_caja.id_apertura_caja
              AND ac.id_empresa = current_setting('app.id_empresa', true)::uuid
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM aperturas_caja ac
            WHERE ac.id = movimientos_caja.id_apertura_caja
              AND ac.id_empresa = current_setting('app.id_empresa', true)::uuid
        )
    );

-- Eliminar índice
DROP INDEX IF EXISTS idx_movimientos_caja_empresa;

-- Eliminar columna denormalizada
ALTER TABLE movimientos_caja DROP COLUMN id_empresa;

-- ============================================================================
-- Revertir denormalización en comprobante_detalles
-- ============================================================================

-- Restaurar RLS policy original (EXISTS join)
DROP POLICY comprobante_detalles_tenant_isolation ON comprobante_detalles;

CREATE POLICY comprobante_detalles_tenant_isolation ON comprobante_detalles
    USING (
        EXISTS (
            SELECT 1 FROM comprobantes c
            WHERE c.id = comprobante_detalles.id_comprobante
              AND c.id_empresa = current_setting('app.id_empresa', true)::uuid
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM comprobantes c
            WHERE c.id = comprobante_detalles.id_comprobante
              AND c.id_empresa = current_setting('app.id_empresa', true)::uuid
        )
    );

-- Eliminar índice
DROP INDEX IF EXISTS idx_comprobante_detalles_empresa;

-- Eliminar columna denormalizada
ALTER TABLE comprobante_detalles DROP COLUMN id_empresa;

COMMIT;
