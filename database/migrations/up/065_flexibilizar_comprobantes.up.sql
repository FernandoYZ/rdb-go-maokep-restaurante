BEGIN;

-- Migration:  flexibilizar_comprobantes
-- Created:    2026-06-27
-- Version:    065
--
-- Propósito: Desacoplar la identidad fiscal del emisor (empresa) en comprobantes
--            permitiendo otros documentos (DNI, Pasaporte, etc.) en lugar de RUC estricto.

-- 1. Agregar las nuevas columnas flexibles
ALTER TABLE comprobantes
    ADD COLUMN id_tipo_documento_fiscal_empresa INT NULL REFERENCES tipos_documento_fiscal(id) ON DELETE RESTRICT,
    ADD COLUMN numero_documento_empresa VARCHAR(30) NULL;

-- 2. Backfill: migrar datos de ruc_empresa anteriores a la nueva estructura
UPDATE comprobantes
SET id_tipo_documento_fiscal_empresa = (SELECT id FROM tipos_documento_fiscal WHERE codigo = 'RUC' LIMIT 1),
    numero_documento_empresa = ruc_empresa
WHERE ruc_empresa IS NOT NULL;

-- 3. Establecer restricciones NOT NULL tras el backfill
ALTER TABLE comprobantes
    ALTER COLUMN id_tipo_documento_fiscal_empresa SET NOT NULL,
    ALTER COLUMN numero_documento_empresa SET NOT NULL;

-- 4. Eliminar la columna ruc_empresa obsoleta
ALTER TABLE comprobantes
    DROP COLUMN IF EXISTS ruc_empresa;

-- 5. Crear índice para búsquedas por documento fiscal del emisor
CREATE INDEX idx_comprobantes_doc_empresa 
    ON comprobantes(id_tipo_documento_fiscal_empresa, numero_documento_empresa);

COMMIT;
