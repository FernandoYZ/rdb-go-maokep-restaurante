BEGIN;

-- Migración: comprobante_detalles (snapshot inmutable de líneas del comprobante)
-- Creada el: 27/05/2026
-- Secuencia: 044
--
-- Propósito: almacenar el detalle fiscal de cada comprobante como snapshot inmutable.
-- Decisiones de diseño:
--   - SIN FK a items_orden ni a productos: el detalle es una copia fiscal al momento
--     de emisión. Los items_orden pueden ser modificados post-emisión; el comprobante
--     guarda el valor vigente al momento de firmarlo ante SUNAT. Requisito legal.
--   - FK RESTRICT a comprobantes: no se puede borrar un comprobante que tiene detalles.
--   - actualizado_en: se incluye para consistencia con otras tablas operacionales,
--     aunque los detalles no deberían modificarse tras la emisión.
--   - nombre_producto_snapshot, descripcion_snapshot, precio_costo_snapshot:
--     campos de snapshot para auditoría y reconstitución del XML firmado.

CREATE TABLE IF NOT EXISTS comprobante_detalles (
    id                      UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    id_comprobante          UUID          NOT NULL REFERENCES comprobantes(id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    renglon                 INT           NOT NULL,
    id_producto             UUID          NOT NULL,
    cantidad                INT           NOT NULL,
    precio_unitario         DECIMAL(10,2) NOT NULL,
    subtotal                DECIMAL(10,2) NOT NULL,
    igv                     DECIMAL(10,2) NOT NULL,
    id_tipo_afectacion_igv  INT           NOT NULL DEFAULT 10 REFERENCES tipos_afectacion_igv(id) ON DELETE RESTRICT,
    nombre_producto_snapshot       TEXT,
    descripcion_snapshot           TEXT,
    precio_costo_snapshot   DECIMAL(10,2),
    creado_en               TIMESTAMPTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actualizado_en          TIMESTAMPTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uk_detalle_comprobante_renglon UNIQUE (id_comprobante, renglon)
);

-- Trigger para actualizado_en (reutiliza función de migración 022)
DROP TRIGGER IF EXISTS trg_actualizado_en_comprobante_detalles ON comprobante_detalles;
CREATE TRIGGER trg_actualizado_en_comprobante_detalles
    BEFORE UPDATE ON comprobante_detalles
    FOR EACH ROW EXECUTE FUNCTION establecer_actualizado_en();

-- Índice para queries de detalles por comprobante
CREATE INDEX IF NOT EXISTS idx_detalles_comprobante
    ON comprobante_detalles(id_comprobante);

COMMIT;
