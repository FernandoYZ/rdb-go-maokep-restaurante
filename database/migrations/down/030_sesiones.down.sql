BEGIN;

-- Reversión: sesiones con refresh tokens y revocación
-- Creada el: 26/05/2026
-- Secuencia: 030

-- Eliminar trigger antes de la tabla
DROP TRIGGER IF EXISTS trg_actualizado_en_sesiones ON sesiones;

-- Eliminar tabla
DROP TABLE IF EXISTS sesiones;

COMMIT;
