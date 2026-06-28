BEGIN;

-- Migration:  clientes
-- Created:    2026-06-27
-- Version:    068
--
-- Propósito: Crear la tabla clientes asociada a cada empresa (tenant) para el POS,
--            permitiendo registrar la base de datos de clientes y soportar
--            la facturación nominativa (Boletas/Facturas) requerida por SUNAT.

CREATE TABLE IF NOT EXISTS clientes (
    id_cliente              UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    id_empresa              UUID         NOT NULL REFERENCES empresas(id_empresa) ON DELETE CASCADE,
    id_tipo_documento_fiscal INT         NOT NULL REFERENCES tipos_documento_fiscal(id) ON DELETE RESTRICT,
    numero_documento        VARCHAR(30)  NOT NULL,
    nombre_o_razon_social   VARCHAR(200) NOT NULL,
    direccion               TEXT,
    telefono                VARCHAR(15),
    email                   VARCHAR(100),
    
    creado_en               TIMESTAMPTZ  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actualizado_en          TIMESTAMPTZ  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- El número de documento debe ser único por tipo dentro de cada empresa
    CONSTRAINT uk_clientes_empresa_documento UNIQUE (id_empresa, id_tipo_documento_fiscal, numero_documento)
);

-- 1. Trigger para actualizado_en
DROP TRIGGER IF EXISTS trg_actualizado_en_clientes ON clientes;
CREATE TRIGGER trg_actualizado_en_clientes
    BEFORE UPDATE ON clientes
    FOR EACH ROW EXECUTE FUNCTION establecer_actualizado_en();

-- 2. Habilitar Row Level Security (RLS)
ALTER TABLE clientes ENABLE ROW LEVEL SECURITY;

CREATE POLICY clientes_tenant_isolation ON clientes
    USING (
        id_empresa = current_setting('app.id_empresa', true)::uuid
    )
    WITH CHECK (
        id_empresa = current_setting('app.id_empresa', true)::uuid
    );

-- 3. Índices de rendimiento para búsquedas en el POS
CREATE INDEX IF NOT EXISTS idx_clientes_busqueda_pos
    ON clientes(id_empresa, numero_documento, telefono, email);

COMMIT;
