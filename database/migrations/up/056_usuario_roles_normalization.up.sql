BEGIN;

-- Migration: usuario_roles normalization
-- Created: 2026-05-27
-- Sequence: 056
--
-- Purpose: replace the scalar usuarios.id_rol column with a junction table
-- that supports multi-role, per-branch, and temporally-bounded role assignments.

-- Step 1: Create junction table
CREATE TABLE usuario_roles (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    id_usuario      UUID        NOT NULL REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
    id_rol          INT         NOT NULL REFERENCES roles(id_rol) ON DELETE RESTRICT,
    id_sucursal     UUID        NULL     REFERENCES sucursales(id_sucursal) ON DELETE RESTRICT,
    efectivo_desde  TIMESTAMPTZ NULL,
    efectivo_hasta  TIMESTAMPTZ NULL,
    creado_en       TIMESTAMPTZ NOT NULL DEFAULT now(),
    actualizado_en  TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT chk_usuario_roles_fechas
        CHECK (efectivo_hasta IS NULL OR efectivo_hasta > efectivo_desde)
);

-- Step 2: Data migration — copy existing id_rol values (non-NULL only)
INSERT INTO usuario_roles (id_usuario, id_rol, id_sucursal, efectivo_desde)
SELECT id_usuario, id_rol, NULL, NULL
FROM usuarios
WHERE id_rol IS NOT NULL;

-- Step 3: Drop the scalar column
ALTER TABLE usuarios DROP COLUMN id_rol;

-- Partial unique index: global role assignment (no branch, no time bound)
CREATE UNIQUE INDEX uq_usuario_roles_global
    ON usuario_roles (id_usuario, id_rol)
    WHERE id_sucursal IS NULL AND efectivo_desde IS NULL;

-- Partial unique index: per-branch indefinite role assignment
CREATE UNIQUE INDEX uq_usuario_roles_sucursal
    ON usuario_roles (id_usuario, id_rol, id_sucursal)
    WHERE id_sucursal IS NOT NULL AND efectivo_desde IS NULL;

-- Performance indices
CREATE INDEX idx_usuario_roles_usuario  ON usuario_roles (id_usuario);
CREATE INDEX idx_usuario_roles_rol      ON usuario_roles (id_rol);
CREATE INDEX idx_usuario_roles_sucursal ON usuario_roles (id_sucursal)
    WHERE id_sucursal IS NOT NULL;
CREATE INDEX idx_usuario_roles_vigencia ON usuario_roles (efectivo_desde, efectivo_hasta);

-- Timestamp trigger
CREATE TRIGGER trg_actualizado_en_usuario_roles
    BEFORE UPDATE ON usuario_roles
    FOR EACH ROW EXECUTE FUNCTION establecer_actualizado_en();

COMMIT;
