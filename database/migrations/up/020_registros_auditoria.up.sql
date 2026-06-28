BEGIN;

-- Migración: registros_auditoria
-- Creada el: 26/05/2026 00:31:53
-- Secuencia: 021

-- Crear ENUM para operaciones de auditoría
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'tipo_operacion_auditoria') THEN
        CREATE TYPE tipo_operacion_auditoria AS ENUM (
            'CREAR',
            'MODIFICAR',
            'ELIMINAR',
            'ACTIVAR',
            'DESACTIVAR'
        );
    END IF;
END $$;

CREATE TABLE IF NOT EXISTS registros_auditoria (
    id_auditoria UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_empresa UUID NOT NULL REFERENCES empresas(id_empresa) ON DELETE RESTRICT,
    id_usuario UUID REFERENCES usuarios(id_usuario) ON DELETE SET NULL,

    tabla_afectada VARCHAR(100) NOT NULL,
    operacion tipo_operacion_auditoria NOT NULL,
    registro_id TEXT,  -- TEXT permite auditar entidades con PKs de cualquier tipo (UUID, INT, compuestas)

    datos_anteriores JSONB,
    datos_nuevos JSONB,

    direccion_ip VARCHAR(45),
    user_agent TEXT,

    creado_en TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_auditoria_empresa ON registros_auditoria(id_empresa);
CREATE INDEX IF NOT EXISTS idx_auditoria_usuario ON registros_auditoria(id_usuario);
CREATE INDEX IF NOT EXISTS idx_auditoria_tabla ON registros_auditoria(tabla_afectada);
CREATE INDEX IF NOT EXISTS idx_auditoria_operacion ON registros_auditoria(operacion);
CREATE INDEX IF NOT EXISTS idx_auditoria_fecha ON registros_auditoria(id_empresa, creado_en);

-- Habilitar Row Level Security (RLS)
ALTER TABLE registros_auditoria ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS registros_auditoria_tenant_isolation ON registros_auditoria;
CREATE POLICY registros_auditoria_tenant_isolation ON registros_auditoria
    USING (id_empresa = current_setting('app.id_empresa', true)::uuid)
    WITH CHECK (id_empresa = current_setting('app.id_empresa', true)::uuid);

-- Función genérica de auditoría con JSONB
CREATE OR REPLACE FUNCTION auditar_registro()
RETURNS TRIGGER AS $$
DECLARE
    v_id_empresa UUID;
    v_id_usuario UUID;
    v_operacion tipo_operacion_auditoria;
    v_registro_id TEXT;
    v_datos_anteriores JSONB := NULL;
    v_datos_nuevos JSONB := NULL;
    v_tabla VARCHAR(100);
BEGIN
    v_tabla := TG_TABLE_NAME::VARCHAR(100);

    -- 1. Intentar obtener el contexto de sesión (RLS y auditoría)
    BEGIN
        v_id_empresa := NULLIF(current_setting('app.id_empresa', true), '')::UUID;
    EXCEPTION WHEN OTHERS THEN
        v_id_empresa := NULL;
    END;

    BEGIN
        v_id_usuario := NULLIF(current_setting('app.id_usuario', true), '')::UUID;
    EXCEPTION WHEN OTHERS THEN
        v_id_usuario := NULL;
    END;

    -- 2. Determinar la operación e identificar los datos
    IF (TG_OP = 'INSERT') THEN
        v_operacion := 'CREAR'::tipo_operacion_auditoria;
        v_datos_nuevos := to_jsonb(NEW);
        
        IF v_id_empresa IS NULL THEN
            BEGIN
                v_id_empresa := (to_jsonb(NEW) ->> 'id_empresa')::UUID;
            EXCEPTION WHEN OTHERS THEN
                v_id_empresa := NULL;
            END;
        END IF;

        v_registro_id := COALESCE(
            to_jsonb(NEW) ->> ('id_' || rtrim(v_tabla, 's')),
            to_jsonb(NEW) ->> 'id_rol',
            to_jsonb(NEW) ->> 'id_usuario',
            to_jsonb(NEW) ->> 'id_producto',
            to_jsonb(NEW) ->> 'id'
        );

    ELSIF (TG_OP = 'UPDATE') THEN
        v_operacion := 'MODIFICAR'::tipo_operacion_auditoria;
        
        -- Detección de activación/desactivación
        IF (to_jsonb(OLD) -> 'disponible' IS NOT NULL) THEN
            IF ((to_jsonb(OLD) ->> 'disponible')::BOOLEAN IS DISTINCT FROM (to_jsonb(NEW) ->> 'disponible')::BOOLEAN) THEN
                IF (to_jsonb(NEW) ->> 'disponible')::BOOLEAN THEN
                    v_operacion := 'ACTIVAR'::tipo_operacion_auditoria;
                ELSE
                    v_operacion := 'DESACTIVAR'::tipo_operacion_auditoria;
                END IF;
            END IF;
        ELSIF (to_jsonb(OLD) -> 'activo' IS NOT NULL) THEN
            IF ((to_jsonb(OLD) ->> 'activo')::BOOLEAN IS DISTINCT FROM (to_jsonb(NEW) ->> 'activo')::BOOLEAN) THEN
                IF (to_jsonb(NEW) ->> 'activo')::BOOLEAN THEN
                    v_operacion := 'ACTIVAR'::tipo_operacion_auditoria;
                ELSE
                    v_operacion := 'DESACTIVAR'::tipo_operacion_auditoria;
                END IF;
            END IF;
        END IF;

        v_datos_anteriores := to_jsonb(OLD);
        v_datos_nuevos := to_jsonb(NEW);

        IF v_id_empresa IS NULL THEN
            BEGIN
                v_id_empresa := (to_jsonb(NEW) ->> 'id_empresa')::UUID;
            EXCEPTION WHEN OTHERS THEN
                v_id_empresa := NULL;
            END;
        END IF;

        v_registro_id := COALESCE(
            to_jsonb(NEW) ->> ('id_' || rtrim(v_tabla, 's')),
            to_jsonb(NEW) ->> 'id_rol',
            to_jsonb(NEW) ->> 'id_usuario',
            to_jsonb(NEW) ->> 'id_producto',
            to_jsonb(NEW) ->> 'id'
        );

    ELSIF (TG_OP = 'DELETE') THEN
        v_operacion := 'ELIMINAR'::tipo_operacion_auditoria;
        v_datos_anteriores := to_jsonb(OLD);

        IF v_id_empresa IS NULL THEN
            BEGIN
                v_id_empresa := (to_jsonb(OLD) ->> 'id_empresa')::UUID;
            EXCEPTION WHEN OTHERS THEN
                v_id_empresa := NULL;
            END;
        END IF;

        v_registro_id := COALESCE(
            to_jsonb(OLD) ->> ('id_' || rtrim(v_tabla, 's')),
            to_jsonb(OLD) ->> 'id_rol',
            to_jsonb(OLD) ->> 'id_usuario',
            to_jsonb(OLD) ->> 'id_producto',
            to_jsonb(OLD) ->> 'id'
        );
    END IF;

    -- Fallback de id_empresa para entorno local o semillas
    IF v_id_empresa IS NULL THEN
        SELECT id_empresa INTO v_id_empresa FROM empresas LIMIT 1;
    END IF;

    -- Insertar log solo si logramos determinar una empresa
    IF v_id_empresa IS NOT NULL THEN
        INSERT INTO registros_auditoria (
            id_empresa,
            id_usuario,
            tabla_afectada,
            operacion,
            registro_id,
            datos_anteriores,
            datos_nuevos,
            direccion_ip,
            user_agent
        ) VALUES (
            v_id_empresa,
            v_id_usuario,
            v_tabla,
            v_operacion,
            v_registro_id,
            v_datos_anteriores,
            v_datos_nuevos,
            NULLIF(current_setting('app.ip_cliente', true), ''),
            NULLIF(current_setting('app.user_agent', true), '')
        );
    END IF;

    IF (TG_OP = 'DELETE') THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Triggers de auditoría para tablas críticas
DROP TRIGGER IF EXISTS trg_auditar_usuarios ON usuarios;
CREATE TRIGGER trg_auditar_usuarios
AFTER INSERT OR UPDATE OR DELETE ON usuarios
FOR EACH ROW EXECUTE FUNCTION auditar_registro();

DROP TRIGGER IF EXISTS trg_auditar_roles ON roles;
CREATE TRIGGER trg_auditar_roles
AFTER INSERT OR UPDATE OR DELETE ON roles
FOR EACH ROW EXECUTE FUNCTION auditar_registro();

DROP TRIGGER IF EXISTS trg_auditar_configuracion_empresa ON configuracion_empresa;
CREATE TRIGGER trg_auditar_configuracion_empresa
AFTER INSERT OR UPDATE OR DELETE ON configuracion_empresa
FOR EACH ROW EXECUTE FUNCTION auditar_registro();

DROP TRIGGER IF EXISTS trg_auditar_productos ON productos;
CREATE TRIGGER trg_auditar_productos
AFTER INSERT OR UPDATE OR DELETE ON productos
FOR EACH ROW EXECUTE FUNCTION auditar_registro();

COMMIT;
