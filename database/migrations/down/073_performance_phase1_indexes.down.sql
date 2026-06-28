BEGIN;

-- Rollback: Performance Phase 1 - Índices y Denormalización
-- Versión: 073

-- ============================================================================
-- 1. Eliminar Índices Compuestos
-- ============================================================================
DROP INDEX IF EXISTS idx_ordenes_usuario_fecha;
DROP INDEX IF EXISTS idx_ordenes_sucursal_estado_fecha;
DROP INDEX IF EXISTS idx_ordenes_activas_estado;
DROP INDEX IF EXISTS idx_productos_categoria_disponibles;
DROP INDEX IF EXISTS idx_producto_sucursales_lookup;
DROP INDEX IF EXISTS idx_usuario_roles_active;
DROP INDEX IF EXISTS idx_pagos_orden_reconciliacion;
DROP INDEX IF EXISTS idx_sesiones_activas_lookup;

-- ============================================================================
-- 2. Revertar Denormalización de id_empresa en items_orden
-- ============================================================================

-- Restaurar RLS policy original (EXISTS join)
DROP POLICY items_orden_tenant_isolation ON items_orden;

CREATE POLICY items_orden_tenant_isolation ON items_orden
    USING (
        EXISTS (
            SELECT 1 FROM ordenes o
            WHERE o.id_orden = items_orden.id_orden
              AND o.id_empresa = current_setting('app.id_empresa', true)::uuid
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM ordenes o
            WHERE o.id_orden = items_orden.id_orden
              AND o.id_empresa = current_setting('app.id_empresa', true)::uuid
        )
    );

-- Eliminar índice en id_empresa
DROP INDEX IF EXISTS idx_items_orden_empresa;

-- Eliminar columna denormalizada
ALTER TABLE items_orden DROP COLUMN id_empresa;

-- ============================================================================
-- 3. Revertir Configuración de AUTOVACUUM a Defaults
-- ============================================================================
ALTER TABLE ordenes RESET (autovacuum_vacuum_scale_factor);
ALTER TABLE ordenes RESET (autovacuum_analyze_scale_factor);
ALTER TABLE ordenes RESET (autovacuum_vacuum_cost_delay);

ALTER TABLE items_orden RESET (autovacuum_vacuum_scale_factor);
ALTER TABLE items_orden RESET (autovacuum_analyze_scale_factor);

ALTER TABLE movimientos_caja RESET (autovacuum_vacuum_scale_factor);
ALTER TABLE movimientos_caja RESET (autovacuum_analyze_scale_factor);

ALTER TABLE sesiones RESET (autovacuum_vacuum_scale_factor);

COMMIT;
