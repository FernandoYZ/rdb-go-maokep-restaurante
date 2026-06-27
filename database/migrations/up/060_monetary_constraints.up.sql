BEGIN;

-- Migración: CHECK constraints monetarios
-- Creada el: 27/05/2026
-- Secuencia: 060
--
-- Propósito: garantizar integridad financiera a nivel de base de datos
-- impidiendo que se persistan montos negativos en las tablas de pago
-- y movimiento de caja.
--
-- Tablas afectadas:
--   - pagos             (SaaS billing): monto_pagado >= 0
--   - pagos_orden       (pagos de mesa): monto_pagado >= 0
--   - items_orden       (líneas de orden): precio_unitario >= 0, subtotal >= 0
--   - movimientos_caja  (caja): monto >= 0
--
-- NOTA: comprobantes no tiene columna monto_total — constraint omitida.
--
-- Dependencias: migración 032 (pagos_orden), 018 (items_orden),
--               037 (movimientos_caja), 002 (pagos).

DO $$
BEGIN
  -- Pre-flight: abort if negatives exist (data integrity check)
  IF (SELECT COUNT(*) FROM pagos WHERE monto_pagado < 0) > 0 THEN
    RAISE EXCEPTION 'Se encontraron valores negativos en pagos.monto_pagado — revisa data antes de aplicar constraint';
  END IF;

  IF (SELECT COUNT(*) FROM pagos_orden WHERE monto_pagado < 0) > 0 THEN
    RAISE EXCEPTION 'Se encontraron valores negativos en pagos_orden.monto_pagado — revisa data antes de aplicar constraint';
  END IF;

  IF (SELECT COUNT(*) FROM items_orden WHERE precio_unitario < 0 OR subtotal < 0) > 0 THEN
    RAISE EXCEPTION 'Se encontraron valores negativos en items_orden.precio_unitario o subtotal — revisa data antes de aplicar constraint';
  END IF;

  IF (SELECT COUNT(*) FROM movimientos_caja WHERE monto < 0) > 0 THEN
    RAISE EXCEPTION 'Se encontraron valores negativos en movimientos_caja.monto — revisa data antes de aplicar constraint';
  END IF;
END $$;

ALTER TABLE pagos
  ADD CONSTRAINT chk_pagos_monto_pagado_positive
  CHECK (monto_pagado >= 0);

ALTER TABLE pagos_orden
  ADD CONSTRAINT chk_pagos_orden_monto_pagado_positive
  CHECK (monto_pagado >= 0);

ALTER TABLE items_orden
  ADD CONSTRAINT chk_items_orden_precio_unitario_positive
  CHECK (precio_unitario >= 0);

ALTER TABLE items_orden
  ADD CONSTRAINT chk_items_orden_subtotal_positive
  CHECK (subtotal >= 0);

ALTER TABLE movimientos_caja
  ADD CONSTRAINT chk_movimientos_caja_monto_positive
  CHECK (monto >= 0);

COMMIT;
