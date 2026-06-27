BEGIN;

-- 1. Crear tabla de catálogo para tipos de documentos fiscales
CREATE TABLE IF NOT EXISTS tipos_documento_fiscal (
    id SERIAL PRIMARY KEY,
    codigo VARCHAR(10) NOT NULL UNIQUE,
    descripcion VARCHAR(100) NOT NULL
);

INSERT INTO tipos_documento_fiscal (codigo, descripcion) VALUES
    ('RUC', 'Registro Único de Contribuyentes (Perú)'),
    ('DNI', 'Documento Nacional de Identidad (Perú)'),
    ('NIT', 'Número de Identificación Tributaria'),
    ('RUT', 'Rol Único Tributario'),
    ('PASAPORTE', 'Pasaporte o Carnet de Extranjería'),
    ('SIN_DOC', 'Sin Documento / Informal')
ON CONFLICT (codigo) DO NOTHING;

-- 2. Modificar la tabla "empresas" para soportar identificación fiscal flexible
ALTER TABLE empresas ADD COLUMN id_tipo_documento_fiscal INT REFERENCES tipos_documento_fiscal(id);
ALTER TABLE empresas ADD COLUMN numero_documento_fiscal VARCHAR(30);

-- Migrar datos de RUCs existentes
UPDATE empresas 
SET id_tipo_documento_fiscal = (SELECT id FROM tipos_documento_fiscal WHERE codigo = 'RUC'),
    numero_documento_fiscal = ruc
WHERE ruc IS NOT NULL;

-- Eliminar columna y restricción UNIQUE de RUC anterior
ALTER TABLE empresas DROP CONSTRAINT IF EXISTS empresas_ruc_key;
ALTER TABLE empresas DROP COLUMN IF EXISTS ruc;

-- Agregar índice único parcial: el número de documento debe ser único por tipo, si existe
CREATE UNIQUE INDEX uk_empresas_fiscal_id 
ON empresas (id_tipo_documento_fiscal, numero_documento_fiscal) 
WHERE numero_documento_fiscal IS NOT NULL;

-- 3. Insertar 'Nota de Venta' en tipos_comprobante
INSERT INTO tipos_comprobante (code, nombre) VALUES
    ('99', 'Nota de Venta / Ticket Interno')
ON CONFLICT (code) DO NOTHING;

-- 4. Habilitar bandera de facturación electrónica a nivel configuración de empresa
ALTER TABLE configuracion_empresa ADD COLUMN facturacion_electronica_habilitada BOOLEAN NOT NULL DEFAULT FALSE;

COMMIT;
