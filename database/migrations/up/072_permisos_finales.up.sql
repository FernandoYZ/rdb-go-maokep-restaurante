BEGIN;

-- Migración: permisos finales
-- Creada el: 2026-06-27
-- Versión: 072
--
-- Propósito: aplicar permisos sobre TODOS los objetos creados en migraciones 001-071
-- Debe ejecutarse DESPUÉS de que todas las tablas, vistas, sequences, funciones existan

-- ============================================================================
-- Permisos sobre tablas existentes para maokep_dueno_esquema
-- ============================================================================
GRANT ALL ON ALL TABLES IN SCHEMA public TO maokep_dueno_esquema;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO maokep_dueno_esquema;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO maokep_dueno_esquema;

-- ============================================================================
-- Permisos sobre tablas existentes para maokep_usuario_app (DML only)
-- ============================================================================
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO maokep_usuario_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO maokep_usuario_app;

-- Ejecutar funciones si es necesario para la aplicación
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO maokep_usuario_app;

COMMIT;
