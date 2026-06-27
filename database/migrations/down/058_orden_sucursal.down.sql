BEGIN;

-- Rollback: migración 058 — elimina id_sucursal de tablas transaccionales
-- Orden inverso: primero índices, luego constraints FK, luego columnas.

-- -------------------------------------------------------------------------
-- comprobantes
-- -------------------------------------------------------------------------
DROP INDEX IF EXISTS idx_comprobantes_sucursal;
ALTER TABLE comprobantes DROP CONSTRAINT IF EXISTS fk_comprobantes_sucursal;
ALTER TABLE comprobantes DROP COLUMN IF EXISTS id_sucursal;

-- -------------------------------------------------------------------------
-- pagos_orden
-- -------------------------------------------------------------------------
DROP INDEX IF EXISTS idx_pagos_orden_sucursal;
ALTER TABLE pagos_orden DROP CONSTRAINT IF EXISTS fk_pagos_orden_sucursal;
ALTER TABLE pagos_orden DROP COLUMN IF EXISTS id_sucursal;

-- -------------------------------------------------------------------------
-- ordenes
-- -------------------------------------------------------------------------
DROP INDEX IF EXISTS idx_ordenes_sucursal;
ALTER TABLE ordenes DROP CONSTRAINT IF EXISTS fk_ordenes_sucursal;
ALTER TABLE ordenes DROP COLUMN IF EXISTS id_sucursal;

COMMIT;
