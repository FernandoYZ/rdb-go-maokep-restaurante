BEGIN;

-- Migración:  empresas
-- Creado:     2026-06-05 20:29:44
-- Versión:    004

CREATE TABLE IF NOT EXISTS empresas (
    id_empresa UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    nombre_empresa VARCHAR(150) NOT NULL, -- ejempo: Restaurante Miguelon Pablito
    slug VARCHAR(120) UNIQUE NOT NULL, -- ejemplo rest-miguelon-pablito

    ruc VARCHAR(11) UNIQUE,

    celular VARCHAR(15),
    direccion TEXT,

    id_plan INT NOT NULL REFERENCES planes(id_plan), -- emprende / crece / escala

    id_estado_empresa INT NOT NULL DEFAULT 1 REFERENCES estados_empresa(id_estado_empresa), -- activo

    fecha_inicio_plan TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    fecha_fin_plan TIMESTAMPTZ,

    creado_en TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actualizado_en TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMIT;
