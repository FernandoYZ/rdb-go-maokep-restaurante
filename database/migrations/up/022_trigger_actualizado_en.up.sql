BEGIN;

-- Migración: función y triggers para auto-actualizar actualizado_en
-- Creada el: 26/05/2026 18:20:00
-- Secuencia: 022

-- GAP-13: Función PL/pgSQL para auto-actualizar actualizado_en en BEFORE UPDATE
-- Garantiza que ninguna capa Go pueda olvidar actualizar el timestamp

CREATE OR REPLACE FUNCTION establecer_actualizado_en()
RETURNS TRIGGER AS $$
BEGIN
    NEW.actualizado_en = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers en todas las tablas que tienen columna actualizado_en
-- Orden de creación sigue el orden de las migraciones

CREATE TRIGGER trg_actualizado_en_planes
  BEFORE UPDATE ON planes
  FOR EACH ROW EXECUTE FUNCTION establecer_actualizado_en();

CREATE TRIGGER trg_actualizado_en_planes_periodos
  BEFORE UPDATE ON planes_periodos
  FOR EACH ROW EXECUTE FUNCTION establecer_actualizado_en();

CREATE TRIGGER trg_actualizado_en_empresas
  BEFORE UPDATE ON empresas
  FOR EACH ROW EXECUTE FUNCTION establecer_actualizado_en();

CREATE TRIGGER trg_actualizado_en_pagos
  BEFORE UPDATE ON pagos
  FOR EACH ROW EXECUTE FUNCTION establecer_actualizado_en();

CREATE TRIGGER trg_actualizado_en_roles
  BEFORE UPDATE ON roles
  FOR EACH ROW EXECUTE FUNCTION establecer_actualizado_en();

CREATE TRIGGER trg_actualizado_en_permisos
  BEFORE UPDATE ON permisos
  FOR EACH ROW EXECUTE FUNCTION establecer_actualizado_en();

CREATE TRIGGER trg_actualizado_en_usuarios
  BEFORE UPDATE ON usuarios
  FOR EACH ROW EXECUTE FUNCTION establecer_actualizado_en();

CREATE TRIGGER trg_actualizado_en_configuracion_empresa
  BEFORE UPDATE ON configuracion_empresa
  FOR EACH ROW EXECUTE FUNCTION establecer_actualizado_en();

CREATE TRIGGER trg_actualizado_en_categorias_menu
  BEFORE UPDATE ON categorias_menu
  FOR EACH ROW EXECUTE FUNCTION establecer_actualizado_en();

CREATE TRIGGER trg_actualizado_en_productos
  BEFORE UPDATE ON productos
  FOR EACH ROW EXECUTE FUNCTION establecer_actualizado_en();

CREATE TRIGGER trg_actualizado_en_ordenes
  BEFORE UPDATE ON ordenes
  FOR EACH ROW EXECUTE FUNCTION establecer_actualizado_en();

CREATE TRIGGER trg_actualizado_en_items_orden
  BEFORE UPDATE ON items_orden
  FOR EACH ROW EXECUTE FUNCTION establecer_actualizado_en();

CREATE TRIGGER trg_actualizado_en_vouchers
  BEFORE UPDATE ON vouchers
  FOR EACH ROW EXECUTE FUNCTION establecer_actualizado_en();

CREATE TRIGGER trg_actualizado_en_secuencias_empresa
  BEFORE UPDATE ON secuencias_empresa
  FOR EACH ROW EXECUTE FUNCTION establecer_actualizado_en();

COMMIT;
