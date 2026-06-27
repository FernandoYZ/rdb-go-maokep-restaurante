BEGIN;

-- Migración: sucursales y usuario_sucursales multi-sede
-- Creada el: 26/05/2026
-- Secuencia: 031
--
-- Propósito: permitir que una empresa tenga múltiples sedes (sucursales) y
-- asignar usuarios a una o más sucursales mediante una tabla pivot.

CREATE TABLE sucursales (
    id_sucursal  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_empresa   UUID NOT NULL REFERENCES empresas(id_empresa) ON DELETE CASCADE,

    nombre       VARCHAR(150) NOT NULL,
    codigo       VARCHAR(30),
    direccion    TEXT,
    telefono     VARCHAR(15),

    latitud      DECIMAL(10, 8),
    longitud     DECIMAL(11, 8),

    activa       BOOLEAN NOT NULL DEFAULT TRUE,
    eliminado_en TIMESTAMPTZ NULL,
    deleted_by   UUID NULL REFERENCES usuarios(id_usuario) ON DELETE SET NULL,

    creado_en      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actualizado_en TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Código único por empresa (puede ser NULL para sucursales sin código asignado)
    CONSTRAINT chk_sucursales_fecha_eliminacion CHECK (eliminado_en IS NULL OR eliminado_en >= creado_en)
);

-- Código único por empresa (solo para sucursales activas y que tengan código asignado)
CREATE UNIQUE INDEX uk_sucursal_empresa_codigo ON sucursales (id_empresa, codigo) WHERE eliminado_en IS NULL AND codigo IS NOT NULL;

-- Índice parcial para consultas de sucursales activas por empresa
CREATE INDEX idx_sucursales_empresa ON sucursales (id_empresa) WHERE eliminado_en IS NULL;

-- Tabla pivot: asignación de usuarios a sucursales
CREATE TABLE usuario_sucursales (
    id_usuario   UUID NOT NULL REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
    id_sucursal  UUID NOT NULL REFERENCES sucursales(id_sucursal) ON DELETE CASCADE,

    creado_en    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id_usuario, id_sucursal)
);

-- Triggers para auto-actualizar actualizado_en
CREATE TRIGGER trg_actualizado_en_sucursales
  BEFORE UPDATE ON sucursales
  FOR EACH ROW EXECUTE FUNCTION establecer_actualizado_en();

COMMIT;
