BEGIN;

-- Migración: series_comprobante
-- Creada el: 27/05/2026
-- Secuencia: 042
--
-- Propósito: gestión de series de comprobantes electrónicos por empresa y tipo.
-- Patrón: UUID PK (tabla operacional — igual que aperturas_caja, ordenes).
-- El UNIQUE (id_empresa, id_tipo_comprobante, serie) garantiza unicidad a nivel DB.
-- El incremento de ultimo_correlativo usa SELECT FOR UPDATE en la aplicación.

CREATE TABLE IF NOT EXISTS series_comprobante (
    id                  UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    id_empresa          UUID         NOT NULL REFERENCES empresas(id_empresa) ON DELETE RESTRICT,
    id_tipo_comprobante INT          NOT NULL REFERENCES tipos_comprobante(id) ON DELETE RESTRICT,
    serie               VARCHAR(4)   NOT NULL,
    ultimo_correlativo  BIGINT       NOT NULL DEFAULT 0,
    activo              BOOLEAN      NOT NULL DEFAULT TRUE,
    creado_en           TIMESTAMPTZ  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actualizado_en      TIMESTAMPTZ  NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uk_series_empresa_tipo_serie UNIQUE (id_empresa, id_tipo_comprobante, serie)
);

-- Trigger para actualizado_en (reutiliza función de migración 022)
DROP TRIGGER IF EXISTS trg_actualizado_en_series_comprobante ON series_comprobante;
CREATE TRIGGER trg_actualizado_en_series_comprobante
    BEFORE UPDATE ON series_comprobante
    FOR EACH ROW EXECUTE FUNCTION establecer_actualizado_en();

-- Índices para consultas frecuentes por empresa y por tipo
CREATE INDEX IF NOT EXISTS idx_series_comprobante_empresa
    ON series_comprobante(id_empresa);

CREATE INDEX IF NOT EXISTS idx_series_comprobante_tipo
    ON series_comprobante(id_tipo_comprobante);

COMMIT;
