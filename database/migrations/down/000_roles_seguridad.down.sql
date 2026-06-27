BEGIN;

-- Desvincular cualquier objeto o permiso otorgado en la base de datos
DROP OWNED BY maokep_usuario_app CASCADE;
DROP OWNED BY maokep_dueno_esquema CASCADE;

-- Revocar privilegios por defecto asignados
ALTER DEFAULT PRIVILEGES FOR ROLE maokep_dueno_esquema IN SCHEMA public 
    REVOKE SELECT, INSERT, UPDATE, DELETE ON TABLES FROM maokep_usuario_app;
ALTER DEFAULT PRIVILEGES FOR ROLE maokep_dueno_esquema IN SCHEMA public 
    REVOKE USAGE, SELECT ON SEQUENCES FROM maokep_usuario_app;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public 
    REVOKE SELECT, INSERT, UPDATE, DELETE ON TABLES FROM maokep_usuario_app;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public 
    REVOKE USAGE, SELECT ON SEQUENCES FROM maokep_usuario_app;

-- Ahora sí se pueden borrar de forma segura
DROP ROLE IF EXISTS maokep_usuario_app;
DROP ROLE IF EXISTS maokep_dueno_esquema;

COMMIT;
