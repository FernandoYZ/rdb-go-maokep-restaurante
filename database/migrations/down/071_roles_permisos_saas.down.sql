BEGIN;

-- Rollback:   roles_permisos_saas
-- Created:    2026-06-27
-- Version:    071

-- 1. Quitar asignación de rol al usuario administrador
DELETE FROM usuario_roles
WHERE id_rol = (SELECT id_rol FROM roles WHERE nombre_rol = 'super_administrador' AND id_empresa IS NULL LIMIT 1)
  AND id_usuario = (SELECT id_usuario FROM usuarios WHERE email = 'fernandozavala266@gmail.com' LIMIT 1);

-- 2. Quitar asociaciones de permisos del rol super_administrador
DELETE FROM rol_permisos
WHERE id_rol = (SELECT id_rol FROM roles WHERE nombre_rol = 'super_administrador' AND id_empresa IS NULL LIMIT 1);

-- 3. Quitar rol de super_administrador
DELETE FROM roles
WHERE nombre_rol = 'super_administrador' AND id_empresa IS NULL;

-- 4. Quitar permisos de nivel saas
DELETE FROM permisos
WHERE contexto = 'saas';

-- 5. Eliminar la columna contexto de la tabla permisos
ALTER TABLE permisos
    DROP COLUMN IF EXISTS contexto;

COMMIT;
