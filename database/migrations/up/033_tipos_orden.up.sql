BEGIN;

-- Migración: tipos_orden lookup + ALTER ordenes tipo_orden → id_tipo_orden FK
-- Creada el: 26/05/2026
-- Secuencia: 033
--
-- Propósito: normalizar tipo_orden de VARCHAR a FK referenciando tabla lookup tipos_orden.
-- Patrón: SERIAL para lookups (igual que estados_orden, estados_pago, metodos_pago).
-- Pre-check: aborta si existen valores en ordenes.tipo_orden sin mapeo en los 5 códigos definidos.

-- Pre-check: detener migración si hay valores no mapeables
DO $$
DECLARE
  v_exists BOOLEAN;
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name='ordenes' AND column_name='tipo_orden'
  ) THEN
    EXECUTE 'SELECT EXISTS (
      SELECT 1 FROM ordenes
      WHERE tipo_orden NOT IN (''mesa'', ''delivery'', ''recojo'', ''qr'', ''app_movil'')
    )' INTO v_exists;
    
    IF v_exists THEN
      RAISE EXCEPTION 'tipos_orden: valores no mapeables encontrados en ordenes.tipo_orden. Corregir datos antes de migrar.';
    END IF;
  END IF;
END $$;

-- Crear tabla lookup
CREATE TABLE IF NOT EXISTS tipos_orden (
  id_tipo_orden  SERIAL PRIMARY KEY,
  codigo         VARCHAR(30)  UNIQUE NOT NULL,
  nombre         VARCHAR(100) NOT NULL,
  descripcion    TEXT,
  creado_en      TIMESTAMPTZ  NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en TIMESTAMPTZ           DEFAULT CURRENT_TIMESTAMP
);

-- Insertar 5 tipos canónicos
INSERT INTO tipos_orden (codigo, nombre) VALUES
  ('mesa',      'Orden en mesa'),
  ('delivery',  'Entrega a domicilio'),
  ('recojo',    'Recojo en local'),
  ('qr',        'Pedido por código QR'),
  ('app_movil', 'Pedido desde app móvil')
ON CONFLICT (codigo) DO NOTHING;

-- Agregar columna nueva FK (temporal, nullable para la migración de datos)
ALTER TABLE ordenes ADD COLUMN IF NOT EXISTS id_tipo_orden INT;

-- Migrar datos: mapear string → ID y eliminar columna vieja si aún existe
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name='ordenes' AND column_name='tipo_orden'
  ) THEN
    EXECUTE 'UPDATE ordenes o
    SET id_tipo_orden = t.id_tipo_orden
    FROM tipos_orden t
    WHERE t.codigo = o.tipo_orden';

    IF EXISTS (SELECT 1 FROM ordenes WHERE id_tipo_orden IS NULL) THEN
      RAISE EXCEPTION 'tipos_orden: migración fallida — algunos registros de ordenes tienen id_tipo_orden NULL después del UPDATE.';
    END IF;

    ALTER TABLE ordenes DROP COLUMN tipo_orden;
  END IF;
END $$;

-- Aplicar NOT NULL y FK
ALTER TABLE ordenes DROP CONSTRAINT IF EXISTS fk_ordenes_tipo_orden;
ALTER TABLE ordenes
  ALTER COLUMN id_tipo_orden SET NOT NULL,
  ADD CONSTRAINT fk_ordenes_tipo_orden
    FOREIGN KEY (id_tipo_orden) REFERENCES tipos_orden(id_tipo_orden) ON DELETE RESTRICT;

-- Índice para consultas por tipo
CREATE INDEX IF NOT EXISTS idx_ordenes_tipo_orden ON ordenes(id_tipo_orden);

COMMIT;
