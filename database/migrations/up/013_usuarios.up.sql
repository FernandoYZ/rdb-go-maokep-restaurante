BEGIN;

-- Migración:  usuarios
-- Creado:     2026-06-06 12:53:31
-- Versión:    013

CREATE TABLE IF NOT EXISTS usuarios (
    id_usuario UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_empresa UUID NOT NULL REFERENCES empresas(id_empresa) ON DELETE CASCADE,
    id_rol INT NOT NULL REFERENCES roles(id_rol),

    email VARCHAR(100) NOT NULL,
    usuario VARCHAR(50) NOT NULL,
    contrasena_hash VARCHAR(255) NOT NULL,
    nombre VARCHAR(150) NOT NULL,
    apellido VARCHAR(150),

    activo BOOLEAN NOT NULL DEFAULT TRUE,
    ultimo_acceso TIMESTAMPTZ,
    eliminado_en TIMESTAMPTZ NULL,

    creado_en TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actualizado_en TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uk_usuarios_email_empresa UNIQUE(email, id_empresa),
    CONSTRAINT chk_usuarios_fecha_eliminacion CHECK (eliminado_en IS NULL OR eliminado_en >= creado_en)
);

-- PLAIN TEXT: pa$$w0rD
-- CONTRASEÑA: $argon2id$v=19$m=16,t=3,p=1$cVZKQk5JbEhFazNyZDRwSQ$KCBzJGrXFZYacO9DPYfSiQi3IDAXleTczjwlo74jZKs

CREATE INDEX idx_usuarios_empresa ON usuarios(id_empresa);
CREATE INDEX idx_usuarios_email ON usuarios(email);
CREATE INDEX idx_usuarios_rol ON usuarios(id_rol);
CREATE INDEX idx_usuarios_activos ON usuarios(id_empresa) WHERE eliminado_en IS NULL;

COMMIT;
