BEGIN;

-- Migración: estados_caja + tipos_movimiento_caja (lookup tables)
-- Creada el: 26/05/2026
-- Secuencia: 037
--
-- Propósito: crear catálogos inmutables para el módulo de caja operativa.
-- Patrón: SERIAL para lookups (igual que estados_orden, estados_pago, metodos_pago).
-- Los datos de catálogo se insertan inline porque las tablas operativas de 038
-- referencian estas FKs y no pueden existir sin los valores base.

CREATE TABLE estados_caja (
  id_estado_caja  SERIAL       PRIMARY KEY,
  codigo          VARCHAR(20)  UNIQUE NOT NULL,
  nombre          VARCHAR(100) NOT NULL,
  creado_en       TIMESTAMPTZ  NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE tipos_movimiento_caja (
  id_tipo_movimiento  SERIAL       PRIMARY KEY,
  codigo              VARCHAR(20)  UNIQUE NOT NULL,
  nombre              VARCHAR(100) NOT NULL,
  creado_en           TIMESTAMPTZ  NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Datos de catálogo: 3 estados de caja
INSERT INTO estados_caja (codigo, nombre) VALUES
  ('abierta',    'Caja Abierta'),
  ('cerrada',    'Caja Cerrada'),
  ('suspendida', 'Caja Suspendida')
ON CONFLICT (codigo) DO NOTHING;

-- Datos de catálogo: 5 tipos de movimiento
INSERT INTO tipos_movimiento_caja (codigo, nombre) VALUES
  ('ingreso',   'Ingreso de dinero'),
  ('egreso',    'Egreso de dinero'),
  ('apertura',  'Apertura de caja'),
  ('cierre',    'Cierre de caja'),
  ('reembolso', 'Reembolso cliente')
ON CONFLICT (codigo) DO NOTHING;

COMMIT;
