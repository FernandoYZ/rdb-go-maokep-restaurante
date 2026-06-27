BEGIN;

-- Migración: vouchers
-- Creada el: 25/05/2026 15:50:00
-- Secuencia: 021

CREATE TABLE IF NOT EXISTS vouchers (
    id_voucher UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    id_pago UUID NOT NULL REFERENCES pagos(id_pago) ON DELETE RESTRICT ON UPDATE CASCADE,

    numero_transaccion VARCHAR(50),
    tipo_evidencia VARCHAR(30) NOT NULL,

    imagen_url TEXT,

    verificado BOOLEAN NOT NULL DEFAULT FALSE,
    fecha_verificacion TIMESTAMPTZ,
    id_usuario_verificador UUID REFERENCES usuarios(id_usuario) ON DELETE SET NULL,

    creado_en TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actualizado_en TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Índices para búsqueda y auditoría
CREATE INDEX idx_vouchers_pago ON vouchers(id_pago);
CREATE INDEX idx_vouchers_verificado ON vouchers(verificado, creado_en);
CREATE INDEX idx_vouchers_usuario_verificador ON vouchers(id_usuario_verificador);
CREATE INDEX idx_vouchers_empresa ON vouchers(id_pago, verificado);

COMMIT;
