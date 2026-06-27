BEGIN;

-- Migración: productos
-- Creada el: 26/05/2026 00:31:53
-- Secuencia: 017

CREATE TABLE IF NOT EXISTS productos (
    id_producto UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_empresa UUID NOT NULL REFERENCES empresas(id_empresa) ON DELETE CASCADE,
    id_categoria UUID NOT NULL REFERENCES categorias_menu(id_categoria) ON DELETE RESTRICT,

    nombre VARCHAR(150) NOT NULL,
    descripcion TEXT,
    imagen_url TEXT,

    precio_venta DECIMAL(10, 2) NOT NULL,
    precio_costo DECIMAL(10, 2),

    id_tipo_afectacion_igv INT NOT NULL DEFAULT 10 REFERENCES tipos_afectacion_igv(id) ON DELETE RESTRICT,

    disponible BOOLEAN NOT NULL DEFAULT TRUE,
    orden INT DEFAULT 0,
    eliminado_en TIMESTAMPTZ NULL,

    creado_en TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actualizado_en TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_productos_fecha_eliminacion CHECK (eliminado_en IS NULL OR eliminado_en >= creado_en)
);

CREATE UNIQUE INDEX uk_producto_empresa ON productos (nombre, id_empresa) WHERE eliminado_en IS NULL;

CREATE INDEX idx_productos_empresa ON productos(id_empresa);
CREATE INDEX idx_productos_categoria ON productos(id_categoria);
CREATE INDEX idx_productos_disponibles ON productos(id_empresa, disponible);
CREATE INDEX idx_productos_activos ON productos(id_empresa) WHERE eliminado_en IS NULL;

COMMIT;
