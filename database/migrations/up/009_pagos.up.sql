BEGIN;

-- Migración: pagos
-- Creada el: 25/05/2026 15:35:17
-- Secuencia: 009

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

-- Índices para performance multi-tenant
CREATE INDEX IF NOT EXISTS idx_pagos_empresa ON pagos(id_empresa);
CREATE INDEX IF NOT EXISTS idx_pagos_suscripcion ON pagos(id_suscripcion);
CREATE INDEX IF NOT EXISTS idx_pagos_estado ON pagos(id_estado_pago, creado_en);
CREATE INDEX IF NOT EXISTS idx_pagos_empresa_fecha ON pagos(id_empresa, creado_en);

-- Habilitar Row Level Security (RLS)
ALTER TABLE pagos ENABLE ROW LEVEL SECURITY;

CREATE POLICY pagos_tenant_isolation ON pagos
    USING (id_empresa = current_setting('app.id_empresa', true)::uuid)
    WITH CHECK (id_empresa = current_setting('app.id_empresa', true)::uuid);

COMMIT;
