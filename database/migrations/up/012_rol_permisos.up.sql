BEGIN;

-- Migración:  rol_permisos
-- Creado:     2026-06-06 12:53:00
-- Versión:    012

CREATE TABLE IF NOT EXISTS rol_permisos (
    id_rol_permiso INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_rol INT NOT NULL REFERENCES roles(id_rol) ON DELETE CASCADE,
    id_permiso INT NOT NULL REFERENCES permisos(id_permiso) ON DELETE CASCADE,

    creado_en TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actualizado_en TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uk_rol_permiso UNIQUE(id_rol, id_permiso)
);

CREATE INDEX idx_rol_permisos_rol ON rol_permisos(id_rol);
CREATE INDEX idx_rol_permisos_permiso ON rol_permisos(id_permiso);

COMMIT;
