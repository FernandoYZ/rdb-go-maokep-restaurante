BEGIN;

-- Rollback:   producto_sucursales
-- Created:    2026-06-27
-- Version:    069

-- 1. Eliminar índice
DROP INDEX IF EXISTS idx_producto_sucursales_suc_disp;

-- 2. Eliminar política RLS
DROP POLICY IF EXISTS producto_sucursales_tenant_isolation ON producto_sucursales;

-- 3. Eliminar trigger
DROP TRIGGER IF EXISTS trg_actualizado_en_producto_sucursales ON producto_sucursales;

-- 4. Eliminar tabla
DROP TABLE IF EXISTS producto_sucursales;

COMMIT;
