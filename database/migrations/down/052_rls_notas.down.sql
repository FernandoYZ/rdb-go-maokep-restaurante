BEGIN;

-- Rollback: 052_rls_notas
-- Elimina todas las políticas RLS y deshabilita Row Level Security
-- en las 5 tablas Phase 5.

-- ordenes_comprobantes
DROP POLICY IF EXISTS ordenes_comprobantes_tenant_isolation ON ordenes_comprobantes;
ALTER TABLE ordenes_comprobantes DISABLE ROW LEVEL SECURITY;

-- notas_debito_detalles
DROP POLICY IF EXISTS notas_debito_detalles_tenant_isolation ON notas_debito_detalles;
ALTER TABLE notas_debito_detalles DISABLE ROW LEVEL SECURITY;

-- notas_credito_detalles
DROP POLICY IF EXISTS notas_credito_detalles_tenant_isolation ON notas_credito_detalles;
ALTER TABLE notas_credito_detalles DISABLE ROW LEVEL SECURITY;

-- notas_debito
DROP POLICY IF EXISTS notas_debito_tenant_isolation ON notas_debito;
ALTER TABLE notas_debito DISABLE ROW LEVEL SECURITY;

-- notas_credito
DROP POLICY IF EXISTS notas_credito_tenant_isolation ON notas_credito;
ALTER TABLE notas_credito DISABLE ROW LEVEL SECURITY;

COMMIT;
