BEGIN;

-- Migración: usuarios
-- Creada el: 26/05/2026 00:31:53
-- Secuencia: 014

CREATE TABLE IF NOT EXISTS usuarios (
    id_usuario UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_empresa UUID NULL REFERENCES empresas(id_empresa) ON DELETE CASCADE,
    id_rol INT NOT NULL REFERENCES roles(id_rol),

    email VARCHAR(100) NOT NULL,
    usuario VARCHAR(50) NOT NULL,
    contrasena_hash VARCHAR(255) NOT NULL,
    nombre VARCHAR(150) NOT NULL,
    apellido VARCHAR(150),

    activo BOOLEAN NOT NULL DEFAULT TRUE,
    ultimo_acceso TIMESTAMPTZ,
    eliminado_en TIMESTAMPTZ NULL,

    scope VARCHAR(20) NOT NULL DEFAULT 'operativo' CHECK (scope IN ('global', 'operativo')),

    creado_en TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actualizado_en TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_usuarios_fecha_eliminacion CHECK (eliminado_en IS NULL OR eliminado_en >= creado_en),
    CONSTRAINT chk_usuarios_scope_empresa CHECK (
        (scope = 'global' AND id_empresa IS NULL) OR
        (scope = 'operativo' AND id_empresa IS NOT NULL)
    )
);

-- CONTRASEÑA: $argon2id$v=19$m=16,t=3,p=1$TmMwdGpScm4xNWdQU2VNMA$+lsrNgk7M05xUH4rHjEQF+rx+zWLNzRDxplRskKawxY

CREATE UNIQUE INDEX uk_usuarios_email_empresa ON usuarios (email, id_empresa) WHERE eliminado_en IS NULL AND id_empresa IS NOT NULL;
CREATE UNIQUE INDEX uk_usuarios_email_global ON usuarios (email) WHERE id_empresa IS NULL;

CREATE INDEX idx_usuarios_empresa ON usuarios(id_empresa);
CREATE INDEX idx_usuarios_email ON usuarios(email);
CREATE INDEX idx_usuarios_rol ON usuarios(id_rol);
CREATE INDEX idx_usuarios_activos ON usuarios(id_empresa) WHERE eliminado_en IS NULL;

-- Promover al administrador inicial a scope global
UPDATE usuarios
  SET scope = 'global', id_empresa = NULL
  WHERE email = 'fernandozavala266@gmail.com';

COMMIT;
