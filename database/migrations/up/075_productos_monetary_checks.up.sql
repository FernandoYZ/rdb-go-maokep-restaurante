BEGIN;

-- Migración: CHECK constraints monetarios para productos
-- Creada el: 2026-06-28
-- Secuencia: 075
--
-- Propósito: Garantizar integridad financiera impidiendo
-- precios de venta o costos negativos en la tabla de productos.

DO $$
BEGIN
  -- Pre-flight: abortar si existen precios negativos (chequeo de integridad de datos)
  IF (SELECT COUNT(*) FROM productos WHERE precio_venta < 0) > 0 THEN
    RAISE EXCEPTION 'Se encontraron valores negativos en productos.precio_venta — revisa los datos antes de aplicar el constraint';
  END IF;

  IF (SELECT COUNT(*) FROM productos WHERE precio_costo < 0) > 0 THEN
    RAISE EXCEPTION 'Se encontraron valores negativos en productos.precio_costo — revisa los datos antes de aplicar el constraint';
  END IF;
END $$;

-- Aplicación de constraints (con DROP previo para garantizar idempotencia)
ALTER TABLE productos DROP CONSTRAINT IF EXISTS chk_productos_precio_venta_positive;
ALTER TABLE productos ADD CONSTRAINT chk_productos_precio_venta_positive CHECK (precio_venta >= 0);

ALTER TABLE productos DROP CONSTRAINT IF EXISTS chk_productos_precio_costo_positive;
ALTER TABLE productos ADD CONSTRAINT chk_productos_precio_costo_positive CHECK (precio_costo IS NULL OR precio_costo >= 0);

COMMIT;
