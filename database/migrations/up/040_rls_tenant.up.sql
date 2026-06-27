BEGIN;

-- =============================================================================
-- PREREQUISITO OBLIGATORIO: Middleware Go
-- =============================================================================
-- Este archivo habilita Row Level Security (RLS) en 6 tablas tenant-scoped.
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
-- =============================================================================

-- Tabla de introspección para debugging de RLS en entornos non-production
CREATE TABLE IF NOT EXISTS rls_context (
    id_empresa  UUID        NOT NULL,
    validado    BOOLEAN     DEFAULT FALSE,
    creado_en   TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- ORDENES — id_empresa directo
-- =============================================================================
ALTER TABLE ordenes ENABLE ROW LEVEL SECURITY;

CREATE POLICY ordenes_tenant_isolation ON ordenes
    USING (
        id_empresa = current_setting('app.id_empresa', true)::uuid
    )
    WITH CHECK (
        id_empresa = current_setting('app.id_empresa', true)::uuid
    );

-- =============================================================================
-- PAGOS_ORDEN — FK indirecto via ordenes
-- =============================================================================
ALTER TABLE pagos_orden ENABLE ROW LEVEL SECURITY;

CREATE POLICY pagos_orden_tenant_isolation ON pagos_orden
    USING (
        EXISTS (
            SELECT 1 FROM ordenes o
            WHERE o.id_orden = pagos_orden.id_orden
              AND o.id_empresa = current_setting('app.id_empresa', true)::uuid
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM ordenes o
            WHERE o.id_orden = pagos_orden.id_orden
              AND o.id_empresa = current_setting('app.id_empresa', true)::uuid
        )
    );

-- =============================================================================
-- ITEMS_ORDEN — FK indirecto via ordenes
-- =============================================================================
ALTER TABLE items_orden ENABLE ROW LEVEL SECURITY;

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

-- =============================================================================
-- APERTURAS_CAJA — id_empresa directo (denormalizado desde migración 038)
-- =============================================================================
ALTER TABLE aperturas_caja ENABLE ROW LEVEL SECURITY;

CREATE POLICY aperturas_caja_tenant_isolation ON aperturas_caja
    USING (
        id_empresa = current_setting('app.id_empresa', true)::uuid
    )
    WITH CHECK (
        id_empresa = current_setting('app.id_empresa', true)::uuid
    );

-- =============================================================================
-- MOVIMIENTOS_CAJA — FK indirecto via aperturas_caja
-- =============================================================================
ALTER TABLE movimientos_caja ENABLE ROW LEVEL SECURITY;

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

-- =============================================================================
-- USUARIOS — solo scope='operativo' con id_empresa
-- Nota: usuarios globales (scope='global', id_empresa NULL) NO están cubiertos
-- por esta policy y siguen siendo visibles sin restricción de tenant.
-- =============================================================================
ALTER TABLE usuarios ENABLE ROW LEVEL SECURITY;

CREATE POLICY usuarios_operativos_tenant_isolation ON usuarios
    USING (
        scope = 'operativo'
        AND id_empresa = current_setting('app.id_empresa', true)::uuid
    )
    WITH CHECK (
        scope = 'operativo'
        AND id_empresa = current_setting('app.id_empresa', true)::uuid
    );

COMMIT;
