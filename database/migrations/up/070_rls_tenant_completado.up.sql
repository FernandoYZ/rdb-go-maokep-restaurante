BEGIN;

-- Migration:  rls_tenant_completado
-- Created:    2026-06-27
-- Version:    070
--
-- Propósito: Habilitar Row Level Security (RLS) en el resto de tablas maestras 
--            y configuracionales asociadas al tenant (empresa) para evitar 
--            filtraciones de datos accidentales a nivel de base de datos.

-- 1. productos
ALTER TABLE productos ENABLE ROW LEVEL SECURITY;

CREATE POLICY productos_tenant_isolation ON productos
    USING (id_empresa = current_setting('app.id_empresa', true)::uuid)
    WITH CHECK (id_empresa = current_setting('app.id_empresa', true)::uuid);

-- 2. categorias_menu
ALTER TABLE categorias_menu ENABLE ROW LEVEL SECURITY;

CREATE POLICY categorias_menu_tenant_isolation ON categorias_menu
    USING (id_empresa = current_setting('app.id_empresa', true)::uuid)
    WITH CHECK (id_empresa = current_setting('app.id_empresa', true)::uuid);

-- 3. sucursales
ALTER TABLE sucursales ENABLE ROW LEVEL SECURITY;

CREATE POLICY sucursales_tenant_isolation ON sucursales
    USING (id_empresa = current_setting('app.id_empresa', true)::uuid)
    WITH CHECK (id_empresa = current_setting('app.id_empresa', true)::uuid);

-- 4. configuracion_empresa
ALTER TABLE configuracion_empresa ENABLE ROW LEVEL SECURITY;

CREATE POLICY configuracion_empresa_tenant_isolation ON configuracion_empresa
    USING (id_empresa = current_setting('app.id_empresa', true)::uuid)
    WITH CHECK (id_empresa = current_setting('app.id_empresa', true)::uuid);

-- 5. usuario_roles
ALTER TABLE usuario_roles ENABLE ROW LEVEL SECURITY;

CREATE POLICY usuario_roles_tenant_isolation ON usuario_roles
    USING (
        EXISTS (
            SELECT 1 FROM usuarios u
            WHERE u.id_usuario = usuario_roles.id_usuario
              AND u.id_empresa = current_setting('app.id_empresa', true)::uuid
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM usuarios u
            WHERE u.id_usuario = usuario_roles.id_usuario
              AND u.id_empresa = current_setting('app.id_empresa', true)::uuid
        )
    );

COMMIT;
