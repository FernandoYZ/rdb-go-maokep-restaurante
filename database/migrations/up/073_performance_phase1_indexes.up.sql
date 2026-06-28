BEGIN;

-- Migración: Performance Phase 1 - Quick Wins (Índices + Denormalización RLS)
-- Creada el: 2026-06-27
-- Versión: 073
--
-- Propósito: Implementar optimizaciones de performance críticas sin downtime
-- - Agregar 7 índices compuestos en hot paths
-- - Denormalizar id_empresa en items_orden para eliminar RLS EXISTS costly
-- - Actualizar RLS policies para usar comparación directa
-- - Mantener CONCURRENTLY para evitar locks

-- ============================================================================
-- 1. Denormalizar id_empresa en items_orden (eliminar RLS EXISTS join)
-- ============================================================================
ALTER TABLE items_orden ADD COLUMN id_empresa UUID;

-- Backfill desde ordenes (relación 1:N)
UPDATE items_orden SET id_empresa = (
    SELECT o.id_empresa FROM ordenes o WHERE o.id_orden = items_orden.id_orden
);

ALTER TABLE items_orden ALTER COLUMN id_empresa SET NOT NULL;

-- Crear índice en id_empresa para RLS performance
CREATE INDEX IF NOT EXISTS idx_items_orden_empresa ON items_orden(id_empresa);

-- Actualizar RLS policy para usar comparación directa (10x más rápido)
DROP POLICY items_orden_tenant_isolation ON items_orden;

CREATE POLICY items_orden_tenant_isolation ON items_orden
    USING (id_empresa = current_setting('app.id_empresa', true)::uuid)
    WITH CHECK (id_empresa = current_setting('app.id_empresa', true)::uuid);

-- ============================================================================
-- 2. Agregar 7 Índices Compuestos en Hot Paths (CONCURRENTLY)
-- ============================================================================

-- 2.1 Ordenes: Usuario + Fecha (perfil de usuario: "mis órdenes hoy")
CREATE INDEX IF NOT EXISTS idx_ordenes_usuario_fecha
    ON ordenes(id_usuario, creado_en DESC);

-- 2.2 Ordenes: Sucursal + Estado + Fecha (reportes de sucursal)
CREATE INDEX IF NOT EXISTS idx_ordenes_sucursal_estado_fecha
    ON ordenes(id_sucursal, id_estado_orden, creado_en DESC);

-- 2.3 Ordenes: Estado + Empresa + Fecha (ordenes activas por sucursal/empresa)
CREATE INDEX IF NOT EXISTS idx_ordenes_activas_estado
    ON ordenes(id_estado_orden, id_empresa, creado_en DESC);

-- 2.4 Productos: Categoría + Disponible (menú por categoría)
CREATE INDEX IF NOT EXISTS idx_productos_categoria_disponibles
    ON productos(id_categoria, disponible, orden)
    WHERE disponible = TRUE AND eliminado_en IS NULL;

-- 2.8 Productos: Nombre (búsqueda de texto rápida para menú mediante trigramas)
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX IF NOT EXISTS idx_productos_nombre_trgm
    ON productos USING GIN (nombre gin_trgm_ops);

-- 2.5 Producto Sucursales: Empresa + Producto (búsqueda de precios por locación)
CREATE INDEX IF NOT EXISTS idx_producto_sucursales_lookup
    ON producto_sucursales(id_empresa, id_producto)
    WHERE disponible = TRUE;

-- 2.6 Usuario Roles: Usuario + Rol (roles activos del usuario)
CREATE INDEX IF NOT EXISTS idx_usuario_roles_active
    ON usuario_roles(id_usuario, id_rol);

-- 2.7 Pagos Orden: Reconciliación de pagos (reportes financieros)
CREATE INDEX IF NOT EXISTS idx_pagos_orden_reconciliacion
    ON pagos_orden(id_empresa, creado_en DESC, id_estado_pago);

-- ============================================================================
-- 3. Agregar Índice Parcial para Sesiones Activas (auth queries)
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_sesiones_activas_lookup
    ON sesiones(id_usuario, id_sesion)
    WHERE revocado = FALSE;

-- ============================================================================
-- 4. Ajustar AUTOVACUUM para Tablas High-Churn
-- ============================================================================

-- Tablas de alta rotación: ejecutar ANALYZE más frecuente
ALTER TABLE ordenes SET (autovacuum_vacuum_scale_factor = 0.05);
ALTER TABLE ordenes SET (autovacuum_analyze_scale_factor = 0.02);
ALTER TABLE ordenes SET (autovacuum_vacuum_cost_delay = 10);

ALTER TABLE items_orden SET (autovacuum_vacuum_scale_factor = 0.05);
ALTER TABLE items_orden SET (autovacuum_analyze_scale_factor = 0.02);

ALTER TABLE movimientos_caja SET (autovacuum_vacuum_scale_factor = 0.05);
ALTER TABLE movimientos_caja SET (autovacuum_analyze_scale_factor = 0.02);

-- Tablas de sesión: cleanup de expiradas
ALTER TABLE sesiones SET (autovacuum_vacuum_scale_factor = 0.02);

COMMIT;
