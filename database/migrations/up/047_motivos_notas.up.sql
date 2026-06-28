BEGIN;

-- Migración: motivos_nota_credito + motivos_nota_debito (lookup tables SUNAT)
-- Creada el: 27/05/2026
-- Secuencia: 047
--
-- Propósito: crear catálogos de motivos para notas de crédito y débito electrónicas.
-- Patrón: SERIAL para lookups (igual que tipos_comprobante / estados_comprobante de 041).
-- Datos de catálogo insertados inline con ON CONFLICT para idempotencia.
--
-- SUNAT code reference — motivos_nota_credito (13 códigos):
--   01 = Anulación de la operación
--   02 = Anulación por error en RUC
--   03 = Corrección por error en la descripción
--   04 = Descuento global
--   05 = Descuento por ítem
--   06 = Devolución total
--   07 = Devolución por ítem
--   08 = Bonificación
--   09 = Disminución en el valor
--   10 = Ajustes de precio
--   11 = Otros conceptos
--   12 = Acta de Entrega Conformidad
--   13 = Acta de Incumplimiento
--
-- SUNAT code reference — motivos_nota_debito (3 códigos):
--   01 = Interés por mora
--   02 = Aumento de precio
--   03 = Penalidades/otros

CREATE TABLE IF NOT EXISTS motivos_nota_credito (
    id      SERIAL       PRIMARY KEY,
    codigo  VARCHAR(2)   NOT NULL UNIQUE,
    nombre  VARCHAR(100) NOT NULL
);

CREATE TABLE IF NOT EXISTS motivos_nota_debito (
    id      SERIAL       PRIMARY KEY,
    codigo  VARCHAR(2)   NOT NULL UNIQUE,
    nombre  VARCHAR(100) NOT NULL
);

-- Datos de catálogo: 13 motivos de nota de crédito SUNAT
INSERT INTO motivos_nota_credito (codigo, nombre) VALUES
    ('01', 'Anulación de la operación'),
    ('02', 'Anulación por error en RUC'),
    ('03', 'Corrección por error en la descripción'),
    ('04', 'Descuento global'),
    ('05', 'Descuento por ítem'),
    ('06', 'Devolución total'),
    ('07', 'Devolución por ítem'),
    ('08', 'Bonificación'),
    ('09', 'Disminución en el valor'),
    ('10', 'Ajustes de precio'),
    ('11', 'Otros conceptos'),
    ('12', 'Acta de Entrega Conformidad'),
    ('13', 'Acta de Incumplimiento')
ON CONFLICT (codigo) DO NOTHING;

-- Datos de catálogo: 3 motivos de nota de débito SUNAT
INSERT INTO motivos_nota_debito (codigo, nombre) VALUES
    ('01', 'Interés por mora'),
    ('02', 'Aumento de precio'),
    ('03', 'Penalidades/otros')
ON CONFLICT (codigo) DO NOTHING;

COMMIT;
