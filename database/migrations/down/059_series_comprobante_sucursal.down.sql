BEGIN;

-- Rollback: migración 059 — restaurar PK original de series_comprobante
--           y firma original de fn_siguiente_correlativo (3 parámetros).
--
-- NOTA: el surrogate UUID (id) se pierde en la migración 059 up.
--       Al revertir, se genera un nuevo UUID por fila — los valores originales
--       de 'id' no son recuperables. Comportamiento esperado y documentado.

-- -------------------------------------------------------------------------
-- Paso 1: restaurar fn_siguiente_correlativo a firma 3-param (pre-059)
-- -------------------------------------------------------------------------

-- Eliminar la versión de 4 parámetros
DROP FUNCTION IF EXISTS fn_siguiente_correlativo(UUID, UUID, INT, VARCHAR);

-- Restaurar versión original de 3 parámetros
CREATE OR REPLACE FUNCTION fn_siguiente_correlativo(
    p_id_empresa           UUID,
    p_id_tipo_comprobante  INT,
    p_serie                VARCHAR(4)
) RETURNS BIGINT LANGUAGE plpgsql AS $$
DECLARE
    v_siguiente BIGINT;
BEGIN
    UPDATE series_comprobante
       SET ultimo_correlativo = ultimo_correlativo + 1
     WHERE id_empresa          = p_id_empresa
       AND id_tipo_comprobante = p_id_tipo_comprobante
       AND serie               = p_serie
       AND activo              = TRUE
    RETURNING ultimo_correlativo INTO v_siguiente;

    IF v_siguiente IS NULL THEN
        RAISE EXCEPTION 'serie_not_found: %-%-%',
            p_id_empresa, p_id_tipo_comprobante, p_serie;
    END IF;

    RETURN v_siguiente;
END;
$$;

-- -------------------------------------------------------------------------
-- Paso 2: restaurar PK y UNIQUE originales
-- -------------------------------------------------------------------------

-- Eliminar la nueva PK compuesta
ALTER TABLE series_comprobante DROP CONSTRAINT IF EXISTS series_comprobante_pkey;

-- Re-agregar columna id con UUID surrogate
ALTER TABLE series_comprobante
    ADD COLUMN id UUID NOT NULL DEFAULT gen_random_uuid();

-- Recrear la PK original en id
ALTER TABLE series_comprobante
    ADD PRIMARY KEY (id);

-- Restaurar la UNIQUE original
ALTER TABLE series_comprobante
    ADD CONSTRAINT uk_series_empresa_tipo_serie
        UNIQUE (id_empresa, id_tipo_comprobante, serie);

-- -------------------------------------------------------------------------
-- Paso 3: eliminar id_sucursal
-- -------------------------------------------------------------------------
ALTER TABLE series_comprobante DROP CONSTRAINT IF EXISTS fk_series_comprobante_sucursal;
ALTER TABLE series_comprobante DROP COLUMN IF EXISTS id_sucursal;

COMMIT;
