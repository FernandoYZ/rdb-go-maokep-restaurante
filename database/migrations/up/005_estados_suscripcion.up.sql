BEGIN;

-- Migración: estados_suscripcion
-- Creada el: 25/05/2026 14:49:14
-- Secuencia: 005

CREATE TABLE IF NOT EXISTS estados_suscripcion (
    id_estado_suscripcion INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    estado_suscripcion VARCHAR(20) NOT NULL
);

INSERT INTO estados_suscripcion (estado_suscripcion) VALUES
('Activa'),
('Vencido'),
('Suspendida'),
('Cancelada');

COMMIT;
