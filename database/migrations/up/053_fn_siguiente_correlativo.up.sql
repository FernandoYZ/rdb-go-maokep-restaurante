BEGIN;

-- Migración: fn_siguiente_correlativo — asignación atómica de correlativos
-- Creada el: 27/05/2026
-- Secuencia: 053
--
-- Propósito: función plpgsql que incrementa y retorna el próximo correlativo
-- para una combinación empresa + tipo_comprobante + serie de forma atómica.
--
-- Mecanismo de atomicidad:
--   UPDATE...RETURNING en un único statement. PostgreSQL adquiere un row lock
--   exclusivo sobre la fila actualizada; RETURNING lee el valor post-update
--   dentro del mismo lock scope. Dos sesiones concurrentes serializan sobre
--   ese lock — la segunda espera a que la primera haga commit o rollback.
--   No se usa SELECT FOR UPDATE (introduciría ventana TOCTOU).
--
-- Contrato de error: si ninguna fila activa coincide con (empresa, tipo, serie),
--   la función lanza EXCEPTION con mensaje 'serie_not_found: ...'.
--
-- Dependencias: series_comprobante (migración 042, Phase 4).
-- PREREQUISITO: activo = TRUE en la fila de series_comprobante.

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

COMMIT;
