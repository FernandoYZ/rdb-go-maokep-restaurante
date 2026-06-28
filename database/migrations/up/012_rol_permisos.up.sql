BEGIN;

-- Migración: rol_permisos
-- Creada el: 26/05/2026 00:31:53
-- Secuencia: 013

CREATE TABLE IF NOT EXISTS rol_permisos (
    id_rol_permiso INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_rol INT NOT NULL REFERENCES roles(id_rol) ON DELETE CASCADE,
    id_permiso INT NOT NULL REFERENCES permisos(id_permiso) ON DELETE CASCADE,

    creado_en TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actualizado_en TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uk_rol_permiso UNIQUE(id_rol, id_permiso)
);

CREATE INDEX IF NOT EXISTS idx_rol_permisos_rol ON rol_permisos(id_rol);
CREATE INDEX IF NOT EXISTS idx_rol_permisos_permiso ON rol_permisos(id_permiso);

COMMIT;
