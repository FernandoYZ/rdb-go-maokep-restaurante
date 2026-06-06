BEGIN;

-- Migración:  roles
-- Creado:     2026-06-06 12:50:17
-- Versión:    010

CREATE TABLE IF NOT EXISTS roles (
    id_rol INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre_rol VARCHAR(50) NOT NULL UNIQUE,
    descripcion TEXT,

    creado_en TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actualizado_en TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Insertar roles por defecto
INSERT INTO roles (nombre_rol, descripcion) VALUES
('administrador', 'Administrador del sistema con acceso total'),
('gerente', 'Gerente de restaurante con control operativo'),
('mesero', 'Personal de mesero para tomar órdenes'),
('cocina', 'Personal de cocina para preparar órdenes'),
('caja', 'Personal de caja para procesar pagos'),
('cliente', 'Cliente de la plataforma SaaS');

COMMIT;
