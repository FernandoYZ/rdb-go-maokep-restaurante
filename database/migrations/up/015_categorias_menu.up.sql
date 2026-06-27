BEGIN;

-- Migración: categorias_menu
-- Creada el: 26/05/2026 00:31:53
-- Secuencia: 016

CREATE TABLE IF NOT EXISTS categorias_menu (
    id_categoria UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_empresa UUID NOT NULL REFERENCES empresas(id_empresa) ON DELETE CASCADE,

    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT,
    orden INT DEFAULT 0,

    activa BOOLEAN NOT NULL DEFAULT TRUE,
    eliminado_en TIMESTAMPTZ NULL,

    creado_en TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actualizado_en TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_categorias_fecha_eliminacion CHECK (eliminado_en IS NULL OR eliminado_en >= creado_en)
);

CREATE UNIQUE INDEX uk_categoria_empresa ON categorias_menu (nombre, id_empresa) WHERE eliminado_en IS NULL;

CREATE INDEX idx_categorias_empresa ON categorias_menu(id_empresa);
CREATE INDEX idx_categorias_activas ON categorias_menu(id_empresa, activa);
CREATE INDEX idx_categorias_activas_sd ON categorias_menu(id_empresa) WHERE eliminado_en IS NULL;

COMMIT;
