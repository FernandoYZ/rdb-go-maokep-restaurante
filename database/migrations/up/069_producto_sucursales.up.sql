BEGIN;

-- Migration:  producto_sucursales
-- Created:    2026-06-27
-- Version:    069
--
-- Propósito: Tabla intermedia para anular (override) precios y disponibilidad 
--            de productos por sucursal, permitiendo que cada local maneje sus propios precios.
--            Se incluye id_empresa denormalizado para garantizar un filtrado RLS rápido sin JOINs.

CREATE TABLE IF NOT EXISTS producto_sucursales (
    id_producto    UUID           NOT NULL REFERENCES productos(id_producto) ON DELETE CASCADE,
    id_sucursal    UUID           NOT NULL REFERENCES sucursales(id_sucursal) ON DELETE CASCADE,
    id_empresa     UUID           NOT NULL REFERENCES empresas(id_empresa) ON DELETE CASCADE,
    
    precio_venta   NUMERIC(10,2)  NOT NULL,
    precio_costo   NUMERIC(10,2)  NULL,
    disponible     BOOLEAN        NOT NULL DEFAULT TRUE,
    
    creado_en      TIMESTAMPTZ    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actualizado_en TIMESTAMPTZ    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (id_producto, id_sucursal),
    
    CONSTRAINT chk_producto_sucursales_precio_venta_positive CHECK (precio_venta >= 0),
    CONSTRAINT chk_producto_sucursales_precio_costo_positive CHECK (precio_costo IS NULL OR precio_costo >= 0)
);

-- 1. Trigger para actualizado_en
DROP TRIGGER IF EXISTS trg_actualizado_en_producto_sucursales ON producto_sucursales;
CREATE TRIGGER trg_actualizado_en_producto_sucursales
    BEFORE UPDATE ON producto_sucursales
    FOR EACH ROW EXECUTE FUNCTION establecer_actualizado_en();

-- 2. Habilitar Row Level Security (RLS)
ALTER TABLE producto_sucursales ENABLE ROW LEVEL SECURITY;

CREATE POLICY producto_sucursales_tenant_isolation ON producto_sucursales
    USING (
        id_empresa = current_setting('app.id_empresa', true)::uuid
    )
    WITH CHECK (
        id_empresa = current_setting('app.id_empresa', true)::uuid
    );

-- 3. Índices de rendimiento
CREATE INDEX IF NOT EXISTS idx_producto_sucursales_suc_disp
    ON producto_sucursales(id_sucursal, disponible);

COMMIT;
