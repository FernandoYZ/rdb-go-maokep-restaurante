BEGIN;

-- Migration:  totales_denormalizados_comprobantes
-- Created:    2026-06-27
-- Version:    066
--
-- Propósito: Agregar totales denormalizados y soporte multimoneda a la tabla comprobantes.
--            Esto mejora drásticamente el rendimiento de reportes financieros y 
--            evita realizar agregaciones pesadas en la tabla comprobante_detalles.

ALTER TABLE comprobantes
    ADD COLUMN total_gravado      NUMERIC(12,2) NOT NULL DEFAULT 0,
    ADD COLUMN total_exonerado    NUMERIC(12,2) NOT NULL DEFAULT 0,
    ADD COLUMN total_inafecto     NUMERIC(12,2) NOT NULL DEFAULT 0,
    ADD COLUMN total_igv          NUMERIC(12,2) NOT NULL DEFAULT 0,
    ADD COLUMN monto_total        NUMERIC(12,2) NOT NULL DEFAULT 0,
    ADD COLUMN codigo_moneda      VARCHAR(3)    NOT NULL DEFAULT 'PEN';

-- 1. Constraints monetarios de seguridad (montos no negativos)
ALTER TABLE comprobantes
    ADD CONSTRAINT chk_comprobantes_total_gravado_positive CHECK (total_gravado >= 0),
    ADD CONSTRAINT chk_comprobantes_total_exonerado_positive CHECK (total_exonerado >= 0),
    ADD CONSTRAINT chk_comprobantes_total_inafecto_positive CHECK (total_inafecto >= 0),
    ADD CONSTRAINT chk_comprobantes_total_igv_positive CHECK (total_igv >= 0),
    ADD CONSTRAINT chk_comprobantes_monto_total_positive CHECK (monto_total >= 0);

-- 2. Backfill: calcular totales históricos a partir de sus detalles
UPDATE comprobantes c
SET total_gravado = COALESCE((
        SELECT SUM(subtotal)
        FROM comprobante_detalles cd
        WHERE cd.id_comprobante = c.id AND cd.id_tipo_afectacion_igv = 10
    ), 0),
    total_exonerado = COALESCE((
        SELECT SUM(subtotal)
        FROM comprobante_detalles cd
        WHERE cd.id_comprobante = c.id AND cd.id_tipo_afectacion_igv = 20
    ), 0),
    total_inafecto = COALESCE((
        SELECT SUM(subtotal)
        FROM comprobante_detalles cd
        WHERE cd.id_comprobante = c.id AND cd.id_tipo_afectacion_igv = 30
    ), 0),
    total_igv = COALESCE((
        SELECT SUM(igv)
        FROM comprobante_detalles cd
        WHERE cd.id_comprobante = c.id
    ), 0),
    monto_total = COALESCE((
        SELECT SUM(subtotal + igv)
        FROM comprobante_detalles cd
        WHERE cd.id_comprobante = c.id
    ), 0);

-- 3. Índice para reportes financieros agrupados por moneda y fecha
CREATE INDEX IF NOT EXISTS idx_comprobantes_reportes_totales
    ON comprobantes(id_empresa, fecha_emision, codigo_moneda, monto_total);

COMMIT;
