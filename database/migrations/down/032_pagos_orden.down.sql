BEGIN;

-- Reversión: pagos_orden dominio operativo
-- Creada el: 26/05/2026
-- Secuencia: 032

-- Eliminar trigger antes de la tabla
DROP TRIGGER IF EXISTS trg_actualizado_en_pagos_orden ON pagos_orden;

-- Eliminar tabla
DROP TABLE IF EXISTS pagos_orden;

COMMIT;
