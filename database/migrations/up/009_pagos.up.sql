BEGIN;

-- Migración:  pagos
-- Creado:     2026-06-06 12:33:02
-- Versión:    009

CREATE TABLE IF NOT EXISTS pagos (
    id_pago UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_empresa UUID NOT NULL REFERENCES empresas(id_empresa) ON DELETE RESTRICT ON UPDATE CASCADE,
    id_suscripcion UUID NOT NULL REFERENCES suscripciones(id_suscripcion) ON DELETE RESTRICT ON UPDATE CASCADE,
    monto_pagado DECIMAL(10,2) NOT NULL,
    id_metodo_pago INT NOT NULL REFERENCES metodos_pago(id_metodo_pago) ON DELETE RESTRICT,
    id_estado_pago INT NOT NULL REFERENCES estados_pago(id_estado_pago),
    fecha_pago TIMESTAMPTZ,
    creado_en TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actualizado_en TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Índices iniciales
CREATE INDEX idx_pagos_empresa ON pagos(id_empresa);
CREATE INDEX idx_pagos_suscripcion ON pagos(id_suscripcion);
CREATE INDEX idx_pagos_estado ON pagos(id_estado_pago, creado_en);
CREATE INDEX idx_pagos_empresa_fecha ON pagos(id_empresa, creado_en);

COMMIT;
