BEGIN;

-- Migración: roles
-- Creada el: 26/05/2026 00:31:53
-- Secuencia: 011

CREATE TABLE IF NOT EXISTS roles (
    id_rol INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre_rol VARCHAR(50) NOT NULL,
    descripcion TEXT,
    id_empresa UUID NULL REFERENCES empresas(id_empresa) ON DELETE CASCADE,

    creado_en TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actualizado_en TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX uk_roles_nombre_global ON roles (nombre_rol) WHERE id_empresa IS NULL;
CREATE UNIQUE INDEX uk_roles_nombre_empresa ON roles (nombre_rol, id_empresa) WHERE id_empresa IS NOT NULL;

-- Insertar roles por defecto
INSERT INTO roles (nombre_rol, descripcion) VALUES
('administrador', 'Administrador del sistema con acceso total'),
('gerente', 'Gerente de restaurante con control operativo'),
('mesero', 'Personal de mesero para tomar órdenes'),
('cocina', 'Personal de cocina para preparar órdenes'),
('caja', 'Personal de caja para procesar pagos'),
('cliente', 'Cliente de la plataforma SaaS');

COMMIT;
