# Maokep - Saas POS para Restaurantes
Sistema SaaS multiempresa para restaurantes.

## Objetivo
- Gestión de ventas
- Gestión de pedidos
- Control de mesas
- Inventario
- Caja
- Usuarios y roles
- Reportes operativos

## Arquitectura

### Arquitectura del sistema
Monolito modular

### Backend
- Go 1.26.0
- net/http
- ServeMux
- PostgreSQL 17
- SSE (Server-Sent Events)
- LISTEN/NOTIFY

### Infraestructura
- Podman
- Podman compose

### Principios

- Multi-tenant por empresa
- RLS (Row Level Security)
- Arquitectura modular
- Event-driven para notificaciones en tiempo real
- Sin dependencias innecesarias

### Módulos:
- auth
- empresas
- usuarios
- productos
- inventario
- pedidos
- ventas
- caja
- reportes
- facturacion
- por definir...

## Estructura del proyecto

```text
cmd/
internal/
    modules/
        auth/
        empresas/
        usuarios/
        productos/
        inventario/
        pedidos/
        ventas/
        caja/
        reportes/
scripts/
docs/
```

## Estado actual

- [ ] Diseño de base de datos - proceso
- [ ] Configuración inicial backend - pendiente
- [ ] Autenticación - pendiente
- [ ] Catálogo productos - pendiente
- [ ] Inventario - pendiente
- [ ] Ventas - pendiente