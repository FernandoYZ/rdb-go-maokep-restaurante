BEGIN;

-- Migración: comprobantes (tabla de hechos de facturación electrónica SUNAT)
-- Creada el: 27/05/2026
-- Secuencia: 043
--
-- Propósito: tabla central del módulo de comprobantes electrónicos.
-- Decisiones de diseño:
--   - id_empresa: columna directa (sin FK a empresas) para soportar RLS eficiente
--     con current_setting('app.id_empresa'). Si se usara FK, la migración 046 RLS
--     quedaría idéntica; se omite FK para no duplicar constraint de la FK de id_orden.
--   - id_orden: FK RESTRICT a ordenes — requisito de inmutabilidad financiera.
--   - ruc_empresa, razon_social_empresa, serie, numero: snapshot al momento de emisión.
--     Los datos de empresa pueden cambiar; el comprobante guarda el valor fiscal vigente.
--   - xml_firmado, cdr: TEXT sin límite — los documentos XML firmados superan 50 KB.
--   - UNIQUE (id_empresa, serie, numero): garantiza unicidad de numeración por tenant.
--   - actualizado_en: trigger reutiliza establecer_actualizado_en() de migración 022.

CREATE TABLE comprobantes (
    id                   UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    id_empresa           UUID         NOT NULL,
    id_orden             UUID         NULL REFERENCES ordenes(id_orden) ON DELETE RESTRICT ON UPDATE RESTRICT,
    id_tipo_comprobante  INT          NOT NULL REFERENCES tipos_comprobante(id) ON DELETE RESTRICT,
    id_estado            INT          NOT NULL REFERENCES estados_comprobante(id) ON DELETE RESTRICT,
    serie                VARCHAR(4)   NOT NULL,
    numero               BIGINT       NOT NULL,
    ruc_empresa          VARCHAR(11)  NOT NULL,
    razon_social_empresa VARCHAR(200) NOT NULL,
    xml_firmado          TEXT,
    cdr                  TEXT,
    fecha_emision        DATE         NOT NULL DEFAULT CURRENT_DATE,
    creado_en            TIMESTAMPTZ  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actualizado_en       TIMESTAMPTZ  NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uk_comprobante_empresa_serie_numero UNIQUE (id_empresa, serie, numero)
);

-- Trigger para actualizado_en (reutiliza función de migración 022)
CREATE TRIGGER trg_actualizado_en_comprobantes
    BEFORE UPDATE ON comprobantes
    FOR EACH ROW EXECUTE FUNCTION establecer_actualizado_en();

-- Índice para queries de listado por empresa + estado + fecha (reportes y POS)
CREATE INDEX idx_comprobantes_empresa_estado_fecha
    ON comprobantes(id_empresa, id_estado, fecha_emision DESC);

-- Índice para lookups por orden (verificar si orden ya tiene comprobante)
CREATE INDEX idx_comprobantes_orden
    ON comprobantes(id_orden);

COMMIT;
