# Base de Datos

La base de datos es el núcleo del sistema Maokep.

Su responsabilidad es garantizar:

- Aislamiento de empresas (multi-tenant).
- Integridad transaccional.
- Consistencia de inventario.
- Auditoría de operaciones.
- Comunicación en tiempo real mediante PostgreSQL LISTEN/NOTIFY.

Gestor utilizado:

- PostgreSQL 17

---

# Principios de Diseño

## Multi-Tenant

Cada registro de negocio pertenece a una empresa.

Ejemplos:

- productos
- pedidos
- ventas
- movimientos_stock
- usuarios

Patrón general:

```sql
id_empresa UUID NOT NULL
```

---

## Seguridad

Se utilizará Row Level Security (RLS).

Objetivo:

- Evitar fugas de información entre empresas.
- Centralizar el aislamiento de tenants en PostgreSQL.

Contexto esperado por conexión:

```sql
SET LOCAL app.id_empresa = '<uuid>';
```

---

## Integridad

Todas las operaciones críticas deberán ejecutarse dentro de transacciones.

Casos:

- Crear venta
- Descontar stock
- Registrar movimiento de caja
- Crear pedido

---

## Trazabilidad

Toda modificación importante deberá generar historial.

Ejemplos:

- movimientos_stock
- movimientos_caja
- auditoría de usuarios

No se permitirá perder trazabilidad de operaciones críticas.

---

# Estrategia de IDs

Se utilizarán UUIDs.

Ejemplo:

```sql
id UUID PRIMARY KEY
```

Motivos:

- Compatibilidad SaaS.
- Evitar enumeración de registros.
- Mejor integración entre servicios futuros.

---

# Organización por Dominios

La base de datos se divide en módulos.

## Core

- empresas
- usuarios
- roles
- permisos

## Catálogo

- categorias
- productos

## Inventario

- inventario
- movimientos_stock

## Operación

- mesas
- pedidos
- pedido_detalles

## Ventas

- ventas
- venta_detalles

## Caja

- cajas
- movimientos_caja

## Reportes

- vistas materializadas
- métricas operativas

---

# Convenciones

## Nombres

Tablas:

```text
snake_case
plural
```

Ejemplos:

- usuarios
- productos
- ventas

Columnas:

```text
snake_case
```

Ejemplos:

- fecha_creacion
- fecha_actualizacion
- id_empresa

---

## Fechas

Todas las fechas se almacenan en UTC.

Tipo:

```sql
TIMESTAMPTZ
```

---

## Soft Delete

No se eliminarán registros críticos.

Patrón:

```sql
activo BOOLEAN DEFAULT TRUE
```

o

```sql
eliminado_en TIMESTAMPTZ
```

según el caso de uso.

---

# Tiempo Real

Se utilizará PostgreSQL LISTEN/NOTIFY.

Objetivos:

- Actualización de pedidos.
- Actualización de mesas.
- Actualización de caja.
- Eventos de inventario.

Ejemplo conceptual:

```sql
NOTIFY pedido_creado;
```

Consumido por:

- Backend Go
- SSE

---

# Rendimiento

## Índices

Regla general:

Toda búsqueda frecuente debe tener índice.

Ejemplos:

```sql
id_empresa
estado
fecha_creacion
```

---

## Consultas

Se priorizarán:

- consultas simples
- índices compuestos
- evitar joins innecesarios

---

# Respaldo y Recuperación

Pendiente definir.

Posibles estrategias:

- pg_dump
- Backups automáticos diarios
- PITR (Point In Time Recovery)

---

# Estado Actual

## Diseño

- [ ] Modelo multi-tenant definido
- [ ] Uso de UUID definido
- [ ] Uso de RLS definido
- [ ] Uso de LISTEN/NOTIFY definido

## Pendiente

- [ ] Modelo físico
- [ ] Diagrama ER
- [ ] Índices
- [ ] Políticas RLS
- [ ] Estrategia de backups