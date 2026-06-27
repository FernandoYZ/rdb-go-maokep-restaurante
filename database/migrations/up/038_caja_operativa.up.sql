BEGIN;

-- Migración: aperturas_caja, movimientos_caja, arqueos_caja
-- Creada el: 26/05/2026
-- Secuencia: 038
--
-- Propósito: crear el dominio operativo de caja para el restaurante.
-- id_empresa se denormaliza en aperturas_caja para soportar RLS y consultas directas
-- sin requerir JOIN a sucursales (ver diseño: Decision sobre RLS aperturas_caja).

CREATE TABLE aperturas_caja (
  id               UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  id_empresa       UUID          NOT NULL REFERENCES empresas(id_empresa)     ON DELETE RESTRICT,
  id_sucursal      UUID          NOT NULL REFERENCES sucursales(id_sucursal)  ON DELETE RESTRICT,
  id_usuario       UUID          NOT NULL REFERENCES usuarios(id_usuario)     ON DELETE RESTRICT,
  id_estado_caja   INT           NOT NULL REFERENCES estados_caja(id_estado_caja) ON DELETE RESTRICT,

  monto_inicial    NUMERIC(12,2) NOT NULL,
  monto_cierre     NUMERIC(12,2) NOT NULL DEFAULT 0,

  fecha_apertura   TIMESTAMPTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_cierre     TIMESTAMPTZ   NULL,

  eliminado_en     TIMESTAMPTZ   NULL,

  creado_en        TIMESTAMPTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en   TIMESTAMPTZ            DEFAULT CURRENT_TIMESTAMP
);

-- Trigger para actualizado_en
CREATE TRIGGER trg_actualizado_en_aperturas_caja
  BEFORE UPDATE ON aperturas_caja
  FOR EACH ROW EXECUTE FUNCTION establecer_actualizado_en();

CREATE TABLE movimientos_caja (
  id                   UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  id_apertura_caja     UUID          NOT NULL REFERENCES aperturas_caja(id) ON DELETE RESTRICT,
  id_orden             UUID          NULL     REFERENCES ordenes(id_orden)  ON DELETE RESTRICT,
  id_tipo_movimiento   INT           NOT NULL REFERENCES tipos_movimiento_caja(id_tipo_movimiento) ON DELETE RESTRICT,
  id_metodo_pago       INT           NULL     REFERENCES metodos_pago(id_metodo_pago) ON DELETE RESTRICT,

  monto                NUMERIC(12,2) NOT NULL,
  descripcion          TEXT,

  creado_en            TIMESTAMPTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Índice para navegación por apertura + fecha (usado en reportes de caja)
CREATE INDEX idx_movimientos_caja_apertura_fecha
  ON movimientos_caja(id_apertura_caja, creado_en DESC);

-- Índice para optimizar arqueos de caja discriminados por método de pago
CREATE INDEX idx_movimientos_caja_metodo_pago 
  ON movimientos_caja(id_apertura_caja, id_metodo_pago) 
  WHERE id_metodo_pago IS NOT NULL;

CREATE TABLE arqueos_caja (
  id                UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  id_apertura_caja  UUID          NOT NULL UNIQUE REFERENCES aperturas_caja(id) ON DELETE RESTRICT,

  monto_esperado    NUMERIC(12,2) NOT NULL,
  monto_real        NUMERIC(12,2) NOT NULL,
  diferencia        NUMERIC(12,2) GENERATED ALWAYS AS (monto_real - monto_esperado) STORED,

  creado_en         TIMESTAMPTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Función: actualizar monto_cierre en aperturas_caja al insertar movimiento
CREATE OR REPLACE FUNCTION actualizar_monto_cierre_caja()
RETURNS TRIGGER AS $$
DECLARE
    v_id_apertura UUID;
BEGIN
    -- Resolver id_apertura_caja tanto para INSERT, UPDATE como DELETE
    v_id_apertura := COALESCE(NEW.id_apertura_caja, OLD.id_apertura_caja);
    
    UPDATE aperturas_caja
    SET monto_cierre = monto_inicial + (
        SELECT COALESCE(SUM(monto), 0)
        FROM movimientos_caja
        WHERE id_apertura_caja = v_id_apertura
    )
    WHERE id = v_id_apertura;
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Trigger: ejecutar después de cada INSERT, UPDATE o DELETE en movimientos_caja
CREATE TRIGGER trg_movimiento_actualiza_monto_cierre
  AFTER INSERT OR UPDATE OR DELETE ON movimientos_caja
  FOR EACH ROW EXECUTE FUNCTION actualizar_monto_cierre_caja();

COMMIT;
