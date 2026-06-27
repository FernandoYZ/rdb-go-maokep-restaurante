BEGIN;

-- Migración: suscripciones
-- Creada el: 25/05/2026 15:20:54
-- Secuencia: 006

CREATE TABLE IF NOT EXISTS suscripciones (
    id_suscripcion UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    id_empresa UUID NOT NULL REFERENCES empresas(id_empresa),

    id_plan INT NOT NULL REFERENCES planes(id_plan),
    id_periodo INT NOT NULL REFERENCES planes_periodos(id_periodo),

    precio_pagado DECIMAL(10,2) NOT NULL,

    fecha_inicio TIMESTAMPTZ NOT NULL,
    fecha_fin TIMESTAMPTZ NOT NULL,

    id_estado_suscripcion INT NOT NULL REFERENCES estados_suscripcion(id_estado_suscripcion) DEFAULT 1, -- Activo

    creado_en TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMIT;
