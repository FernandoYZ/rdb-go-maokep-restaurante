BEGIN;

-- Migración: registros_auditoria
-- Creada el: 26/05/2026 00:31:53
-- Secuencia: 021

CREATE TABLE IF NOT EXISTS registros_auditoria (
    id_auditoria UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_empresa UUID NOT NULL REFERENCES empresas(id_empresa) ON DELETE RESTRICT,
    id_usuario UUID REFERENCES usuarios(id_usuario) ON DELETE SET NULL,

    tabla_afectada VARCHAR(100) NOT NULL,
    operacion VARCHAR(10) NOT NULL,
    registro_id TEXT,  -- TEXT permite auditar entidades con PKs de cualquier tipo (UUID, INT, compuestas)

    datos_anteriores JSONB,
    datos_nuevos JSONB,

    direccion_ip VARCHAR(45),
    user_agent TEXT,

    creado_en TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_auditoria_empresa ON registros_auditoria(id_empresa);
CREATE INDEX idx_auditoria_usuario ON registros_auditoria(id_usuario);
CREATE INDEX idx_auditoria_tabla ON registros_auditoria(tabla_afectada);
CREATE INDEX idx_auditoria_operacion ON registros_auditoria(operacion);
CREATE INDEX idx_auditoria_fecha ON registros_auditoria(id_empresa, creado_en);

COMMIT;
