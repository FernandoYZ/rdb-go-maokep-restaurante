BEGIN;

-- Migración: CHECK constraints monetarios
-- Creada el: 27/05/2026
-- Secuencia: 060
--
-- Propósito: garantizar integridad financiera a nivel de base de datos
-- impidiendo que se persistan montos negativos en las tablas de pago,
-- movimiento de caja, planes, facturación y notas de crédito/débito.

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

  -- Nuevos checks pre-flight
  IF (SELECT COUNT(*) FROM planes WHERE precio < 0) > 0 THEN
    RAISE EXCEPTION 'Se encontraron valores negativos en planes.precio — revisa data antes de aplicar constraint';
  END IF;

  IF (SELECT COUNT(*) FROM planes_periodos WHERE porcentaje_descuento < 0 OR porcentaje_descuento > 100) > 0 THEN
    RAISE EXCEPTION 'Se encontraron valores fuera del rango 0-100 en planes_periodos.porcentaje_descuento — revisa data antes de aplicar constraint';
  END IF;

  IF (SELECT COUNT(*) FROM aperturas_caja WHERE monto_inicial < 0) > 0 THEN
    RAISE EXCEPTION 'Se encontraron valores negativos en aperturas_caja.monto_inicial — revisa data antes de aplicar constraint';
  END IF;

  IF (SELECT COUNT(*) FROM aperturas_caja WHERE monto_cierre < 0) > 0 THEN
    RAISE EXCEPTION 'Se encontraron valores negativos en aperturas_caja.monto_cierre — revisa data antes de aplicar constraint';
  END IF;

  IF (SELECT COUNT(*) FROM arqueos_caja WHERE monto_esperado < 0) > 0 THEN
    RAISE EXCEPTION 'Se encontraron valores negativos en arqueos_caja.monto_esperado — revisa data antes de aplicar constraint';
  END IF;

  IF (SELECT COUNT(*) FROM arqueos_caja WHERE monto_real < 0) > 0 THEN
    RAISE EXCEPTION 'Se encontraron valores negativos en arqueos_caja.monto_real — revisa data antes de aplicar constraint';
  END IF;

  IF (SELECT COUNT(*) FROM comprobante_detalles WHERE precio_unitario < 0) > 0 THEN
    RAISE EXCEPTION 'Se encontraron valores negativos en comprobante_detalles.precio_unitario — revisa data antes de aplicar constraint';
  END IF;

  IF (SELECT COUNT(*) FROM comprobante_detalles WHERE subtotal < 0) > 0 THEN
    RAISE EXCEPTION 'Se encontraron valores negativos en comprobante_detalles.subtotal — revisa data antes de aplicar constraint';
  END IF;

  IF (SELECT COUNT(*) FROM comprobante_detalles WHERE igv < 0) > 0 THEN
    RAISE EXCEPTION 'Se encontraron valores negativos en comprobante_detalles.igv — revisa data antes de aplicar constraint';
  END IF;

  IF (SELECT COUNT(*) FROM comprobante_detalles WHERE precio_costo_snapshot < 0) > 0 THEN
    RAISE EXCEPTION 'Se encontraron valores negativos en comprobante_detalles.precio_costo_snapshot — revisa data antes de aplicar constraint';
  END IF;

  IF (SELECT COUNT(*) FROM notas_credito WHERE monto_total < 0) > 0 THEN
    RAISE EXCEPTION 'Se encontraron valores negativos en notas_credito.monto_total — revisa data antes de aplicar constraint';
  END IF;

  IF (SELECT COUNT(*) FROM notas_credito_detalles WHERE cantidad < 0) > 0 THEN
    RAISE EXCEPTION 'Se encontraron valores negativos en notas_credito_detalles.cantidad — revisa data antes de aplicar constraint';
  END IF;

  IF (SELECT COUNT(*) FROM notas_credito_detalles WHERE precio_unitario < 0) > 0 THEN
    RAISE EXCEPTION 'Se encontraron valores negativos en notas_credito_detalles.precio_unitario — revisa data antes de aplicar constraint';
  END IF;

  IF (SELECT COUNT(*) FROM notas_credito_detalles WHERE igv < 0) > 0 THEN
    RAISE EXCEPTION 'Se encontraron valores negativos en notas_credito_detalles.igv — revisa data antes de aplicar constraint';
  END IF;

  IF (SELECT COUNT(*) FROM notas_credito_detalles WHERE subtotal < 0) > 0 THEN
    RAISE EXCEPTION 'Se encontraron valores negativos en notas_credito_detalles.subtotal — revisa data antes de aplicar constraint';
  END IF;

  IF (SELECT COUNT(*) FROM notas_debito WHERE monto_total < 0) > 0 THEN
    RAISE EXCEPTION 'Se encontraron valores negativos en notas_debito.monto_total — revisa data antes de aplicar constraint';
  END IF;

  IF (SELECT COUNT(*) FROM notas_debito_detalles WHERE cantidad < 0) > 0 THEN
    RAISE EXCEPTION 'Se encontraron valores negativos en notas_debito_detalles.cantidad — revisa data antes de aplicar constraint';
  END IF;

  IF (SELECT COUNT(*) FROM notas_debito_detalles WHERE precio_unitario < 0) > 0 THEN
    RAISE EXCEPTION 'Se encontraron valores negativos en notas_debito_detalles.precio_unitario — revisa data antes de aplicar constraint';
  END IF;

  IF (SELECT COUNT(*) FROM notas_debito_detalles WHERE igv < 0) > 0 THEN
    RAISE EXCEPTION 'Se encontraron valores negativos en notas_debito_detalles.igv — revisa data antes de aplicar constraint';
  END IF;

  IF (SELECT COUNT(*) FROM notas_debito_detalles WHERE subtotal < 0) > 0 THEN
    RAISE EXCEPTION 'Se encontraron valores negativos en notas_debito_detalles.subtotal — revisa data antes de aplicar constraint';
  END IF;
END $$;

-- Aplicación de constraints (con DROP previo para garantizar idempotencia)

-- 1. pagos
ALTER TABLE pagos DROP CONSTRAINT IF EXISTS chk_pagos_monto_pagado_positive;
ALTER TABLE pagos ADD CONSTRAINT chk_pagos_monto_pagado_positive CHECK (monto_pagado >= 0);

-- 2. pagos_orden
ALTER TABLE pagos_orden DROP CONSTRAINT IF EXISTS chk_pagos_orden_monto_pagado_positive;
ALTER TABLE pagos_orden ADD CONSTRAINT chk_pagos_orden_monto_pagado_positive CHECK (monto_pagado >= 0);

-- 3. items_orden
ALTER TABLE items_orden DROP CONSTRAINT IF EXISTS chk_items_orden_precio_unitario_positive;
ALTER TABLE items_orden ADD CONSTRAINT chk_items_orden_precio_unitario_positive CHECK (precio_unitario >= 0);

ALTER TABLE items_orden DROP CONSTRAINT IF EXISTS chk_items_orden_subtotal_positive;
ALTER TABLE items_orden ADD CONSTRAINT chk_items_orden_subtotal_positive CHECK (subtotal >= 0);

-- 4. movimientos_caja
ALTER TABLE movimientos_caja DROP CONSTRAINT IF EXISTS chk_movimientos_caja_monto_positive;
ALTER TABLE movimientos_caja ADD CONSTRAINT chk_movimientos_caja_monto_positive CHECK (monto >= 0);

-- 5. planes
ALTER TABLE planes DROP CONSTRAINT IF EXISTS chk_planes_precio_positive;
ALTER TABLE planes ADD CONSTRAINT chk_planes_precio_positive CHECK (precio >= 0);

-- 6. planes_periodos
ALTER TABLE planes_periodos DROP CONSTRAINT IF EXISTS chk_planes_periodos_porcentaje_descuento_range;
ALTER TABLE planes_periodos ADD CONSTRAINT chk_planes_periodos_porcentaje_descuento_range CHECK (porcentaje_descuento >= 0 AND porcentaje_descuento <= 100);

-- 7. aperturas_caja
ALTER TABLE aperturas_caja DROP CONSTRAINT IF EXISTS chk_aperturas_caja_monto_inicial_positive;
ALTER TABLE aperturas_caja ADD CONSTRAINT chk_aperturas_caja_monto_inicial_positive CHECK (monto_inicial >= 0);

ALTER TABLE aperturas_caja DROP CONSTRAINT IF EXISTS chk_aperturas_caja_monto_cierre_positive;
ALTER TABLE aperturas_caja ADD CONSTRAINT chk_aperturas_caja_monto_cierre_positive CHECK (monto_cierre >= 0);

-- 8. arqueos_caja
ALTER TABLE arqueos_caja DROP CONSTRAINT IF EXISTS chk_arqueos_caja_monto_esperado_positive;
ALTER TABLE arqueos_caja ADD CONSTRAINT chk_arqueos_caja_monto_esperado_positive CHECK (monto_esperado >= 0);

ALTER TABLE arqueos_caja DROP CONSTRAINT IF EXISTS chk_arqueos_caja_monto_real_positive;
ALTER TABLE arqueos_caja ADD CONSTRAINT chk_arqueos_caja_monto_real_positive CHECK (monto_real >= 0);

-- 9. comprobante_detalles
ALTER TABLE comprobante_detalles DROP CONSTRAINT IF EXISTS chk_comprobante_detalles_precio_unitario_positive;
ALTER TABLE comprobante_detalles ADD CONSTRAINT chk_comprobante_detalles_precio_unitario_positive CHECK (precio_unitario >= 0);

ALTER TABLE comprobante_detalles DROP CONSTRAINT IF EXISTS chk_comprobante_detalles_subtotal_positive;
ALTER TABLE comprobante_detalles ADD CONSTRAINT chk_comprobante_detalles_subtotal_positive CHECK (subtotal >= 0);

ALTER TABLE comprobante_detalles DROP CONSTRAINT IF EXISTS chk_comprobante_detalles_igv_positive;
ALTER TABLE comprobante_detalles ADD CONSTRAINT chk_comprobante_detalles_igv_positive CHECK (igv >= 0);

ALTER TABLE comprobante_detalles DROP CONSTRAINT IF EXISTS chk_comprobante_detalles_precio_costo_snapshot_positive;
ALTER TABLE comprobante_detalles ADD CONSTRAINT chk_comprobante_detalles_precio_costo_snapshot_positive CHECK (precio_costo_snapshot >= 0);

-- 10. notas_credito
ALTER TABLE notas_credito DROP CONSTRAINT IF EXISTS chk_notas_credito_monto_total_positive;
ALTER TABLE notas_credito ADD CONSTRAINT chk_notas_credito_monto_total_positive CHECK (monto_total >= 0);

-- 11. notas_credito_detalles
ALTER TABLE notas_credito_detalles DROP CONSTRAINT IF EXISTS chk_notas_credito_detalles_cantidad_positive;
ALTER TABLE notas_credito_detalles ADD CONSTRAINT chk_notas_credito_detalles_cantidad_positive CHECK (cantidad >= 0);

ALTER TABLE notas_credito_detalles DROP CONSTRAINT IF EXISTS chk_notas_credito_detalles_precio_unitario_positive;
ALTER TABLE notas_credito_detalles ADD CONSTRAINT chk_notas_credito_detalles_precio_unitario_positive CHECK (precio_unitario >= 0);

ALTER TABLE notas_credito_detalles DROP CONSTRAINT IF EXISTS chk_notas_credito_detalles_igv_positive;
ALTER TABLE notas_credito_detalles ADD CONSTRAINT chk_notas_credito_detalles_igv_positive CHECK (igv >= 0);

ALTER TABLE notas_credito_detalles DROP CONSTRAINT IF EXISTS chk_notas_credito_detalles_subtotal_positive;
ALTER TABLE notas_credito_detalles ADD CONSTRAINT chk_notas_credito_detalles_subtotal_positive CHECK (subtotal >= 0);

-- 12. notas_debito
ALTER TABLE notas_debito DROP CONSTRAINT IF EXISTS chk_notas_debito_monto_total_positive;
ALTER TABLE notas_debito ADD CONSTRAINT chk_notas_debito_monto_total_positive CHECK (monto_total >= 0);

-- 13. notas_debito_detalles
ALTER TABLE notas_debito_detalles DROP CONSTRAINT IF EXISTS chk_notas_debito_detalles_cantidad_positive;
ALTER TABLE notas_debito_detalles ADD CONSTRAINT chk_notas_debito_detalles_cantidad_positive CHECK (cantidad >= 0);

ALTER TABLE notas_debito_detalles DROP CONSTRAINT IF EXISTS chk_notas_debito_detalles_precio_unitario_positive;
ALTER TABLE notas_debito_detalles ADD CONSTRAINT chk_notas_debito_detalles_precio_unitario_positive CHECK (precio_unitario >= 0);

ALTER TABLE notas_debito_detalles DROP CONSTRAINT IF EXISTS chk_notas_debito_detalles_igv_positive;
ALTER TABLE notas_debito_detalles ADD CONSTRAINT chk_notas_debito_detalles_igv_positive CHECK (igv >= 0);

ALTER TABLE notas_debito_detalles DROP CONSTRAINT IF EXISTS chk_notas_debito_detalles_subtotal_positive;
ALTER TABLE notas_debito_detalles ADD CONSTRAINT chk_notas_debito_detalles_subtotal_positive CHECK (subtotal >= 0);

COMMIT;
