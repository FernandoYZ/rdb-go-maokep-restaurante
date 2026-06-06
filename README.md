# Maokep Restaurante - Base de Datos

> [!NOTE]
> Este repositorio está dedicado exclusivamente a la capa de persistencia y gestión de infraestructura de base de datos para el ecosistema Maokep.

## Objetivo
Centralizar la definición, migraciones e infraestructura de la base de datos PostgreSQL, gestionada mediante contenedores.

## Tecnologías e Infraestructura
- **PostgreSQL 17**
- **Podman** (Contenedorización)
- **Podman Compose** (Orquestación local)
- **Make** (Automatización de tareas)

## Arquitectura de Datos

> [!IMPORTANT]
> El diseño sigue un modelo **Multi-tenant** estricto para garantizar la privacidad y seguridad de los datos entre diferentes restaurantes.

- **Aislamiento**: Implementado mediante **Row Level Security (RLS)** basado en el parámetro `app.id_empresa`.
- **Diseño Modular**: Organización por dominios de negocio para escalabilidad.
- **Robustez Financiera**: Snapshots inmutables de productos/precios en órdenes y comprobantes para auditoría tributaria.
- **Auditoría**: Soft deletes, trazabilidad completa y triggers de actualización automática de timestamps.

> [!WARNING]
> **Requisito de Middleware**: El uso de RLS requiere que el backend (Go) ejecute `SET LOCAL app.id_empresa = <UUID>` al inicio de cada transacción. Sin esto, las consultas no retornarán resultados.

## Roadmap de Desarrollo (Fases)

### Fase 1-3: Core & POS Operativo
- [x] **Infraestructura**: Setup de Podman y automatización con Make.
- [x] **Billing SaaS**: Planes, suscripciones y gestión de empresas.
- [ ] **RBAC (Control de Acceso)**: Roles, permisos y usuarios multi-tenant.
- [ ] **Catálogo & Menú**: Categorías y productos con soporte para soft-delete.
- [ ] **Órdenes & Caja**: Flujo completo de pedidos, movimientos de caja y arqueos.
- [ ] **RLS Enforcement**: Políticas de seguridad a nivel de fila para aislamiento de datos.

### Fase 4-6: Facturación Electrónica (SUNAT)
- [ ] **Comprobantes**: Series, numeración y registro de facturas/boletas.
- [ ] **Notas de Crédito/Débito**: Gestión de rectificaciones y motivos SUNAT.
- [ ] **Atomicidad**: Correlativos atómicos mediante PL/pgSQL y soporte para idempotencia.

### Fase 7-8: Escalabilidad & Safeguards
- [ ] **Multi-Sucursal**: Soporte para múltiples sedes por empresa y roles por sucursal.
- [ ] **Seguridad Financiera**: Constraints de valores positivos y triggers de inmutabilidad en históricos.
- [ ] **Real-time**: Infraestructura LISTEN/NOTIFY para invalidación de sesiones en tiempo real.

## Estructura del Proyecto
```text
database/
    migrations/     # Scripts SQL (up/down) numerados por fase
    ARCHITECTURE.md  # Resumen modular del diseño
SCHEMA.md           # Especificación técnica detallada (Referencia)
docs/               # Documentación adicional
scripts/            # Automatización en Bash
compose.yml         # Orquestación de PostgreSQL
Makefile            # Comandos de gestión rápida
```

## Comandos Rápidos

> [!TIP]
> Si es tu primera vez en el proyecto, ejecuta `make help` para ver una descripción detallada de cada comando y sus parámetros.

- `make up`: Levanta el entorno con Podman.
- `make reset`: Limpia la DB y re-ejecuta todas las migraciones.
- `make migration <nombre>`: Genera un nuevo par de migraciones (up/down).
- `make help`: Muestra ayuda sobre los comandos disponibles.
