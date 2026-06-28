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

DROP POLICY IF EXISTS productos_tenant_isolation ON productos;
CREATE POLICY productos_tenant_isolation ON productos
    USING (id_empresa = current_setting('app.id_empresa', true)::uuid)
    WITH CHECK (id_empresa = current_setting('app.id_empresa', true)::uuid);

-- 2. categorias_menu
ALTER TABLE categorias_menu ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS categorias_menu_tenant_isolation ON categorias_menu;
CREATE POLICY categorias_menu_tenant_isolation ON categorias_menu
    USING (id_empresa = current_setting('app.id_empresa', true)::uuid)
    WITH CHECK (id_empresa = current_setting('app.id_empresa', true)::uuid);

-- 3. sucursales
ALTER TABLE sucursales ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS sucursales_tenant_isolation ON sucursales;
CREATE POLICY sucursales_tenant_isolation ON sucursales
    USING (id_empresa = current_setting('app.id_empresa', true)::uuid)
    WITH CHECK (id_empresa = current_setting('app.id_empresa', true)::uuid);

-- 4. configuracion_empresa
ALTER TABLE configuracion_empresa ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS configuracion_empresa_tenant_isolation ON configuracion_empresa;
CREATE POLICY configuracion_empresa_tenant_isolation ON configuracion_empresa
    USING (id_empresa = current_setting('app.id_empresa', true)::uuid)
    WITH CHECK (id_empresa = current_setting('app.id_empresa', true)::uuid);

-- 5. usuario_roles
ALTER TABLE usuario_roles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS usuario_roles_tenant_isolation ON usuario_roles;
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

-- 6. suscripciones (directo por id_empresa)
ALTER TABLE suscripciones ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS suscripciones_tenant_isolation ON suscripciones;
CREATE POLICY suscripciones_tenant_isolation ON suscripciones
    USING (id_empresa = current_setting('app.id_empresa', true)::uuid)
    WITH CHECK (id_empresa = current_setting('app.id_empresa', true)::uuid);

-- 7. roles (por id_empresa IS NULL OR id_empresa = context_tenant)
ALTER TABLE roles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS roles_tenant_isolation ON roles;
CREATE POLICY roles_tenant_isolation ON roles
    USING (id_empresa IS NULL OR id_empresa = current_setting('app.id_empresa', true)::uuid)
    WITH CHECK (id_empresa IS NULL OR id_empresa = current_setting('app.id_empresa', true)::uuid);

-- 8. rol_permisos (indirecto por EXISTS en roles)
ALTER TABLE rol_permisos ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS rol_permisos_tenant_isolation ON rol_permisos;
CREATE POLICY rol_permisos_tenant_isolation ON rol_permisos
    USING (
        EXISTS (
            SELECT 1 FROM roles r
            WHERE r.id_rol = rol_permisos.id_rol
              AND (r.id_empresa IS NULL OR r.id_empresa = current_setting('app.id_empresa', true)::uuid)
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM roles r
            WHERE r.id_rol = rol_permisos.id_rol
              AND (r.id_empresa IS NULL OR r.id_empresa = current_setting('app.id_empresa', true)::uuid)
        )
    );

-- 9. secuencias_empresa (directo por id_empresa)
ALTER TABLE secuencias_empresa ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS secuencias_empresa_tenant_isolation ON secuencias_empresa;
CREATE POLICY secuencias_empresa_tenant_isolation ON secuencias_empresa
    USING (id_empresa = current_setting('app.id_empresa', true)::uuid)
    WITH CHECK (id_empresa = current_setting('app.id_empresa', true)::uuid);

-- 10. usuario_sucursales (indirecto por EXISTS en sucursales)
ALTER TABLE usuario_sucursales ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS usuario_sucursales_tenant_isolation ON usuario_sucursales;
CREATE POLICY usuario_sucursales_tenant_isolation ON usuario_sucursales
    USING (
        EXISTS (
            SELECT 1 FROM sucursales s
            WHERE s.id_sucursal = usuario_sucursales.id_sucursal
              AND s.id_empresa = current_setting('app.id_empresa', true)::uuid
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM sucursales s
            WHERE s.id_sucursal = usuario_sucursales.id_sucursal
              AND s.id_empresa = current_setting('app.id_empresa', true)::uuid
        )
    );

-- 11. vouchers (indirecto por EXISTS en pagos)
ALTER TABLE vouchers ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS vouchers_tenant_isolation ON vouchers;
CREATE POLICY vouchers_tenant_isolation ON vouchers
    USING (
        EXISTS (
            SELECT 1 FROM pagos p
            WHERE p.id_pago = vouchers.id_pago
              AND p.id_empresa = current_setting('app.id_empresa', true)::uuid
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM pagos p
            WHERE p.id_pago = vouchers.id_pago
              AND p.id_empresa = current_setting('app.id_empresa', true)::uuid
        )
    );

-- 12. arqueos_caja (indirecto por EXISTS en aperturas_caja)
ALTER TABLE arqueos_caja ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS arqueos_caja_tenant_isolation ON arqueos_caja;
CREATE POLICY arqueos_caja_tenant_isolation ON arqueos_caja
    USING (
        EXISTS (
            SELECT 1 FROM aperturas_caja a
            WHERE a.id = arqueos_caja.id_apertura_caja
              AND a.id_empresa = current_setting('app.id_empresa', true)::uuid
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM aperturas_caja a
            WHERE a.id = arqueos_caja.id_apertura_caja
              AND a.id_empresa = current_setting('app.id_empresa', true)::uuid
        )
    );

COMMIT;
