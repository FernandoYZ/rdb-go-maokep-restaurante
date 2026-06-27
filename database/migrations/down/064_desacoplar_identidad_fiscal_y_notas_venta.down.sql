BEGIN;

-- 1. Quitar bandera de facturación electrónica en configuración de empresa
ALTER TABLE configuracion_empresa DROP COLUMN IF EXISTS facturacion_electronica_habilitada;

-- 2. Eliminar 'Nota de Venta' de tipos_comprobante
DELETE FROM tipos_comprobante WHERE code = '99';

-- 3. Restaurar columna ruc en empresas
ALTER TABLE empresas ADD COLUMN ruc VARCHAR(11);

-- Re-migrar los datos que eran de tipo RUC
UPDATE empresas
SET ruc = numero_documento_fiscal
WHERE id_tipo_documento_fiscal = (SELECT id FROM tipos_documento_fiscal WHERE codigo = 'RUC');

-- Volver a agregar el constraint UNIQUE
ALTER TABLE empresas ADD CONSTRAINT empresas_ruc_key UNIQUE (ruc);

-- Eliminar índice parcial y columnas agregadas en empresas
DROP INDEX IF EXISTS uk_empresas_fiscal_id;
ALTER TABLE empresas DROP COLUMN IF EXISTS numero_documento_fiscal;
ALTER TABLE empresas DROP COLUMN IF EXISTS id_tipo_documento_fiscal;

-- 4. Eliminar la tabla de catálogo de tipos de documento fiscal
DROP TABLE IF EXISTS tipos_documento_fiscal;

COMMIT;
