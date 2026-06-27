BEGIN;

-- Migración: estados_pago
-- Creada el: 25/05/2026 15:27:30
-- Secuencia: 007

CREATE TABLE IF NOT EXISTS estados_pago (
    id_estado_pago INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    estado_pago VARCHAR(15) NOT NULL
);

INSERT INTO estados_pago (estado_pago) VALUES
('Pendiente'),
('Rechazado'),
('Pagado');

COMMIT;
