BEGIN;

-- Migración: Performance Phase 2/3 - RLS Denormalization + Caja Optimization
-- Creada el: 2026-06-27
-- Versión: 074
--
-- Propósito:
-- Phase 2: Eliminar costosos EXISTS joins en RLS policies
--   - Denormalizar id_empresa en comprobante_detalles
--   - Denormalizar id_empresa en movimientos_caja
-- Phase 3: Reemplazar trigger de caja con materialized view
--   - Crear caja_saldos (pre-aggregated cash register balances)
--   - Eliminar overhead de SUM en cada INSERT

-- ============================================================================
-- PHASE 2: RLS DENORMALIZATION
-- ============================================================================

-- ============================================================================
-- 2.1 Denormalizar id_empresa en comprobante_detalles
-- ============================================================================

ALTER TABLE comprobante_detalles ADD COLUMN IF NOT EXISTS id_empresa UUID;

-- Backfill desde comprobantes (relación 1:N)
UPDATE comprobante_detalles SET id_empresa = (
    SELECT c.id_empresa FROM comprobantes c WHERE c.id = comprobante_detalles.id_comprobante
) WHERE id_empresa IS NULL;

ALTER TABLE comprobante_detalles ALTER COLUMN id_empresa SET NOT NULL;

-- Crear índice para RLS performance
CREATE INDEX IF NOT EXISTS idx_comprobante_detalles_empresa ON comprobante_detalles(id_empresa);

-- Actualizar RLS policy para usar comparación directa (10x más rápido)
DROP POLICY comprobante_detalles_tenant_isolation ON comprobante_detalles;

CREATE POLICY comprobante_detalles_tenant_isolation ON comprobante_detalles
    USING (id_empresa = current_setting('app.id_empresa', true)::uuid)
    WITH CHECK (id_empresa = current_setting('app.id_empresa', true)::uuid);

-- ============================================================================
-- 2.2 Denormalizar id_empresa en movimientos_caja
-- ============================================================================

ALTER TABLE movimientos_caja ADD COLUMN IF NOT EXISTS id_empresa UUID;

-- Backfill desde aperturas_caja
UPDATE movimientos_caja SET id_empresa = (
    SELECT ac.id_empresa FROM aperturas_caja ac WHERE ac.id = movimientos_caja.id_apertura_caja
) WHERE id_empresa IS NULL;

ALTER TABLE movimientos_caja ALTER COLUMN id_empresa SET NOT NULL;

-- Crear índice para RLS performance
CREATE INDEX IF NOT EXISTS idx_movimientos_caja_empresa ON movimientos_caja(id_empresa);

-- Actualizar RLS policy para usar comparación directa
DROP POLICY movimientos_caja_tenant_isolation ON movimientos_caja;

CREATE POLICY movimientos_caja_tenant_isolation ON movimientos_caja
    USING (id_empresa = current_setting('app.id_empresa', true)::uuid)
    WITH CHECK (id_empresa = current_setting('app.id_empresa', true)::uuid);

-- ============================================================================
-- PHASE 3: CAJA OPTIMIZATION
-- ============================================================================

-- ============================================================================
-- 3.1 Crear materialized view: caja_saldos
-- ============================================================================
-- Pre-agregados: saldos de cajas calculados una sola vez
-- Sin trigger costoso en cada movimiento

CREATE MATERIALIZED VIEW caja_saldos AS
SELECT
    ac.id as id_apertura_caja,
    ac.id_empresa,
    ac.id_sucursal,
    ac.monto_inicial,
    COALESCE(SUM(mc.monto), 0)::NUMERIC(12,2) as monto_movimientos,
    ac.monto_inicial + COALESCE(SUM(mc.monto), 0)::NUMERIC(12,2) as monto_cierre_calculado,
    COUNT(mc.id) as num_movimientos,
    MAX(mc.creado_en) as ultimo_movimiento_en
FROM aperturas_caja ac
LEFT JOIN movimientos_caja mc ON ac.id = mc.id_apertura_caja
WHERE ac.id_estado_caja <> 2 -- Optimización: Excluir cajas cerradas (id_estado_caja = 2) de la vista materializada activa
GROUP BY ac.id, ac.id_empresa, ac.id_sucursal, ac.monto_inicial;

-- Índices en la vista materializada
CREATE UNIQUE INDEX IF NOT EXISTS idx_caja_saldos_apertura ON caja_saldos(id_apertura_caja);
CREATE INDEX IF NOT EXISTS idx_caja_saldos_empresa ON caja_saldos(id_empresa);
CREATE INDEX IF NOT EXISTS idx_caja_saldos_sucursal ON caja_saldos(id_sucursal);

-- Vista unificada de saldos de caja: histórico consolidado en tabla + cajas activas en la vista materializada
CREATE OR REPLACE VIEW v_caja_saldos WITH (security_invoker = true) AS
SELECT 
    id AS id_apertura_caja,
    id_empresa,
    id_sucursal,
    monto_inicial,
    (monto_cierre - monto_inicial) AS monto_movimientos,
    monto_cierre AS monto_cierre_calculado,
    NULL::BIGINT AS num_movimientos,
    fecha_cierre AS ultimo_movimiento_en,
    TRUE AS es_historico
FROM aperturas_caja
WHERE id_estado_caja = 2 AND id_empresa = current_setting('app.id_empresa', true)::uuid
UNION ALL
SELECT 
    id_apertura_caja,
    id_empresa,
    id_sucursal,
    monto_inicial,
    monto_movimientos,
    monto_cierre_calculado,
    num_movimientos,
    ultimo_movimiento_en,
    FALSE AS es_historico
FROM caja_saldos
WHERE id_empresa = current_setting('app.id_empresa', true)::uuid;

-- ============================================================================
-- 3.2 Remover trigger costoso de actualizar_monto_cierre_caja
-- ============================================================================
-- El trigger recalculaba SUM en cada INSERT/UPDATE/DELETE
-- Ahora usamos materialized view que se refresca on-demand o periódicamente

DROP TRIGGER IF EXISTS trg_movimiento_actualiza_monto_cierre ON movimientos_caja;
DROP FUNCTION IF EXISTS actualizar_monto_cierre_caja();

-- Nota: Aplicación debe llamar:
-- REFRESH MATERIALIZED VIEW CONCURRENTLY caja_saldos;
-- al cierre de turno o en schedule periódico

COMMIT;
