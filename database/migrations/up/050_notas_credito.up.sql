BEGIN;

-- Migración: notas_credito + notas_credito_detalles (fact + snapshot tables)
-- Creada el: 27/05/2026
-- Secuencia: 050
--
-- Propósito: crear las tablas de notas de crédito electrónicas (SUNAT tipo 07).
-- Dependencias: 047 (motivos_nota_credito), 043 (comprobantes).
--
-- Decisiones de diseño:
--   - UUID PKs para fact/snapshot tables (igual que comprobantes, 043).
--   - DECIMAL(10,2) para monetarios (igual que Phase 4 comprobante_detalles).
--   - DECIMAL(10,4) para cantidad (permite fracciones: 0.5 kg, 0.25 unidades).
--   - FK RESTRICT en todos los lados (no cascades en tablas financieras).
--   - Trigger establecer_actualizado_en() sólo en la tabla de hechos (notas_credito).
--   - notas_credito_detalles es snapshot inmutable — NO tiene trigger (mismo patrón
--     que envios_sunat de migración 045).
--   - RLS habilitado en migración 052 (patrón Phase 4: RLS centralizado al final).
--   - fecha_emision: DATE (igual que comprobantes.fecha_emision — SUNAT fecha fiscal).

-- =============================================================================
-- NOTAS_CREDITO — tabla de hechos
-- =============================================================================
CREATE TABLE IF NOT EXISTS notas_credito (
    id              UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    id_empresa      UUID          NOT NULL,
    id_comprobante  UUID          NOT NULL REFERENCES comprobantes(id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    id_motivo       INT           NOT NULL REFERENCES motivos_nota_credito(id) ON DELETE RESTRICT,
    numero_nota     VARCHAR(20)   NOT NULL,
    fecha_emision   DATE          NOT NULL DEFAULT CURRENT_DATE,
    estado          VARCHAR(20)   NOT NULL DEFAULT 'borrador',
    monto_total     DECIMAL(10,2) NOT NULL,
    observaciones   TEXT,
    creado_en       TIMESTAMPTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actualizado_en  TIMESTAMPTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uk_nota_credito_empresa_numero UNIQUE (id_empresa, numero_nota)
);

-- Trigger para actualizado_en (reutiliza función de migración 022)
DROP TRIGGER IF EXISTS trg_actualizado_en_notas_credito ON notas_credito;
CREATE TRIGGER trg_actualizado_en_notas_credito
    BEFORE UPDATE ON notas_credito
    FOR EACH ROW EXECUTE FUNCTION establecer_actualizado_en();

-- Índice compuesto para reportes y POS: empresa + fecha
CREATE INDEX IF NOT EXISTS idx_notas_credito_empresa_fecha
    ON notas_credito(id_empresa, fecha_emision DESC);

-- Índice inverso para lookups: ¿qué notas están asociadas a este comprobante?
CREATE INDEX IF NOT EXISTS idx_notas_credito_comprobante
    ON notas_credito(id_comprobante);

-- =============================================================================
-- NOTAS_CREDITO_DETALLES — snapshot inmutable
-- =============================================================================
-- No tiene trigger: las filas son inmutables después del INSERT (snapshot al
-- momento de emisión). Patrón idéntico a envios_sunat (migración 045).
CREATE TABLE IF NOT EXISTS notas_credito_detalles (
    id                         UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    id_nota                    UUID          NOT NULL REFERENCES notas_credito(id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    renglon                    INT           NOT NULL,
    nombre_producto_snapshot   TEXT,
    descripcion_snapshot       TEXT,
    cantidad                   DECIMAL(10,4) NOT NULL,
    precio_unitario            DECIMAL(10,2) NOT NULL,
    igv                        DECIMAL(10,2),
    subtotal                   DECIMAL(10,2) NOT NULL,
    creado_en                  TIMESTAMPTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actualizado_en             TIMESTAMPTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uk_nota_credito_detalle_renglon UNIQUE (id_nota, renglon)
);

-- Índice inverso para lookups por nota
CREATE INDEX IF NOT EXISTS idx_notas_credito_detalles_nota
    ON notas_credito_detalles(id_nota);

COMMIT;
