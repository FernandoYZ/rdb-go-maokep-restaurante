BEGIN;

-- Migración: RLS policies para tablas Phase 5 (notas crédito/débito + bridge)
-- Creada el: 27/05/2026
-- Secuencia: 052
--
-- Propósito: habilitar Row Level Security + políticas de aislamiento tenant
-- para las 5 tablas Phase 5 con datos de tenant. Patrón idéntico a migración 046
-- (Phase 4 RLS). Motivos lookup tables NO tienen RLS (catálogos globales SUNAT).
--
-- PREREQUISITO OBLIGATORIO: Middleware Go
-- El handler Go DEBE ejecutar antes de cada query:
--     SET LOCAL app.id_empresa = '<uuid-de-la-empresa>';
-- Sin esto: 0 filas visibles en TODAS las tablas RLS.
-- Ver: migración 040 (Phase 3 RLS) y 046 (Phase 4 RLS) para el patrón completo.
--
-- Estrategias de RLS por tabla:
--   - notas_credito:          directo   — id_empresa = current_setting(...)
--   - notas_debito:           directo   — id_empresa = current_setting(...)
--   - notas_credito_detalles: EXISTS    — via notas_credito.id_empresa
--   - notas_debito_detalles:  EXISTS    — via notas_debito.id_empresa
--   - ordenes_comprobantes:   OR EXISTS — via ordenes.id_empresa OR comprobantes.id_empresa
--
-- MOTIVOS tables: sin RLS (catálogos globales compartidos — mismo patrón que
--   tipos_comprobante y estados_comprobante en migración 046).

-- =============================================================================
-- NOTAS_CREDITO — id_empresa directo
-- =============================================================================
ALTER TABLE notas_credito ENABLE ROW LEVEL SECURITY;
ALTER TABLE notas_credito FORCE ROW LEVEL SECURITY;

CREATE POLICY notas_credito_tenant_isolation ON notas_credito
    USING (
        id_empresa = current_setting('app.id_empresa', true)::uuid
    )
    WITH CHECK (
        id_empresa = current_setting('app.id_empresa', true)::uuid
    );

-- =============================================================================
-- NOTAS_DEBITO — id_empresa directo
-- =============================================================================
ALTER TABLE notas_debito ENABLE ROW LEVEL SECURITY;
ALTER TABLE notas_debito FORCE ROW LEVEL SECURITY;

CREATE POLICY notas_debito_tenant_isolation ON notas_debito
    USING (
        id_empresa = current_setting('app.id_empresa', true)::uuid
    )
    WITH CHECK (
        id_empresa = current_setting('app.id_empresa', true)::uuid
    );

-- =============================================================================
-- NOTAS_CREDITO_DETALLES — EXISTS 1-hop via notas_credito
-- =============================================================================
-- Patrón idéntico a comprobante_detalles (migración 046).
ALTER TABLE notas_credito_detalles ENABLE ROW LEVEL SECURITY;
ALTER TABLE notas_credito_detalles FORCE ROW LEVEL SECURITY;

CREATE POLICY notas_credito_detalles_tenant_isolation ON notas_credito_detalles
    USING (
        EXISTS (
            SELECT 1 FROM notas_credito nc
            WHERE nc.id = notas_credito_detalles.id_nota
              AND nc.id_empresa = current_setting('app.id_empresa', true)::uuid
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM notas_credito nc
            WHERE nc.id = notas_credito_detalles.id_nota
              AND nc.id_empresa = current_setting('app.id_empresa', true)::uuid
        )
    );

-- =============================================================================
-- NOTAS_DEBITO_DETALLES — EXISTS 1-hop via notas_debito
-- =============================================================================
ALTER TABLE notas_debito_detalles ENABLE ROW LEVEL SECURITY;
ALTER TABLE notas_debito_detalles FORCE ROW LEVEL SECURITY;

CREATE POLICY notas_debito_detalles_tenant_isolation ON notas_debito_detalles
    USING (
        EXISTS (
            SELECT 1 FROM notas_debito nd
            WHERE nd.id = notas_debito_detalles.id_nota
              AND nd.id_empresa = current_setting('app.id_empresa', true)::uuid
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM notas_debito nd
            WHERE nd.id = notas_debito_detalles.id_nota
              AND nd.id_empresa = current_setting('app.id_empresa', true)::uuid
        )
    );

-- =============================================================================
-- ORDENES_COMPROBANTES — OR EXISTS (dual FK tenant check)
-- =============================================================================
-- Diseño: OR porque ambos lados siempre pertenecen al mismo tenant en la
-- práctica, pero OR es más resiliente a edge cases. Véase Decision 3 del design.
ALTER TABLE ordenes_comprobantes ENABLE ROW LEVEL SECURITY;
ALTER TABLE ordenes_comprobantes FORCE ROW LEVEL SECURITY;

CREATE POLICY ordenes_comprobantes_tenant_isolation ON ordenes_comprobantes
    USING (
        EXISTS (
            SELECT 1 FROM ordenes o
            WHERE o.id_orden = ordenes_comprobantes.id_orden
              AND o.id_empresa = current_setting('app.id_empresa', true)::uuid
        )
        OR
        EXISTS (
            SELECT 1 FROM comprobantes c
            WHERE c.id = ordenes_comprobantes.id_comprobante
              AND c.id_empresa = current_setting('app.id_empresa', true)::uuid
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM ordenes o
            WHERE o.id_orden = ordenes_comprobantes.id_orden
              AND o.id_empresa = current_setting('app.id_empresa', true)::uuid
        )
        OR
        EXISTS (
            SELECT 1 FROM comprobantes c
            WHERE c.id = ordenes_comprobantes.id_comprobante
              AND c.id_empresa = current_setting('app.id_empresa', true)::uuid
        )
    );

COMMIT;
