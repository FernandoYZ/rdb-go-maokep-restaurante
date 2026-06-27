BEGIN;

-- Migración: consolidación de triggers actualizado_en
-- Creada el: 26/05/2026
-- Secuencia: 023
--
-- Propósito: eliminar la función set_updated_at() y sus triggers trg_updated_at_*
-- introducidos por la migración 025. La función establecer_actualizado_en() (migración 022)
-- ya cubre todas las tablas existentes. Esta migración elimina la duplicidad.

-- Eliminar triggers duplicados de set_updated_at (de la migración 025)
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

-- Eliminar función duplicada set_updated_at()
-- establecer_actualizado_en() (022) permanece intacta
DROP FUNCTION IF EXISTS set_updated_at();

COMMIT;
