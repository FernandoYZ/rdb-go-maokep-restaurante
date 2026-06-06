BEGIN;

-- Migración:  estados_empresa
-- Creado:     2026-06-05 20:28:42
-- Versión:    003

CREATE TABLE IF NOT EXISTS estados_empresa (
    id_estado_empresa INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    estado_empresa VARCHAR(15) NOT NULL
);

INSERT INTO estados_empresa (estado_empresa) VALUES
('Activo'),
('Suspendido'),
('Eliminado');

COMMIT;
