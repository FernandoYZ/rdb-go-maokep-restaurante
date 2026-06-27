BEGIN;

-- Migración: planes_periodos
-- Creada el: 25/05/2026 15:07:50
-- Secuencia: 002

CREATE TABLE IF NOT EXISTS planes_periodos (
    id_periodo INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_plan INT NOT NULL REFERENCES planes(id_plan),
    meses INT NOT NULL,
    porcentaje_descuento DECIMAL(5,2) NOT NULL DEFAULT 0
);


INSERT INTO planes_periodos
(id_plan, meses, porcentaje_descuento)
VALUES
-- Emprende
(1, 1, 0),
(1, 3, 5),
(1, 12, 15),

-- Crece
(2, 1, 0),
(2, 3, 7),
(2, 12, 18),

-- Escala
(3, 1, 0),
(3, 3, 10),
(3, 12, 20);

COMMIT;
