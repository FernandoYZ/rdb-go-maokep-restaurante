BEGIN;

-- Migración:  metodos_pago
-- Creado:     2026-06-06 12:31:55
-- Versión:    008

CREATE TABLE IF NOT EXISTS metodos_pago (
    id_metodo_pago INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    metodo_pago VARCHAR(20) NOT NULL UNIQUE,
    activo BOOLEAN NOT NULL DEFAULT TRUE
);

INSERT INTO metodos_pago (metodo_pago) VALUES
('Yape'),
('Transferencia'),
('Efectivo');

COMMIT;
