BEGIN;

-- Migration:  credenciales_sunat
-- Created:    2026-06-27
-- Version:    067
--
-- Propósito: Tabla aislada por RLS y protegida para almacenar credenciales 
--            de facturación electrónica (usuario/clave SOL y certificados digitales)
--            de cada empresa. Las contraseñas y certificados deben guardarse encriptados
--            desde el backend (ej: AES-256).

CREATE TABLE IF NOT EXISTS credenciales_sunat (
    id_empresa                   UUID         PRIMARY KEY REFERENCES empresas(id_empresa) ON DELETE CASCADE,
    proveedor                    VARCHAR(30)  NOT NULL DEFAULT 'SUNAT',
    usuario_sol_encriptado       TEXT         NULL,
    clave_sol_encriptada         TEXT         NULL,
    certificado_pfx_encriptado   TEXT         NULL,
    clave_certificado_encriptada TEXT         NULL,
    entorno                      VARCHAR(20)  NOT NULL DEFAULT 'sandbox' CHECK (entorno IN ('sandbox', 'produccion')),
    endpoint_url                 TEXT         NULL,
    
    creado_en                    TIMESTAMPTZ  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actualizado_en               TIMESTAMPTZ  NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 1. Trigger para actualizar el campo actualizado_en
DROP TRIGGER IF EXISTS trg_actualizado_en_credenciales_sunat ON credenciales_sunat;
CREATE TRIGGER trg_actualizado_en_credenciales_sunat
    BEFORE UPDATE ON credenciales_sunat
    FOR EACH ROW EXECUTE FUNCTION establecer_actualizado_en();

-- 2. Habilitar Row Level Security (RLS) para proteger los secretos
ALTER TABLE credenciales_sunat ENABLE ROW LEVEL SECURITY;

CREATE POLICY credenciales_sunat_tenant_isolation ON credenciales_sunat
    USING (
        id_empresa = current_setting('app.id_empresa', true)::uuid
    )
    WITH CHECK (
        id_empresa = current_setting('app.id_empresa', true)::uuid
    );

COMMIT;
