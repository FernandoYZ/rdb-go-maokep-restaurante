BEGIN;

-- Migración: estados_orden
-- Creada el: 26/05/2026 00:31:53
-- Secuencia: 018

CREATE TABLE IF NOT EXISTS estados_orden (
    id_estado_orden INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre_estado VARCHAR(30) NOT NULL UNIQUE
);

-- Insertar estados por defecto
INSERT INTO estados_orden (nombre_estado) VALUES
('Pendiente'),
('Confirmada'),
('En preparación'),
('Listo'),
('Entregada'),
('Cancelada'),
('Devuelta');

COMMIT;
