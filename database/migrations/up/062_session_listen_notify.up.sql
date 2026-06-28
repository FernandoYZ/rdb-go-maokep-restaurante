BEGIN;

-- Migración: infraestructura de sesiones con LISTEN/NOTIFY
-- Creada el: 27/05/2026
-- Secuencia: 062
--
-- Propósito: auditoría y notificación en tiempo real de cambios de sesión.
-- Permite que Go escuche cambios y actualice caché local sin polling.
--
-- Caso de uso:
--   1. Usuario hace login → trigger emite NOTIFY
--   2. Go listener recibe NOTIFY y actualiza caché de sesiones activas
--   3. Logout/revoke → NOTIFY, caché se actualiza
--   4. Cookie + caché → validación rápida sin query a BD en cada request

-- ============================================================================
-- 1. Tabla: tipos_evento_sesion (enumeración de eventos válidos)
-- ============================================================================
CREATE TABLE IF NOT EXISTS tipos_evento_sesion (
    id INT PRIMARY KEY,
    tipo_evento VARCHAR(30) NOT NULL UNIQUE,
    descripcion TEXT
);

INSERT INTO tipos_evento_sesion (id, tipo_evento, descripcion) VALUES
    (1, 'creada', 'Nueva sesión creada'),
    (2, 'revocada', 'Sesión revocada por usuario o administrador'),
    (3, 'extendida', 'Sesión extendida'),
    (4, 'expirada', 'Sesión expirada por tiempo'),
    (5, 'renovada', 'Sesión renovada con nuevo refresh token')
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- 2. Tabla: eventos_sesion (log de auditoría para cambios de sesión)
-- ============================================================================
CREATE TABLE IF NOT EXISTS eventos_sesion (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_sesion UUID NOT NULL REFERENCES sesiones(id_sesion) ON DELETE CASCADE,
    id_usuario UUID NOT NULL REFERENCES usuarios(id_usuario) ON DELETE RESTRICT,
    id_tipo_evento INT NOT NULL REFERENCES tipos_evento_sesion(id) ON DELETE RESTRICT,
    razon TEXT NULL,
    direccion_ip INET NULL,
    creado_en TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Índices para consultas de auditoría eficientes
CREATE INDEX IF NOT EXISTS idx_eventos_sesion_sesion ON eventos_sesion(id_sesion);
CREATE INDEX IF NOT EXISTS idx_eventos_sesion_usuario ON eventos_sesion(id_usuario);
CREATE INDEX IF NOT EXISTS idx_eventos_sesion_tipo ON eventos_sesion(id_tipo_evento);
CREATE INDEX IF NOT EXISTS idx_eventos_sesion_fecha ON eventos_sesion(creado_en DESC);

-- ============================================================================
-- 3. Vista: sesiones_activas (filtro para sesiones válidas)
-- ============================================================================
CREATE OR REPLACE VIEW sesiones_activas AS
SELECT
    id_sesion,
    id_usuario,
    refresh_token_hash,
    ip_address,
    user_agent,
    dispositivo_nombre,
    ultimo_acceso,
    expira_en,
    creado_en
FROM sesiones
WHERE revocado = FALSE
    AND expira_en > CURRENT_TIMESTAMP;

-- ============================================================================
-- 4. Función: fn_registrar_evento_sesion
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_registrar_evento_sesion(
    p_id_sesion UUID,
    p_id_usuario UUID,
    p_id_tipo_evento INT,
    p_razon TEXT DEFAULT NULL
)
RETURNS VOID AS $$
DECLARE
    v_payload TEXT;
    v_tipo_evento VARCHAR(30);
BEGIN
    -- Obtener nombre del tipo de evento
    SELECT tipo_evento INTO v_tipo_evento
    FROM tipos_evento_sesion
    WHERE id = p_id_tipo_evento;

    -- Insertar registro de evento
    INSERT INTO eventos_sesion (id_sesion, id_usuario, id_tipo_evento, razon, direccion_ip)
    VALUES (p_id_sesion, p_id_usuario, p_id_tipo_evento, p_razon, inet_client_addr());

    -- Emitir notificación con payload JSON
    v_payload := json_build_object(
        'id_sesion', p_id_sesion::TEXT,
        'id_usuario', p_id_usuario::TEXT,
        'id_tipo_evento', p_id_tipo_evento,
        'tipo_evento', v_tipo_evento,
        'creado_en', CURRENT_TIMESTAMP
    )::TEXT;

    PERFORM pg_notify('cambios_sesion', v_payload);
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 5. Trigger: cuando se crea sesión (INSERT en sesiones)
-- ============================================================================
CREATE OR REPLACE FUNCTION trg_sesion_creada()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM fn_registrar_evento_sesion(
        NEW.id_sesion,
        NEW.id_usuario,
        1,
        'Nueva sesión'
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_sesion_insert_notificar ON sesiones;
CREATE TRIGGER trg_sesion_insert_notificar
    AFTER INSERT ON sesiones
    FOR EACH ROW EXECUTE FUNCTION trg_sesion_creada();

-- ============================================================================
-- 6. Trigger: cuando se revoca sesión (UPDATE revocado = true)
-- ============================================================================
CREATE OR REPLACE FUNCTION trg_sesion_revocada()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.revocado AND NOT OLD.revocado THEN
        PERFORM fn_registrar_evento_sesion(
            NEW.id_sesion,
            NEW.id_usuario,
            2,
            'Sesión revocada'
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_sesion_update_notificar ON sesiones;
CREATE TRIGGER trg_sesion_update_notificar
    AFTER UPDATE ON sesiones
    FOR EACH ROW EXECUTE FUNCTION trg_sesion_revocada();

-- ============================================================================
-- 7. Row Level Security (RLS)
-- ============================================================================
ALTER TABLE eventos_sesion ENABLE ROW LEVEL SECURITY;

CREATE POLICY eventos_sesion_aislamiento_inquilino ON eventos_sesion
    USING (
        EXISTS (
            SELECT 1 FROM usuarios u
            WHERE u.id_usuario = eventos_sesion.id_usuario
              AND u.id_empresa = current_setting('app.id_empresa', true)::uuid
        )
    );

COMMIT;
