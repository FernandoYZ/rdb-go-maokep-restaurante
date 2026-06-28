BEGIN;

-- Migración: configuracion_empresa
-- Creada el: 26/05/2026 00:31:53
-- Secuencia: 015

CREATE TABLE IF NOT EXISTS configuracion_empresa (
    id_configuracion UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_empresa UUID NOT NULL UNIQUE REFERENCES empresas(id_empresa) ON DELETE CASCADE,

    nombre_publico VARCHAR(200) NOT NULL,
    logo_url TEXT,
    descripcion TEXT,

    horario_apertura TIME,
    horario_cierre TIME,
    zona_horaria VARCHAR(50) DEFAULT 'America/Lima',

    latitud DECIMAL(10, 8),
    longitud DECIMAL(11, 8),
    telefono VARCHAR(15),

    puede_recoger BOOLEAN DEFAULT TRUE,
    puede_entregar BOOLEAN DEFAULT FALSE,
    puede_comer_in_situ BOOLEAN DEFAULT TRUE,

    creado_en TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actualizado_en TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_configuracion_empresa ON configuracion_empresa(id_empresa);

COMMIT;
