BEGIN;

-- Migración: items_orden
-- Creada el: 26/05/2026 00:31:53
-- Secuencia: 020

CREATE TABLE IF NOT EXISTS items_orden (
    id_item_orden UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_orden UUID NOT NULL REFERENCES ordenes(id_orden) ON DELETE CASCADE,
    id_producto UUID NOT NULL REFERENCES productos(id_producto) ON DELETE RESTRICT,

    cantidad INT NOT NULL,
    precio_unitario DECIMAL(10, 2) NOT NULL,
    subtotal DECIMAL(10, 2) NOT NULL,

    id_tipo_afectacion_igv INT NOT NULL DEFAULT 10 REFERENCES tipos_afectacion_igv(id) ON DELETE RESTRICT,

    nombre_producto_snapshot TEXT NULL,
    precio_unitario_snapshot DECIMAL(10, 2) NULL,

    instrucciones TEXT,

    creado_en TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actualizado_en TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Documentar los campos de snapshot
COMMENT ON COLUMN items_orden.nombre_producto_snapshot
  IS 'Snapshot del nombre del producto al momento de crear el item — inmutable después del cierre de orden';

COMMENT ON COLUMN items_orden.precio_unitario_snapshot
  IS 'Snapshot del precio unitario al momento de crear el item — inmutable después del cierre de orden';

CREATE INDEX IF NOT EXISTS idx_items_orden ON items_orden(id_orden);
CREATE INDEX IF NOT EXISTS idx_items_producto ON items_orden(id_producto);

COMMIT;
