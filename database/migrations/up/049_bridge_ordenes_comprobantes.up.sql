BEGIN;

-- Migración: tabla puente ordenes_comprobantes (N:M ordenes ↔ comprobantes)
-- Creada el: 27/05/2026
-- Secuencia: 049
--
-- Propósito: habilitar cardinalidad flexible entre ordenes y comprobantes.
-- Antes de esta migración el vínculo era 1:1 directo via comprobantes.id_orden.
-- Esta tabla puente permite:
--   - 1:1 clásico: comprobante con id_orden NOT NULL + sin filas en puente
--   - N:1 (varias ordenes → un comprobante): múltiples filas en puente, id_orden NULL en comprobante
--   - 1:N (una orden → varios comprobantes): varias filas en puente con mismo id_orden
--
-- Depende de migración 048 (id_orden nullable en comprobantes).
-- ON DELETE RESTRICT en ambas FKs: no se puede eliminar una orden o comprobante
-- que tenga filas activas en el puente. Comportamiento correcto para datos fiscales.

CREATE TABLE IF NOT EXISTS ordenes_comprobantes (
    id_orden        UUID NOT NULL REFERENCES ordenes(id_orden)   ON DELETE RESTRICT ON UPDATE RESTRICT,
    id_comprobante  UUID NOT NULL REFERENCES comprobantes(id)    ON DELETE RESTRICT ON UPDATE RESTRICT,
    PRIMARY KEY (id_orden, id_comprobante)
);

-- Índices de búsqueda inversa para ambas direcciones del vínculo N:M
CREATE INDEX idx_ordenes_comprobantes_orden
    ON ordenes_comprobantes(id_orden);

CREATE INDEX idx_ordenes_comprobantes_comprobante
    ON ordenes_comprobantes(id_comprobante);

COMMIT;
