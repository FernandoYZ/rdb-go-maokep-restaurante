# Maokep Restaurante Database

> [!NOTE]
> Este repositorio contiene exclusivamente la capa de persistencia del ecosistema Maokep: esquema relacional, migraciones, funciones, políticas RLS y utilidades operativas para PostgreSQL 17.

Base de datos PostgreSQL 17 para el ecosistema Maokep Restaurante.

---

## Arquitectura

* PostgreSQL 17
* Multi-tenancy mediante Row Level Security
* Migraciones SQL versionadas
* Auditoría basada en JSONB
* Integridad financiera a nivel del motor
* Facturación electrónica SUNAT
* CLI de administración en Go

> [!IMPORTANT]
> La lógica crítica de negocio se implementa dentro de PostgreSQL para garantizar consistencia independientemente de la aplicación consumidora.

---

## Multi-Tenancy

Las tablas transaccionales utilizan Row Level Security (RLS).

```sql
SET LOCAL app.id_empresa = '<uuid>';
```

> [!CAUTION]
> Las consultas ejecutadas sin establecer `app.id_empresa` pueden ser rechazadas por las políticas RLS o devolver resultados vacíos.

---

## Inmutabilidad Fiscal

Los documentos emitidos son inmutables.

* Sin UPDATE.
* Sin DELETE.
* Congelamiento de datos fiscales.
* Protección mediante triggers.

Tablas protegidas:

* `comprobante_detalles`
* `notas_credito_detalles`
* `notas_debito_detalles`

> [!WARNING]
> Cualquier modificación manual de información tributaria fuera de las funciones autorizadas puede comprometer la trazabilidad fiscal del sistema.

---

## Integridad Financiera

Las validaciones financieras se ejecutan dentro del motor.

* Montos no negativos.
* Inventarios no negativos.
* Validación de vuelto.
* Restricciones contables.

```text
vuelto = monto_recibido - monto_cobrado
```

---

## Numeración Electrónica

Los correlativos SUNAT se asignan mediante:

```sql
UPDATE ... RETURNING
```

> [!TIP]
> El uso de bloqueos de fila elimina condiciones de carrera durante la generación concurrente de comprobantes.

---

## Auditoría

La tabla `registros_auditoria` almacena:

* Estado anterior.
* Estado nuevo.
* Usuario.
* Fecha.
* Operación.

Formato:

```text
JSONB
```

---

## Dominios del Sistema

### SaaS Core

* `empresas`
* `planes`
* `suscripciones`
* `pagos`

### IAM (Identity & Access Management)

* `usuarios`
* `roles`
* `permisos`
* `sesiones`

### Catálogo e Inventario

* `productos`
* `categorias_menu`
* `stock_sucursal`

### POS

* `ordenes`
* `pagos_orden`
* `aperturas_caja`
* `movimientos_caja`

### Facturación Electrónica

* `comprobantes`
* `envios_sunat`
* `notas_credito`
* `notas_debito`

---

## CLI `maokep`

> [!NOTE]
> El CLI funciona tanto en desarrollo como en producción utilizando un sistema híbrido de migraciones.

| APP_ENV     | Origen SQL          | Uso              |
| ----------- | ------------------- | ---------------- |
| development | Sistema de archivos | Desarrollo local |
| production  | embed.FS            | Producción       |

---

## Comandos

| Comando         | Descripción                  |
| --------------- | ---------------------------- |
| `make build`    | Compila el CLI               |
| `make up`       | Levanta PostgreSQL y migra   |
| `make migrate`  | Ejecuta migraciones          |
| `make rollback` | Revierte la última migración |
| `make status`   | Estado de migraciones        |
| `make reset`    | Reconstruye el esquema       |

---

## Garantías del Sistema

> [!IMPORTANT]
> La base de datos constituye la principal barrera de seguridad y consistencia del sistema.

* Aislamiento multi-tenant.
* Inmutabilidad fiscal.
* Integridad financiera.
* Auditoría estructurada.
* Migraciones reproducibles.
* Consistencia concurrente.

---

## Requisitos

* Go 1.25+
* GNU Make
* Podman

---

## Licencia

Propiedad del proyecto Maokep Restaurante.
