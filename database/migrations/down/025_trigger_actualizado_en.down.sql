BEGIN;

-- Reversión: función y triggers para auto-actualizar actualizado_en
-- Creada el: 26/05/2026 18:20:00
-- Secuencia: 025

-- Eliminar triggers en orden inverso (por coherencia, aunque no es obligatorio)
DROP TRIGGER IF EXISTS trg_updated_at_vouchers ON vouchers;
DROP TRIGGER IF EXISTS trg_updated_at_items_orden ON items_orden;
DROP TRIGGER IF EXISTS trg_updated_at_ordenes ON ordenes;
DROP TRIGGER IF EXISTS trg_updated_at_productos ON productos;
DROP TRIGGER IF EXISTS trg_updated_at_categorias_menu ON categorias_menu;
DROP TRIGGER IF EXISTS trg_updated_at_configuracion_empresa ON configuracion_empresa;
DROP TRIGGER IF EXISTS trg_updated_at_usuarios ON usuarios;
DROP TRIGGER IF EXISTS trg_updated_at_permisos ON permisos;
DROP TRIGGER IF EXISTS trg_updated_at_roles ON roles;
DROP TRIGGER IF EXISTS trg_updated_at_pagos ON pagos;
DROP TRIGGER IF EXISTS trg_updated_at_empresas ON empresas;
DROP TRIGGER IF EXISTS trg_updated_at_planes_periodos ON planes_periodos;
DROP TRIGGER IF EXISTS trg_updated_at_planes ON planes;

-- Eliminar función
DROP FUNCTION IF EXISTS set_updated_at();

COMMIT;
