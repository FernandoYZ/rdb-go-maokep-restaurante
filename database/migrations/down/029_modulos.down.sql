BEGIN;

-- Reversión: módulos, plan_modulos, plan_limites
-- Creada el: 26/05/2026
-- Secuencia: 029

-- Eliminar triggers antes de las tablas
DROP TRIGGER IF EXISTS trg_actualizado_en_plan_limites ON plan_limites;
DROP TRIGGER IF EXISTS trg_actualizado_en_modulos ON modulos;

-- Eliminar tablas en orden de dependencias (hijas primero)
DROP TABLE IF EXISTS plan_limites;
DROP TABLE IF EXISTS plan_modulos;
DROP TABLE IF EXISTS modulos;

COMMIT;
