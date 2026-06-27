BEGIN;

DROP POLICY IF EXISTS ordenes_tenant_isolation ON ordenes;
ALTER TABLE ordenes DISABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS pagos_orden_tenant_isolation ON pagos_orden;
ALTER TABLE pagos_orden DISABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS items_orden_tenant_isolation ON items_orden;
ALTER TABLE items_orden DISABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS aperturas_caja_tenant_isolation ON aperturas_caja;
ALTER TABLE aperturas_caja DISABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS movimientos_caja_tenant_isolation ON movimientos_caja;
ALTER TABLE movimientos_caja DISABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS usuarios_operativos_tenant_isolation ON usuarios;
ALTER TABLE usuarios DISABLE ROW LEVEL SECURITY;

DROP TABLE IF EXISTS rls_context;

COMMIT;
