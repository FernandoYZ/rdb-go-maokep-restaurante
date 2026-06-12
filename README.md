# Maokep Restaurante - Base de Datos

> [!NOTE]
> Este repositorio está dedicado exclusivamente a la capa de persistencia y gestión de infraestructura de base de datos para el ecosistema Maokep.

## Objetivo
Centralizar la definición, migraciones e infraestructura de la base de datos PostgreSQL, gestionada mediante contenedores.

## Tecnologías e Infraestructura
- **PostgreSQL 17** (Motor de base de datos)
- **Go** (Herramientas de gestión y migraciones)
- **Podman / Compose** (Contenedorización y orquestación)
- **Make / Bash** (Automatización de tareas y UI de consola)

## Arquitectura de Datos

> [!IMPORTANT]
> El diseño sigue un modelo **Multi-tenant** estricto para garantizar la privacidad y seguridad de los datos entre diferentes restaurantes.

- **Aislamiento**: Implementado mediante **Row Level Security (RLS)** basado en el parámetro `app.id_empresa`.
- **Seguridad de Red**: Acceso restringido a `localhost` en el contenedor para entornos VPS.
- **Performance**: PostgreSQL optimizado mediante parámetros de memoria (`shared_buffers`, `work_mem`).
- **Diseño Modular**: Organización por dominios de negocio para escalabilidad.
- **Auditoría**: Soft deletes, trazabilidad completa y triggers de actualización automática.

## Roadmap de Desarrollo (Fases)

### Fase 1-3: Core & POS Operativo
- [x] **Infraestructura**: Setup de Podman, automatización y herramientas CLI (Go).
- [x] **Billing SaaS**: Planes, suscripciones y gestión de empresas.
- [x] **RBAC (Control de Acceso)**: Roles, permisos y usuarios multi-tenant.
- [x] **Catálogo & Menú**: Categorías y productos con soporte para soft-delete.
- [ ] **Órdenes & Caja**: Flujo completo de pedidos, movimientos de caja y arqueos.
- [ ] **RLS Enforcement**: Políticas de seguridad a nivel de fila para aislamiento de datos.

### Fase 4-6: Facturación Electrónica (SUNAT)
- [ ] **Comprobantes**: Series, numeración y registro de facturas/boletas.
- [ ] **Notas de Crédito/Débito**: Gestión de rectificaciones y motivos SUNAT.
- [ ] **Atomicidad**: Correlativos atómicos e idempotencia.

## Estructura del Proyecto
```text
├── cmd/cli/        # Punto de entrada de la herramienta de gestión (Go)
├── internal/       # Lógica modular (Console, Database, Config)
├── database/       # Definición de esquemas, arquitectura y migraciones
├── scripts/        # Scripts auxiliares de automatización (Bash)
├── compose.yml     # Orquestación de infraestructura (PostgreSQL 17)
└── Makefile        # Interfaz unificada de comandos (Single Source of Truth)
```

## Comandos Rápidos

- `make up`: Levanta el entorno y asegura conectividad.
- `make status`: Muestra el estado actual de las migraciones (Pendientes vs Aplicadas).
- `make migrate`: Ejecuta todas las migraciones pendientes.
- `make reset`: Limpia la DB y re-ejecuta todo desde cero.
- `make migration <nombre>`: Genera un par de archivos SQL (up/down).
- `make help`: Muestra ayuda detallada sobre todos los comandos.
