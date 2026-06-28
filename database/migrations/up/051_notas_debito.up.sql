BEGIN;

-- Migración: notas_debito + notas_debito_detalles (fact + snapshot tables)
-- Creada el: 27/05/2026
-- Secuencia: 051
--
-- Propósito: crear las tablas de notas de débito electrónicas (SUNAT tipo 08).
-- Dependencias: 047 (motivos_nota_debito), 043 (comprobantes).
--
-- Decisiones de diseño:
--   - Estructura idéntica a notas_credito (050) con tabla y prefijos _debito.
--   - FK id_motivo referencia motivos_nota_debito (no motivos_nota_credito).
--   - Trigger en fact table; NO trigger en snapshot detalles (mismo patrón que 050).
--   - RLS habilitado en migración 052.

-- =============================================================================
-- NOTAS_DEBITO — tabla de hechos
-- =============================================================================
CREATE TABLE IF NOT EXISTS notas_debito (
    id              UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    id_empresa      UUID          NOT NULL,
    id_comprobante  UUID          NOT NULL REFERENCES comprobantes(id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    id_motivo       INT           NOT NULL REFERENCES motivos_nota_debito(id) ON DELETE RESTRICT,
    numero_nota     VARCHAR(20)   NOT NULL,
    fecha_emision   DATE          NOT NULL DEFAULT CURRENT_DATE,
    estado          VARCHAR(20)   NOT NULL DEFAULT 'borrador',
    monto_total     DECIMAL(10,2) NOT NULL,
    observaciones   TEXT,
    creado_en       TIMESTAMPTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actualizado_en  TIMESTAMPTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uk_nota_debito_empresa_numero UNIQUE (id_empresa, numero_nota)
);

-- Trigger para actualizado_en (reutiliza función de migración 022)
DROP TRIGGER IF EXISTS trg_actualizado_en_notas_debito ON notas_debito;
CREATE TRIGGER trg_actualizado_en_notas_debito
    BEFORE UPDATE ON notas_debito
    FOR EACH ROW EXECUTE FUNCTION establecer_actualizado_en();

-- Índice compuesto para reportes y POS: empresa + fecha
CREATE INDEX IF NOT EXISTS idx_notas_debito_empresa_fecha
    ON notas_debito(id_empresa, fecha_emision DESC);

-- Índice inverso para lookups: ¿qué notas débito están asociadas a este comprobante?
CREATE INDEX IF NOT EXISTS idx_notas_debito_comprobante
    ON notas_debito(id_comprobante);

-- =============================================================================
-- NOTAS_DEBITO_DETALLES — snapshot inmutable
-- =============================================================================
-- No tiene trigger: snapshot inmutable. Mismo patrón que notas_credito_detalles.
CREATE TABLE IF NOT EXISTS notas_debito_detalles (
    id                         UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    id_nota                    UUID          NOT NULL REFERENCES notas_debito(id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    renglon                    INT           NOT NULL,
    nombre_producto_snapshot   TEXT,
    descripcion_snapshot       TEXT,
    cantidad                   DECIMAL(10,4) NOT NULL,
    precio_unitario            DECIMAL(10,2) NOT NULL,
    igv                        DECIMAL(10,2),
    subtotal                   DECIMAL(10,2) NOT NULL,
    creado_en                  TIMESTAMPTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actualizado_en             TIMESTAMPTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uk_nota_debito_detalle_renglon UNIQUE (id_nota, renglon)
);

-- Índice inverso para lookups por nota
CREATE INDEX IF NOT EXISTS idx_notas_debito_detalles_nota
    ON notas_debito_detalles(id_nota);

COMMIT;
