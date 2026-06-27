BEGIN;

-- Reversión: función y triggers para auto-actualizar actualizado_en
-- Creada el: 26/05/2026 18:20:00
-- Secuencia: 022

-- Eliminar triggers en orden inverso (por coherencia, aunque no es obligatorio)
DROP TRIGGER IF EXISTS trg_actualizado_en_vouchers ON vouchers;
DROP TRIGGER IF EXISTS trg_actualizado_en_items_orden ON items_orden;
DROP TRIGGER IF EXISTS trg_actualizado_en_ordenes ON ordenes;
DROP TRIGGER IF EXISTS trg_actualizado_en_productos ON productos;
DROP TRIGGER IF EXISTS trg_actualizado_en_categorias_menu ON categorias_menu;
DROP TRIGGER IF EXISTS trg_actualizado_en_configuracion_empresa ON configuracion_empresa;
DROP TRIGGER IF EXISTS trg_actualizado_en_usuarios ON usuarios;
DROP TRIGGER IF EXISTS trg_actualizado_en_permisos ON permisos;
DROP TRIGGER IF EXISTS trg_actualizado_en_roles ON roles;
DROP TRIGGER IF EXISTS trg_actualizado_en_pagos ON pagos;
DROP TRIGGER IF EXISTS trg_actualizado_en_empresas ON empresas;
DROP TRIGGER IF EXISTS trg_actualizado_en_planes_periodos ON planes_periodos;
DROP TRIGGER IF EXISTS trg_actualizado_en_planes ON planes;

-- Eliminar función
DROP FUNCTION IF EXISTS establecer_actualizado_en();

COMMIT;
