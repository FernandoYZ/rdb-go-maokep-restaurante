BEGIN;

-- Migración: permisos
-- Creada el: 26/05/2026 00:31:53
-- Secuencia: 012

CREATE TABLE IF NOT EXISTS permisos (
    id_permiso INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre_permiso VARCHAR(100) NOT NULL UNIQUE,
    descripcion TEXT,

    creado_en TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actualizado_en TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Insertar permisos por defecto (CRUD general)
INSERT INTO permisos (nombre_permiso, descripcion) VALUES
('ver_ordenes', 'Ver todas las órdenes del restaurante'),
('crear_orden', 'Crear nuevas órdenes'),
('editar_orden', 'Editar órdenes existentes'),
('eliminar_orden', 'Eliminar órdenes'),
('ver_menu', 'Ver catálogo de productos'),
('editar_menu', 'Modificar productos y categorías'),
('ver_pagos', 'Ver transacciones de pago'),
('procesar_pago', 'Procesar pagos'),
('ver_reportes', 'Acceder a reportes y analytics'),
('gestionar_usuarios', 'Crear y modificar usuarios'),
('gestionar_configuracion', 'Modificar configuración del restaurante'),
('acceder_auditoria', 'Ver registros de auditoría');

COMMIT;
