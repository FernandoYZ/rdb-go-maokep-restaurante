BEGIN;

-- Reversión: registros_auditoria
-- Creada el: 26/05/2026 00:31:53
-- Secuencia: 021

-- Remover triggers asociados
DROP TRIGGER IF EXISTS trg_auditar_usuarios ON usuarios;
DROP TRIGGER IF EXISTS trg_auditar_roles ON roles;
DROP TRIGGER IF EXISTS trg_auditar_configuracion_empresa ON configuracion_empresa;
DROP TRIGGER IF EXISTS trg_auditar_productos ON productos;

-- Remover función
DROP FUNCTION IF EXISTS auditar_registro();

-- Remover tabla
DROP TABLE IF EXISTS registros_auditoria;

-- Remover ENUM
DROP TYPE IF EXISTS tipo_operacion_auditoria;

COMMIT;
