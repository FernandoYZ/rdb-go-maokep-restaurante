BEGIN;

-- Reversión: sucursales y usuario_sucursales multi-sede
-- Creada el: 26/05/2026
-- Secuencia: 031

-- Eliminar trigger antes de las tablas
DROP TRIGGER IF EXISTS trg_actualizado_en_sucursales ON sucursales;

-- Eliminar tablas en orden de dependencias (hija primero)
DROP TABLE IF EXISTS usuario_sucursales;
DROP TABLE IF EXISTS sucursales;

COMMIT;
