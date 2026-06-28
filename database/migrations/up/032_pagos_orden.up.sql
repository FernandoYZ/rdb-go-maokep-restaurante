BEGIN;

-- Migración: pagos_orden dominio operativo
-- Creada el: 26/05/2026
-- Secuencia: 032
--
-- Propósito: crear tabla de pagos operativos vinculados a órdenes del restaurante.
-- Esta tabla es distinta de `pagos` (suscripciones SaaS) y opera en el dominio
-- de gestión de órdenes por empresa.

CREATE TABLE IF NOT EXISTS pagos_orden (
    id_pago_orden    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_orden         UUID NOT NULL REFERENCES ordenes(id_orden) ON DELETE RESTRICT,
    id_empresa       UUID NOT NULL REFERENCES empresas(id_empresa) ON DELETE RESTRICT,

    monto_pagado     NUMERIC(12, 2) NOT NULL,
    moneda           VARCHAR(3) NOT NULL DEFAULT 'PEN',
    tipo_cambio      NUMERIC(10, 4),
    monto_recibido   NUMERIC(12, 2),
    vuelto           NUMERIC(12, 2),

    id_metodo_pago   INT REFERENCES metodos_pago(id_metodo_pago) ON DELETE RESTRICT,
    id_estado_pago   INT NOT NULL REFERENCES estados_pago(id_estado_pago) ON DELETE RESTRICT,

    fecha_pago       TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    eliminado_en     TIMESTAMPTZ NULL,

    creado_en        TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actualizado_en   TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Restricciones de consistencia monetaria
    CONSTRAINT chk_pagos_orden_monto_recibido CHECK (monto_recibido IS NULL OR monto_recibido >= 0),
    CONSTRAINT chk_pagos_orden_vuelto CHECK (vuelto IS NULL OR vuelto >= 0),
    CONSTRAINT chk_pagos_orden_vuelto_calculo CHECK (
        (monto_recibido IS NULL OR vuelto IS NULL) OR 
        (vuelto = monto_recibido - monto_pagado)
    )
);

-- Índice para navegación por FK de orden
CREATE INDEX IF NOT EXISTS idx_pagos_orden_orden ON pagos_orden (id_orden);

-- Índice para consultas de pagos por empresa en un rango de fechas
CREATE INDEX IF NOT EXISTS idx_pagos_orden_empresa ON pagos_orden (id_empresa, creado_en);

-- Trigger para auto-actualizar actualizado_en
DROP TRIGGER IF EXISTS trg_actualizado_en_pagos_orden ON pagos_orden;
CREATE TRIGGER trg_actualizado_en_pagos_orden
  BEFORE UPDATE ON pagos_orden
  FOR EACH ROW EXECUTE FUNCTION establecer_actualizado_en();

COMMIT;
