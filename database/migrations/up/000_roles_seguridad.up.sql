BEGIN;

-- Roles de Seguridad (Capa de Ciberseguridad)
-- Propósito: Aislamiento de privilegios y principio de menor privilegio.

DO $$
BEGIN
    -- Go reemplazará {OWNER_PASS} y {APP_PASS} con los valores reales del .env antes de ejecutar
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'maokep_dueno_esquema') THEN
        CREATE ROLE maokep_dueno_esquema WITH LOGIN PASSWORD '{OWNER_PASS}';
    END IF;

    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'maokep_usuario_app') THEN
        CREATE ROLE maokep_usuario_app WITH LOGIN PASSWORD '{APP_PASS}';
    END IF;
END
$$;

-- Permisos (El resto queda exactamente igual como lo hiciste)
ALTER SCHEMA public OWNER TO maokep_dueno_esquema;
GRANT ALL PRIVILEGES ON DATABASE "maokep-restaurante" TO maokep_dueno_esquema;

ALTER DEFAULT PRIVILEGES FOR ROLE maokep_dueno_esquema IN SCHEMA public 
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO maokep_usuario_app;

ALTER DEFAULT PRIVILEGES FOR ROLE maokep_dueno_esquema IN SCHEMA public 
    GRANT USAGE, SELECT ON SEQUENCES TO maokep_usuario_app;

-- Otorgar default privileges para el rol postgres (que corre las migraciones locales)
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public 
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO maokep_usuario_app;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public 
    GRANT USAGE, SELECT ON SEQUENCES TO maokep_usuario_app;

COMMIT;