BEGIN;

-- Migración: metodos_pago
-- Creada el: 25/05/2026 15:31:52
-- Secuencia: 008

CREATE TABLE IF NOT EXISTS metodos_pago (
    id_metodo_pago INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    metodo_pago VARCHAR(20) NOT NULL UNIQUE,
    activo BOOLEAN NOT NULL DEFAULT TRUE
);

INSERT INTO metodos_pago (metodo_pago) VALUES
('Yape'),
('Transferencia'),
('Efectivo');

-- Catálogo de tipos de afectación al IGV (SUNAT)
CREATE TABLE IF NOT EXISTS tipos_afectacion_igv (
    id          INT          PRIMARY KEY,
    codigo      VARCHAR(2)   NOT NULL UNIQUE,
    descripcion VARCHAR(150) NOT NULL,
    creado_en   TIMESTAMPTZ  NOT NULL DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO tipos_afectacion_igv (id, codigo, descripcion) VALUES
    (10, '10', 'Gravado - Operación Onerosa'),
    (20, '20', 'Exonerado - Operación Onerosa'),
    (30, '30', 'Inafecto - Operación Onerosa')
ON CONFLICT (id) DO NOTHING;

COMMIT;
