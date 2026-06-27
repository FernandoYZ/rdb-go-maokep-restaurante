BEGIN;

-- Rollback:   clientes
-- Created:    2026-06-27
-- Version:    068

-- 1. Eliminar índice
DROP INDEX IF EXISTS idx_clientes_busqueda_pos;

-- 2. Eliminar política RLS
DROP POLICY IF EXISTS clientes_tenant_isolation ON clientes;

-- 3. Eliminar trigger
DROP TRIGGER IF EXISTS trg_actualizado_en_clientes ON clientes;

-- 4. Eliminar tabla
DROP TABLE IF EXISTS clientes;

COMMIT;
