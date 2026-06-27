BEGIN;

-- Down migration: restore usuarios.id_rol scalar column from usuario_roles
-- and drop the junction table.

-- Step 1: Re-add the scalar column as nullable
ALTER TABLE usuarios ADD COLUMN id_rol INT NULL REFERENCES roles(id_rol);

-- Step 2: Backfill from the first global usuario_roles row per user
-- (global = id_sucursal IS NULL, ordered by creado_en)
UPDATE usuarios u
SET id_rol = (
    SELECT ur.id_rol
    FROM usuario_roles ur
    WHERE ur.id_usuario = u.id_usuario
      AND ur.id_sucursal IS NULL
    ORDER BY ur.creado_en ASC
    LIMIT 1
);

-- Step 3: Drop the junction table (cascade removes FK deps if any)
DROP TABLE usuario_roles;

COMMIT;
