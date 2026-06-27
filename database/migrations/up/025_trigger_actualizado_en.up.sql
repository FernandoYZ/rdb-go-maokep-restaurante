BEGIN;

-- Migración: función y triggers para auto-actualizar actualizado_en
-- Creada el: 26/05/2026 18:20:00
-- Secuencia: 025

-- GAP-13: Función PL/pgSQL para auto-actualizar actualizado_en en BEFORE UPDATE
-- Garantiza que ninguna capa Go pueda olvidar actualizar el timestamp

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.actualizado_en = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers en todas las tablas que tienen columna actualizado_en
-- Orden de creación sigue el orden de las migraciones

CREATE TRIGGER trg_updated_at_planes
  BEFORE UPDATE ON planes
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_updated_at_planes_periodos
  BEFORE UPDATE ON planes_periodos
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_updated_at_empresas
  BEFORE UPDATE ON empresas
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_updated_at_pagos
  BEFORE UPDATE ON pagos
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_updated_at_roles
  BEFORE UPDATE ON roles
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_updated_at_permisos
  BEFORE UPDATE ON permisos
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_updated_at_usuarios
  BEFORE UPDATE ON usuarios
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_updated_at_configuracion_empresa
  BEFORE UPDATE ON configuracion_empresa
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_updated_at_categorias_menu
  BEFORE UPDATE ON categorias_menu
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_updated_at_productos
  BEFORE UPDATE ON productos
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_updated_at_ordenes
  BEFORE UPDATE ON ordenes
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_updated_at_items_orden
  BEFORE UPDATE ON items_orden
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_updated_at_vouchers
  BEFORE UPDATE ON vouchers
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

COMMIT;
