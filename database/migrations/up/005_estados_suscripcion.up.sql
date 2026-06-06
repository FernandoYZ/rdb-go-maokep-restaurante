BEGIN;

-- Migración:  estados_suscripcion
-- Creado:     2026-06-05 20:48:31
-- Versión:    005

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
