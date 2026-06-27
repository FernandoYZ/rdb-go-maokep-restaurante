BEGIN;

-- Rollback:   rls_tenant_completado
-- Created:    2026-06-27
-- Version:    070

-- 1. Deshabilitar RLS y borrar políticas
ALTER TABLE productos DISABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS productos_tenant_isolation ON productos;

ALTER TABLE categorias_menu DISABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS categorias_menu_tenant_isolation ON categorias_menu;

ALTER TABLE sucursales DISABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS sucursales_tenant_isolation ON sucursales;

ALTER TABLE configuracion_empresa DISABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS configuracion_empresa_tenant_isolation ON configuracion_empresa;

ALTER TABLE usuario_roles DISABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS usuario_roles_tenant_isolation ON usuario_roles;

COMMIT;
