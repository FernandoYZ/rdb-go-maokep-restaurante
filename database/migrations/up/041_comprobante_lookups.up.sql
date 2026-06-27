BEGIN;

-- Migración: tipos_comprobante + estados_comprobante (lookup tables SUNAT)
-- Creada el: 27/05/2026
-- Secuencia: 041
--
-- Propósito: crear catálogos inmutables para el módulo de comprobantes electrónicos SUNAT.
-- Patrón: SERIAL para lookups (igual que estados_caja, tipos_movimiento_caja de migración 037).
-- Los datos de catálogo se insertan inline porque las tablas operativas de 042/043
-- referencian estas FKs y no pueden existir sin los valores base.
--
-- SUNAT code reference:
--   01 = Factura Electrónica
--   03 = Boleta de Venta Electrónica

CREATE TABLE tipos_comprobante (
    id      SERIAL       PRIMARY KEY,
    code    VARCHAR(2)   NOT NULL UNIQUE,
    nombre  VARCHAR(100) NOT NULL,
    activo  BOOLEAN      NOT NULL DEFAULT TRUE,
    creado_en TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE estados_comprobante (
    id          SERIAL      PRIMARY KEY,
    nombre      VARCHAR(50) NOT NULL UNIQUE,
    descripcion TEXT,
    creado_en   TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Datos de catálogo: 2 tipos SUNAT activos
INSERT INTO tipos_comprobante (code, nombre) VALUES
    ('01', 'Factura Electrónica'),
    ('03', 'Boleta de Venta Electrónica')
ON CONFLICT (code) DO NOTHING;

-- Datos de catálogo: 5 estados del ciclo de vida SUNAT
INSERT INTO estados_comprobante (nombre) VALUES
    ('borrador'),
    ('emitido'),
    ('aceptado'),
    ('rechazado'),
    ('anulado')
ON CONFLICT (nombre) DO NOTHING;

COMMIT;
