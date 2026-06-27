BEGIN;

-- Eliminar índices compuestos de Slice B
DROP INDEX IF EXISTS idx_series_empresa_tipo_creado;

-- Eliminar políticas RLS
DROP POLICY IF EXISTS envios_sunat_tenant_isolation ON envios_sunat;
DROP POLICY IF EXISTS comprobante_detalles_tenant_isolation ON comprobante_detalles;
DROP POLICY IF EXISTS comprobantes_tenant_isolation ON comprobantes;
DROP POLICY IF EXISTS series_comprobante_tenant_isolation ON series_comprobante;

-- Deshabilitar RLS en todas las tablas del módulo comprobantes
ALTER TABLE envios_sunat DISABLE ROW LEVEL SECURITY;
ALTER TABLE comprobante_detalles DISABLE ROW LEVEL SECURITY;
ALTER TABLE comprobantes DISABLE ROW LEVEL SECURITY;
ALTER TABLE series_comprobante DISABLE ROW LEVEL SECURITY;

COMMIT;
