BEGIN;

-- Migración:  planes
-- Creado:     2026-06-05 20:16:23
-- Versión:    001

CREATE TABLE IF NOT EXISTS planes (
    id_plan INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    plan VARCHAR(30) NOT NULL,
    precio DECIMAL(10, 2) NOT NULL,
    dias_vigencia INT NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    creado_en TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actualizado_en TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO planes (plan, precio, dias_vigencia) VALUES
('Emprende', 29.90, 30),
('Crece', 49.90, 30),
('Escala', 89.90, 30);

COMMIT;
