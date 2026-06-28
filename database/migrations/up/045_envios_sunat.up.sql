BEGIN;

-- Migración: envios_sunat (log de auditoría append-only de comunicaciones SUNAT)
-- Creada el: 27/05/2026
-- Secuencia: 045
--
-- Propósito: registrar cada intento de envío a SUNAT con su resultado HTTP y CDR.
-- Decisiones de diseño:
--   - Append-only: NO tiene actualizado_en — una vez registrado, el intento no se modifica.
--     Si SUNAT responde con aceptado o rechazado, se inserta un nuevo registro.
--   - http_status: INT nullable — puede ser NULL si hubo timeout de red (no llegó respuesta HTTP).
--   - response_code: VARCHAR(50) nullable — código SUNAT (ej. '0' = aceptado).
--   - raw_cdr: TEXT nullable — el XML del CDR de SUNAT (puede ser NULL en error de red).
--   - FK RESTRICT a comprobantes: no se puede borrar un comprobante que tiene envíos registrados.
--   - Índice en creado_en DESC para queries de historial cronológico de envíos.

CREATE TABLE IF NOT EXISTS envios_sunat (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    id_comprobante  UUID        NOT NULL REFERENCES comprobantes(id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    http_status     INT,
    response_code   VARCHAR(50),
    raw_cdr         TEXT,
    creado_en       TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Índice para consultas de envíos por comprobante
CREATE INDEX IF NOT EXISTS idx_envios_comprobante
    ON envios_sunat(id_comprobante);

-- Índice para historial cronológico (auditoría)
CREATE INDEX IF NOT EXISTS idx_envios_creado
    ON envios_sunat(creado_en DESC);

COMMIT;
