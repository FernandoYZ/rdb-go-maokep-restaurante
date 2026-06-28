BEGIN;

-- Migración: Session LISTEN/NOTIFY Infrastructure
-- Creada el: 27/05/2026
-- Secuencia: 062
--
-- Propósito: infraestructura para notificación en tiempo real de cambios de sesión.
-- Permite que Go escuche LISTEN session_changes y actualice cache local sin polling.
--
-- Use case:
--   1. Usuario hace login → trigger emite NOTIFY
--   2. Go listener recibe NOTIFY y actualiza cache de sesiones activas
--   3. Logout/revoke → NOTIFY, cache se actualiza
--   4. Cookie + cache → validación rápida sin query a DB en cada request
--
-- Nota: LISTEN/NOTIFY es para monolito con múltiples goroutines, no para distribuido.

-- ============================================================================
-- 1. Tabla: session_events (evento log para auditoría opcional)
-- ============================================================================
CREATE TABLE session_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  id_sesion UUID NOT NULL,
  id_usuario UUID NOT NULL,
  evento VARCHAR(20) NOT NULL, -- 'created', 'revoked', 'extended', 'expired'
  razon TEXT NULL,
  ip_address INET NULL,
  creado_en TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Índices para auditoría rápida
CREATE INDEX idx_session_events_sesion ON session_events(id_sesion);
CREATE INDEX idx_session_events_usuario ON session_events(id_usuario);
CREATE INDEX idx_session_events_fecha ON session_events(creado_en DESC);

-- ============================================================================
-- 2. Función: fn_notify_session_change
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_notify_session_change(
  p_id_sesion UUID,
  p_id_usuario UUID,
  p_evento VARCHAR(20),
  p_razon TEXT DEFAULT NULL
)
RETURNS VOID AS $$
DECLARE
  v_payload TEXT;
BEGIN
  -- Insert evento log
  INSERT INTO session_events (id_sesion, id_usuario, evento, razon, ip_address)
  VALUES (p_id_sesion, p_id_usuario, p_evento, p_razon, inet_client_addr());

  -- Emit NOTIFY con payload JSON
  v_payload := json_build_object(
    'id_sesion', p_id_sesion::TEXT,
    'id_usuario', p_id_usuario::TEXT,
    'evento', p_evento,
    'creado_en', CURRENT_TIMESTAMP
  )::TEXT;

  PERFORM pg_notify('session_changes', v_payload);
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 3. Trigger: cuando se crea sesión (INSERT en sesiones)
-- ============================================================================
CREATE OR REPLACE FUNCTION trg_sesion_created()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM fn_notify_session_change(
    NEW.id_sesion,
    NEW.id_usuario,
    'created',
    'New session'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sesion_insert_notify
  AFTER INSERT ON sesiones
  FOR EACH ROW EXECUTE FUNCTION trg_sesion_created();

-- ============================================================================
-- 4. Trigger: cuando se revoca sesión (UPDATE revocado = true)
-- ============================================================================
CREATE OR REPLACE FUNCTION trg_sesion_revoked()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.revocado AND NOT OLD.revocado THEN
    PERFORM fn_notify_session_change(
      NEW.id_sesion,
      NEW.id_usuario,
      'revoked',
      'Session revoked by user or admin'
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sesion_update_notify
  AFTER UPDATE ON sesiones
  FOR EACH ROW EXECUTE FUNCTION trg_sesion_revoked();

-- ============================================================================
-- 5. Helper view: sesiones_activas (para validación rápida)
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

-- Habilitar Row Level Security (RLS) en session_events
ALTER TABLE session_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY session_events_tenant_isolation ON session_events
    USING (
        EXISTS (
            SELECT 1 FROM usuarios u
            WHERE u.id_usuario = session_events.id_usuario
              AND u.id_empresa = current_setting('app.id_empresa', true)::uuid
        )
    );

COMMIT;
