BEGIN;

-- Migración: sesiones con refresh tokens y revocación
-- Creada el: 26/05/2026
-- Secuencia: 030
--
-- Propósito: persistir sesiones de usuario para manejo de refresh tokens JWT,
-- permitiendo revocación individual y auditoría de dispositivos.

CREATE TABLE sesiones (
    id_sesion          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_usuario         UUID NOT NULL REFERENCES usuarios(id_usuario) ON DELETE RESTRICT,

    refresh_token_hash VARCHAR(255) NOT NULL,

    -- Información del dispositivo/cliente
    ip_address         INET,
    user_agent         TEXT,
    dispositivo_nombre VARCHAR(100),

    ultimo_acceso      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expira_en          TIMESTAMPTZ NOT NULL,

    -- Estado de revocación
    revocado           BOOLEAN NOT NULL DEFAULT FALSE,
    revocado_en        TIMESTAMPTZ NULL,

    eliminado_en       TIMESTAMPTZ NULL,

    creado_en          TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actualizado_en     TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- La sesión debe expirar después de su creación
    CONSTRAINT chk_sesiones_expiry CHECK (expira_en > creado_en)
);

-- Índice compuesto para consultas típicas: sesiones activas de un usuario ordenadas por expiración
CREATE INDEX idx_sesiones_usuario ON sesiones (id_usuario, expira_en);

-- Índice parcial para filtrado rápido de sesiones no revocadas
CREATE INDEX idx_sesiones_activas ON sesiones (id_usuario) WHERE revocado = FALSE;

-- Trigger para auto-actualizar actualizado_en
CREATE TRIGGER trg_actualizado_en_sesiones
  BEFORE UPDATE ON sesiones
  FOR EACH ROW EXECUTE FUNCTION establecer_actualizado_en();

-- Índice para acelerar la purga de sesiones expiradas
CREATE INDEX idx_sesiones_expiracion ON sesiones(expira_en);

-- Habilitar Row Level Security (RLS)
ALTER TABLE sesiones ENABLE ROW LEVEL SECURITY;

CREATE POLICY sesiones_tenant_isolation ON sesiones
    USING (
        EXISTS (
            SELECT 1 FROM usuarios u
            WHERE u.id_usuario = sesiones.id_usuario
              AND u.id_empresa = current_setting('app.id_empresa', true)::uuid
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM usuarios u
            WHERE u.id_usuario = sesiones.id_usuario
              AND u.id_empresa = current_setting('app.id_empresa', true)::uuid
        )
    );

COMMIT;
