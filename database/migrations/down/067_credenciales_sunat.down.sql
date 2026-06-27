BEGIN;

-- Rollback:   credenciales_sunat
-- Created:    2026-06-27
-- Version:    067

-- 1. Eliminar políticas de RLS
DROP POLICY IF EXISTS credenciales_sunat_tenant_isolation ON credenciales_sunat;

-- 2. Eliminar trigger
DROP TRIGGER IF EXISTS trg_actualizado_en_credenciales_sunat ON credenciales_sunat;

-- 3. Eliminar tabla
DROP TABLE IF EXISTS credenciales_sunat;

COMMIT;
