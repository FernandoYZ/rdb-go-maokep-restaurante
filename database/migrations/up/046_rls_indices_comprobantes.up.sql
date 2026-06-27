BEGIN;

-- =============================================================================
-- PREREQUISITO OBLIGATORIO: Middleware Go
-- =============================================================================
-- Este archivo habilita Row Level Security (RLS) en las tablas del módulo
-- de comprobantes electrónicos SUNAT.
--
-- ANTES DE CUALQUIER QUERY en estas tablas, el handler Go DEBE ejecutar:
--
--     SET LOCAL app.id_empresa = '<uuid-de-la-empresa>';
--
-- dentro de la misma transacción. Sin esto:
--   - current_setting('app.id_empresa', true) retorna NULL o cadena vacía
--   - TODAS las SELECT/UPDATE/DELETE en tablas RLS retornan 0 filas
--   - La aplicación quedará completamente rota (0 filas en todas las consultas)
--
-- NO HACER DEPLOY A PRODUCCIÓN SIN EL MIDDLEWARE GO IMPLEMENTADO.
-- Ver: docs/RLS_MIDDLEWARE_SETUP.md
-- Patrón establecido por migración 040 (Phase 3 RLS).
-- =============================================================================

-- =============================================================================
-- TIPOS_COMPROBANTE — tabla global compartida, sin RLS
-- =============================================================================
-- tipos_comprobante es un catálogo global (no tenant-scoped).
-- Todos los tenants ven los mismos tipos SUNAT (01 Factura, 03 Boleta).
-- NO se habilita RLS en esta tabla — acceso universal de lectura.

-- =============================================================================
-- ESTADOS_COMPROBANTE — tabla global compartida, sin RLS
-- =============================================================================
-- estados_comprobante es un catálogo global (no tenant-scoped).
-- Todos los tenants usan los mismos estados del ciclo de vida SUNAT.
-- NO se habilita RLS en esta tabla — acceso universal de lectura.

-- =============================================================================
-- SERIES_COMPROBANTE — id_empresa directo
-- =============================================================================
ALTER TABLE series_comprobante ENABLE ROW LEVEL SECURITY;

CREATE POLICY series_comprobante_tenant_isolation ON series_comprobante
    USING (
        id_empresa = current_setting('app.id_empresa', true)::uuid
    )
    WITH CHECK (
        id_empresa = current_setting('app.id_empresa', true)::uuid
    );

-- =============================================================================
-- COMPROBANTES — id_empresa directo
-- =============================================================================
ALTER TABLE comprobantes ENABLE ROW LEVEL SECURITY;

CREATE POLICY comprobantes_tenant_isolation ON comprobantes
    USING (
        id_empresa = current_setting('app.id_empresa', true)::uuid
    )
    WITH CHECK (
        id_empresa = current_setting('app.id_empresa', true)::uuid
    );

-- =============================================================================
-- COMPROBANTE_DETALLES — FK indirecto via comprobantes
-- =============================================================================
ALTER TABLE comprobante_detalles ENABLE ROW LEVEL SECURITY;

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

-- =============================================================================
-- ENVIOS_SUNAT — FK indirecto via comprobantes
-- =============================================================================
ALTER TABLE envios_sunat ENABLE ROW LEVEL SECURITY;

CREATE POLICY envios_sunat_tenant_isolation ON envios_sunat
    USING (
        EXISTS (
            SELECT 1 FROM comprobantes c
            WHERE c.id = envios_sunat.id_comprobante
              AND c.id_empresa = current_setting('app.id_empresa', true)::uuid
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM comprobantes c
            WHERE c.id = envios_sunat.id_comprobante
              AND c.id_empresa = current_setting('app.id_empresa', true)::uuid
        )
    );

-- =============================================================================
-- ÍNDICES COMPUESTOS — rendimiento en queries de reportes y POS
-- =============================================================================

-- Series por empresa: búsqueda rápida de series activas por tipo
CREATE INDEX idx_series_empresa_tipo_creado
    ON series_comprobante(id_empresa, id_tipo_comprobante, creado_en DESC);

COMMIT;
