BEGIN;

-- Migración: id_sucursal en tablas transaccionales
-- Creada el: 27/05/2026
-- Secuencia: 058
--
-- Propósito: agregar contexto de sucursal (id_sucursal) a las tablas
-- operacionales: ordenes, pagos_orden y comprobantes.
--
-- Patrón de tres pasos (safe nullable-backfill-NOT NULL):
--   1. ADD COLUMN nullable
--   2. UPDATE / backfill usando la primera sucursal de la empresa (ORDER BY creado_en ASC)
--   3. ALTER COLUMN SET NOT NULL
--
-- SUPUESTO de backfill: cada empresa tiene exactamente una sucursal seedeada.
-- En entornos multi-sucursal, verificar el resultado del UPDATE antes de aplicar.
--
-- Dependencias: sucursales (migración 031), ordenes (migración 018),
--               pagos_orden (migración 032), comprobantes (migración 043).

-- -------------------------------------------------------------------------
-- ordenes
-- -------------------------------------------------------------------------
ALTER TABLE ordenes
    ADD COLUMN id_sucursal UUID NULL;

UPDATE ordenes o
   SET id_sucursal = (
       SELECT s.id_sucursal
         FROM sucursales s
        WHERE s.id_empresa = o.id_empresa
        ORDER BY s.creado_en ASC
        LIMIT 1
   );

ALTER TABLE ordenes
    ADD CONSTRAINT fk_ordenes_sucursal
        FOREIGN KEY (id_sucursal) REFERENCES sucursales(id_sucursal) ON DELETE RESTRICT;

ALTER TABLE ordenes
    ALTER COLUMN id_sucursal SET NOT NULL;

CREATE INDEX idx_ordenes_sucursal ON ordenes(id_sucursal);

-- -------------------------------------------------------------------------
-- pagos_orden
-- -------------------------------------------------------------------------
ALTER TABLE pagos_orden
    ADD COLUMN id_sucursal UUID NULL;

UPDATE pagos_orden po
   SET id_sucursal = (
       SELECT s.id_sucursal
         FROM sucursales s
         JOIN ordenes o ON o.id_empresa = s.id_empresa
        WHERE o.id_orden = po.id_orden
        ORDER BY s.creado_en ASC
        LIMIT 1
   );

ALTER TABLE pagos_orden
    ADD CONSTRAINT fk_pagos_orden_sucursal
        FOREIGN KEY (id_sucursal) REFERENCES sucursales(id_sucursal) ON DELETE RESTRICT;

ALTER TABLE pagos_orden
    ALTER COLUMN id_sucursal SET NOT NULL;

CREATE INDEX idx_pagos_orden_sucursal ON pagos_orden(id_sucursal);

-- -------------------------------------------------------------------------
-- comprobantes
-- -------------------------------------------------------------------------
ALTER TABLE comprobantes
    ADD COLUMN id_sucursal UUID NULL;

UPDATE comprobantes c
   SET id_sucursal = (
       SELECT s.id_sucursal
         FROM sucursales s
        WHERE s.id_empresa = c.id_empresa
        ORDER BY s.creado_en ASC
        LIMIT 1
   );

ALTER TABLE comprobantes
    ADD CONSTRAINT fk_comprobantes_sucursal
        FOREIGN KEY (id_sucursal) REFERENCES sucursales(id_sucursal) ON DELETE RESTRICT;

ALTER TABLE comprobantes
    ALTER COLUMN id_sucursal SET NOT NULL;

CREATE INDEX idx_comprobantes_sucursal ON comprobantes(id_sucursal);

COMMIT;
