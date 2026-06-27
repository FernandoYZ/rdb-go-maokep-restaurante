BEGIN;

-- Rollback:   flexibilizar_comprobantes
-- Created:    2026-06-27
-- Version:    065

-- 1. Agregar de nuevo la columna ruc_empresa
ALTER TABLE comprobantes
    ADD COLUMN ruc_empresa VARCHAR(11) NULL;

-- 2. Restaurar datos cortando a 11 caracteres (el RUC es de 11)
UPDATE comprobantes
SET ruc_empresa = LEFT(numero_documento_empresa, 11)
WHERE numero_documento_empresa IS NOT NULL;

-- 3. Restablecer restricción NOT NULL
ALTER TABLE comprobantes
    ALTER COLUMN ruc_empresa SET NOT NULL;

-- 4. Eliminar nuevas columnas e índice
DROP INDEX IF EXISTS idx_comprobantes_doc_empresa;

ALTER TABLE comprobantes
    DROP COLUMN IF EXISTS id_tipo_documento_fiscal_empresa,
    DROP COLUMN IF EXISTS numero_documento_empresa;

COMMIT;
