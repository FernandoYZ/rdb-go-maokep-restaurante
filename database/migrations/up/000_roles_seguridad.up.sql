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

-- ============================================================================
-- Permisos para maokep_dueno_esquema (owner - DDL)
-- ============================================================================
ALTER SCHEMA public OWNER TO maokep_dueno_esquema;
GRANT ALL PRIVILEGES ON DATABASE "maokep-restaurante" TO maokep_dueno_esquema;
GRANT USAGE ON SCHEMA public TO maokep_dueno_esquema;

-- Permisos sobre tablas y secuencias existentes
GRANT ALL ON ALL TABLES IN SCHEMA public TO maokep_dueno_esquema;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO maokep_dueno_esquema;

-- Default privileges para tablas/sequences futuras
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
    GRANT ALL ON TABLES TO maokep_dueno_esquema;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
    GRANT ALL ON SEQUENCES TO maokep_dueno_esquema;

-- ============================================================================
-- Permisos para maokep_usuario_app (application user - DML)
-- ============================================================================
ALTER DEFAULT PRIVILEGES FOR ROLE maokep_dueno_esquema IN SCHEMA public
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO maokep_usuario_app;

ALTER DEFAULT PRIVILEGES FOR ROLE maokep_dueno_esquema IN SCHEMA public
    GRANT USAGE, SELECT ON SEQUENCES TO maokep_usuario_app;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO maokep_usuario_app;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
    GRANT USAGE, SELECT ON SEQUENCES TO maokep_usuario_app;

COMMIT;