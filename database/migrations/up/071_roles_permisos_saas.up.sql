BEGIN;

-- Migration:  roles_permisos_saas
-- Created:    2026-06-27
-- Version:    071
--
-- Propósito: Diferenciar el Control Plane (permisos globales de administración del SaaS)
--            del Data Plane (operaciones de restaurante). Se crea el rol de 
--            Super Administrador y se le otorgan permisos exclusivos de plataforma.

-- 1. Agregar columna contexto a la tabla permisos
ALTER TABLE permisos
    ADD COLUMN contexto VARCHAR(20) NOT NULL DEFAULT 'tenant' CHECK (contexto IN ('saas', 'tenant'));

-- 2. Insertar nuevos permisos de nivel de plataforma SaaS
INSERT INTO permisos (nombre_permiso, descripcion, contexto) VALUES
    ('saas_ver_empresas', 'Ver listado global de empresas registradas', 'saas'),
    ('saas_crear_empresa', 'Registrar una nueva empresa en el SaaS', 'saas'),
    ('saas_gestionar_planes', 'Administrar planes de precios y límites', 'saas'),
    ('saas_ver_pagos', 'Ver reporte de ingresos y facturación de suscripciones del SaaS', 'saas'),
    ('saas_soporte_tecnico', 'Permiso para impersonar o dar soporte técnico a inquilinos', 'saas')
ON CONFLICT (nombre_permiso) DO NOTHING;

-- 3. Insertar el rol global de Super Administrador de la plataforma
INSERT INTO roles (nombre_rol, descripcion, id_empresa) VALUES
    ('super_administrador', 'Super Administrador de la plataforma SaaS con acceso al panel de control global', NULL)
ON CONFLICT (nombre_rol) WHERE id_empresa IS NULL DO NOTHING;

-- 4. Asociar todos los permisos de contexto 'saas' al rol 'super_administrador'
INSERT INTO rol_permisos (id_rol, id_permiso)
SELECT 
    (SELECT id_rol FROM roles WHERE nombre_rol = 'super_administrador' AND id_empresa IS NULL LIMIT 1),
    id_permiso
FROM permisos
WHERE contexto = 'saas'
ON CONFLICT (id_rol, id_permiso) DO NOTHING;

-- 5. Asignar el rol de super_administrador al usuario creador en la tabla pivot de roles
INSERT INTO usuario_roles (id_usuario, id_rol, id_sucursal, efectivo_desde)
SELECT 
    id_usuario,
    (SELECT id_rol FROM roles WHERE nombre_rol = 'super_administrador' AND id_empresa IS NULL LIMIT 1),
    NULL,
    NULL
FROM usuarios
WHERE email = 'fernandozavala266@gmail.com'
ON CONFLICT DO NOTHING;

COMMIT;
