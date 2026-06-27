BEGIN;

-- Migración: planes
-- Creada el: 25/05/2026 14:30:58
-- Secuencia: 001

CREATE TABLE IF NOT EXISTS planes (
    id_plan INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    plan VARCHAR(30) NOT NULL,
    codigo VARCHAR(30) NOT NULL UNIQUE,
    precio DECIMAL(10, 2) NOT NULL,
    dias_vigencia INT NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    creado_en TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actualizado_en TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO planes (plan, codigo, precio, dias_vigencia) VALUES
('Emprende', 'emprende', 29.90, 30),
('Crece', 'crece', 49.90, 30),
('Escala', 'escala', 89.90, 30);

COMMIT;
