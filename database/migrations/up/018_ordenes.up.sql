BEGIN;

-- Migración: ordenes
-- Creada el: 26/05/2026 00:31:53
-- Secuencia: 019

-- Crear tabla para secuencias por empresa (evita race conditions con SELECT FOR UPDATE)
CREATE TABLE IF NOT EXISTS secuencias_empresa (
  id_empresa     UUID         NOT NULL REFERENCES empresas(id_empresa) ON DELETE RESTRICT,
  tabla          VARCHAR(60)  NOT NULL,
  ultimo_valor   BIGINT       NOT NULL DEFAULT 0,
  creado_en      TIMESTAMPTZ  NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en TIMESTAMPTZ           DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_empresa, tabla)
);

CREATE TABLE IF NOT EXISTS ordenes (
    id_orden UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_empresa UUID NOT NULL REFERENCES empresas(id_empresa) ON DELETE RESTRICT,
    id_usuario UUID NOT NULL REFERENCES usuarios(id_usuario) ON DELETE RESTRICT,

    numero_orden BIGINT NOT NULL,
    id_estado_orden INT NOT NULL DEFAULT 1 REFERENCES estados_orden(id_estado_orden),

    tipo_orden VARCHAR(20) NOT NULL,
    notas TEXT,

    subtotal DECIMAL(10, 2) NOT NULL DEFAULT 0,
    impuesto DECIMAL(10, 2) NOT NULL DEFAULT 0,
    total DECIMAL(10, 2) NOT NULL DEFAULT 0,

    fecha_orden DATE NOT NULL DEFAULT CURRENT_DATE,

    eliminado_en TIMESTAMPTZ NULL,

    creado_en TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actualizado_en TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_ordenes_fecha_eliminacion
        CHECK (eliminado_en IS NULL OR eliminado_en >= creado_en)
);

CREATE INDEX idx_ordenes_empresa ON ordenes(id_empresa);
CREATE INDEX idx_ordenes_usuario ON ordenes(id_usuario);
CREATE INDEX idx_ordenes_estado ON ordenes(id_estado_orden);
CREATE INDEX idx_ordenes_fecha ON ordenes(id_empresa, creado_en);
CREATE INDEX idx_ordenes_activas ON ordenes(id_empresa) WHERE eliminado_en IS NULL;
CREATE UNIQUE INDEX uk_orden_empresa ON ordenes (numero_orden, id_empresa, fecha_orden);
CREATE INDEX idx_ordenes_empresa_numero_desc ON ordenes(id_empresa, numero_orden DESC);

COMMIT;
