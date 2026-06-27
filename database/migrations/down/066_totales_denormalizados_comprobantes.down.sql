BEGIN;

-- Rollback:   totales_denormalizados_comprobantes
-- Created:    2026-06-27
-- Version:    066

-- 1. Eliminar índice
DROP INDEX IF EXISTS idx_comprobantes_reportes_totales;

-- 2. Eliminar constraints monetarios
ALTER TABLE comprobantes
    DROP CONSTRAINT IF EXISTS chk_comprobantes_total_gravado_positive,
    DROP CONSTRAINT IF EXISTS chk_comprobantes_total_exonerado_positive,
    DROP CONSTRAINT IF EXISTS chk_comprobantes_total_inafecto_positive,
    DROP CONSTRAINT IF EXISTS chk_comprobantes_total_igv_positive,
    DROP CONSTRAINT IF EXISTS chk_comprobantes_monto_total_positive;

-- 3. Eliminar columnas
ALTER TABLE comprobantes
    DROP COLUMN IF EXISTS total_gravado,
    DROP COLUMN IF EXISTS total_exonerado,
    DROP COLUMN IF EXISTS total_inafecto,
    DROP COLUMN IF EXISTS total_igv,
    DROP COLUMN IF EXISTS monto_total,
    DROP COLUMN IF EXISTS codigo_moneda;

COMMIT;
