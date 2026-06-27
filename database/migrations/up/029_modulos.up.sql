BEGIN;

-- Migración: módulos, plan_modulos, plan_limites
-- Creada el: 26/05/2026
-- Secuencia: 029
--
-- Propósito: definir el catálogo de módulos funcionales del sistema y permitir
-- que cada plan habilite un subconjunto de módulos con límites configurables.

-- Tabla de catálogo de módulos del sistema
CREATE TABLE modulos (
    id_modulo   INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo      VARCHAR(50) UNIQUE NOT NULL,
    nombre      VARCHAR(100) NOT NULL,
    descripcion TEXT,
    activo      BOOLEAN NOT NULL DEFAULT TRUE,

    creado_en     TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actualizado_en TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX uk_modulos_codigo ON modulos (codigo);

-- Tabla pivot plan ↔ módulo (qué módulos activa cada plan)
CREATE TABLE plan_modulos (
    id_plan    INT NOT NULL REFERENCES planes(id_plan) ON DELETE CASCADE,
    id_modulo  INT NOT NULL REFERENCES modulos(id_modulo) ON DELETE CASCADE,

    creado_en  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id_plan, id_modulo)
);

-- Tabla de límites numéricos/texto/booleanos por plan y módulo
CREATE TABLE plan_limites (
    id_limite        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_plan          INT NOT NULL REFERENCES planes(id_plan) ON DELETE CASCADE,
    id_modulo        INT REFERENCES modulos(id_modulo) ON DELETE CASCADE,
    tipo_limite      VARCHAR(100) NOT NULL,
    tipo_valor       VARCHAR(20) NOT NULL CHECK (tipo_valor IN ('numero', 'texto', 'booleano')),

    valor_numero     NUMERIC,
    valor_texto      VARCHAR(255),
    valor_booleano   BOOLEAN,

    creado_en        TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actualizado_en   TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    UNIQUE (id_plan, id_modulo, tipo_limite),

    -- Exactamente un valor debe ser no nulo (los otros dos deben ser NULL)
    CONSTRAINT chk_plan_limites_valor_unico CHECK (
        (valor_numero IS NOT NULL)::int +
        (valor_texto IS NOT NULL)::int +
        (valor_booleano IS NOT NULL)::int = 1
    )
);

-- Triggers para auto-actualizar actualizado_en
CREATE TRIGGER trg_actualizado_en_modulos
  BEFORE UPDATE ON modulos
  FOR EACH ROW EXECUTE FUNCTION establecer_actualizado_en();

CREATE TRIGGER trg_actualizado_en_plan_limites
  BEFORE UPDATE ON plan_limites
  FOR EACH ROW EXECUTE FUNCTION establecer_actualizado_en();

-- Módulos base del sistema
INSERT INTO modulos (codigo, nombre, descripcion) VALUES
    ('inventario',          'Inventario',           'Gestión de ingredientes y stock'),
    ('delivery',            'Delivery',             'Pedidos y despacho a domicilio'),
    ('reportes_avanzados',  'Reportes avanzados',   'Análisis y exportación de datos'),
    ('cocina',              'Cocina',               'Panel de comandas para cocina (KDS)'),
    ('multiusuario',        'Multi-usuario',        'Gestión de múltiples usuarios por empresa'),
    ('qr',                  'Menú QR',              'Carta digital con código QR para mesas'),
    ('caja',                'Caja',                 'Apertura/cierre de caja y arqueo'),
    ('facturacion_electronica', 'Facturación Electrónica', 'Módulo de emisión de comprobantes electrónicos a través de SUNAT/OSE')
ON CONFLICT (codigo) DO NOTHING;

-- Tabla de add-ons (módulos adquiridos individualmente por la empresa)
CREATE TABLE IF NOT EXISTS empresa_modulos (
    id_empresa  UUID        NOT NULL REFERENCES empresas(id_empresa) ON DELETE CASCADE,
    id_modulo   INT         NOT NULL REFERENCES modulos(id_modulo) ON DELETE CASCADE,
    activo      BOOLEAN     NOT NULL DEFAULT TRUE,
    adquirido_en TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    creado_en   TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actualizado_en TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (id_empresa, id_modulo)
);

-- Trigger para auto-actualizar actualizado_en
CREATE TRIGGER trg_actualizado_en_empresa_modulos
    BEFORE UPDATE ON empresa_modulos
    FOR EACH ROW EXECUTE FUNCTION establecer_actualizado_en();

-- Habilitar Row Level Security (RLS) para proteger los datos por tenant
ALTER TABLE empresa_modulos ENABLE ROW LEVEL SECURITY;

CREATE POLICY empresa_modulos_tenant_isolation ON empresa_modulos
    USING (
        id_empresa = current_setting('app.id_empresa', true)::uuid
    )
    WITH CHECK (
        id_empresa = current_setting('app.id_empresa', true)::uuid
    );

COMMIT;
