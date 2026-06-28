BEGIN;

-- Revocar permisos de maokep_dueno_esquema
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM maokep_dueno_esquema;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM maokep_dueno_esquema;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA public FROM maokep_dueno_esquema;

-- Revocar permisos de maokep_usuario_app
REVOKE SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public FROM maokep_usuario_app;
REVOKE USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public FROM maokep_usuario_app;
REVOKE EXECUTE ON ALL FUNCTIONS IN SCHEMA public FROM maokep_usuario_app;

COMMIT;
