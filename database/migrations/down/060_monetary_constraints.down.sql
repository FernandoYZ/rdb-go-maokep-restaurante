BEGIN;

-- Rollback: eliminar CHECK constraints monetarios
-- Secuencia: 060 down

ALTER TABLE movimientos_caja
  DROP CONSTRAINT IF EXISTS chk_movimientos_caja_monto_positive;

ALTER TABLE items_orden
  DROP CONSTRAINT IF EXISTS chk_items_orden_subtotal_positive;

ALTER TABLE items_orden
  DROP CONSTRAINT IF EXISTS chk_items_orden_precio_unitario_positive;

ALTER TABLE pagos_orden
  DROP CONSTRAINT IF EXISTS chk_pagos_orden_monto_pagado_positive;

ALTER TABLE pagos
  DROP CONSTRAINT IF EXISTS chk_pagos_monto_pagado_positive;

COMMIT;
