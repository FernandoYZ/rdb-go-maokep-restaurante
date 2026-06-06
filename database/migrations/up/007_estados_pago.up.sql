BEGIN;

-- Migración:  estados_pago
-- Creado:     2026-06-06 12:31:21
-- Versión:    007

CREATE TABLE IF NOT EXISTS estados_pago (
    id_estado_pago INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    estado_pago VARCHAR(15) NOT NULL
);

INSERT INTO estados_pago (estado_pago) VALUES
('Pendiente'),
('Rechazado'),
('Pagado');

COMMIT;
