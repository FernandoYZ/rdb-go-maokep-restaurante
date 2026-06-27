BEGIN;

-- Reversión de migración 047: eliminar tablas de motivos de notas
-- Orden: primero motivos_nota_debito, luego motivos_nota_credito
-- (no hay dependencias cruzadas entre ellas en esta migración)

DROP TABLE IF EXISTS motivos_nota_debito;
DROP TABLE IF EXISTS motivos_nota_credito;

COMMIT;
