BEGIN;

-- Migración: series_comprobante — agregar id_sucursal + reconstruir PK
-- Creada el: 27/05/2026
-- Secuencia: 059
--
-- Propósito:
--   1. Agregar columna id_sucursal (UUID FK → sucursales) a series_comprobante.
--   2. Backfill usando la primera sucursal de la empresa (mismo patrón que 058).
--   3. Eliminar la clave primaria surrogate UUID (id) y la UNIQUE anterior.
--   4. Reconstruir la PK como clave natural compuesta:
--      (id_sucursal, id_tipo_comprobante, serie).
--   5. Actualizar fn_siguiente_correlativo para incluir p_id_sucursal como
--      4to parámetro, y restringir la búsqueda por sucursal en lugar de por empresa.
--
-- SUPUESTO: ninguna otra tabla tiene FK a series_comprobante(id).
-- Confirmado por grep: no existen FKs externas a esta columna en el código base.
--
-- Dependencias: series_comprobante (migración 042), sucursales (migración 031),
--               fn_siguiente_correlativo (migración 053).

-- -------------------------------------------------------------------------
-- Paso 1: agregar id_sucursal como nullable, backfill, set NOT NULL
-- -------------------------------------------------------------------------
ALTER TABLE series_comprobante
    ADD COLUMN id_sucursal UUID NULL;

UPDATE series_comprobante sc
   SET id_sucursal = (
       SELECT s.id_sucursal
         FROM sucursales s
        WHERE s.id_empresa = sc.id_empresa
        ORDER BY s.creado_en ASC
        LIMIT 1
   );

ALTER TABLE series_comprobante
    ADD CONSTRAINT fk_series_comprobante_sucursal
        FOREIGN KEY (id_sucursal) REFERENCES sucursales(id_sucursal) ON DELETE RESTRICT;

ALTER TABLE series_comprobante
    ALTER COLUMN id_sucursal SET NOT NULL;

-- -------------------------------------------------------------------------
-- Paso 2: reconstruir PK (eliminar surrogate UUID, promover clave natural)
-- -------------------------------------------------------------------------

-- Eliminar UNIQUE constraint y PK existentes
ALTER TABLE series_comprobante DROP CONSTRAINT IF EXISTS uk_series_empresa_tipo_serie;
ALTER TABLE series_comprobante DROP CONSTRAINT IF EXISTS series_comprobante_pkey;

-- Eliminar columna id surrogate (ya no es la PK)
ALTER TABLE series_comprobante DROP COLUMN IF EXISTS id;

-- Crear nueva PK compuesta
ALTER TABLE series_comprobante
    ADD PRIMARY KEY (id_sucursal, id_tipo_comprobante, serie);

-- -------------------------------------------------------------------------
-- Paso 3: reemplazar fn_siguiente_correlativo con versión de 4 parámetros
--         El lookups se hace por (id_sucursal, id_tipo_comprobante, serie)
--         — ya no necesita id_empresa porque id_sucursal determina la empresa.
-- -------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_siguiente_correlativo(
    p_id_empresa           UUID,
    p_id_sucursal          UUID,
    p_id_tipo_comprobante  INT,
    p_serie                VARCHAR(4)
) RETURNS BIGINT LANGUAGE plpgsql AS $$
DECLARE
    v_siguiente BIGINT;
BEGIN
    UPDATE series_comprobante
       SET ultimo_correlativo = ultimo_correlativo + 1
     WHERE id_sucursal         = p_id_sucursal
       AND id_tipo_comprobante = p_id_tipo_comprobante
       AND serie               = p_serie
       AND activo              = TRUE
    RETURNING ultimo_correlativo INTO v_siguiente;

    IF v_siguiente IS NULL THEN
        RAISE EXCEPTION 'serie_not_found: %-%-%-%',
            p_id_empresa, p_id_sucursal, p_id_tipo_comprobante, p_serie;
    END IF;

    RETURN v_siguiente;
END;
$$;

COMMIT;
