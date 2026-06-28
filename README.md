# Maokep Restaurante - Capa de Persistencia

> [!NOTE]
> Este repositorio está dedicado exclusivamente a la definición, arquitectura, políticas de aislamiento y utilitarios de migración de la base de datos PostgreSQL 17 para el ecosistema Maokep.

## Características de la Base de Datos

* **Aislamiento Multi-Tenant (RLS):** Garantía de seguridad lógica absoluta mediante **Row Level Security** en todas las tablas transaccionales en base a la variable de sesión `app.id_empresa`. Las tablas de detalles y auditoría se protegen mediante subconsultas cruzadas `EXISTS`.
* **Inmutabilidad Fiscal:** Triggers integrados a nivel relacional que bloquean modificaciones (`UPDATE`/`DELETE`) en los detalles de facturación (`comprobante_detalles`, `notas_credito_detalles`, `notas_debito_detalles`). La cabecera `comprobantes` congela sus datos fiscales en el motor una vez emitida.
* **Integridad y Consistencia Financiera:** Restricciones de no-negativos (`CHECK >= 0`) aplicadas a precios, inventarios, cobros y vuelto. La tabla `pagos_orden` cuenta con una validación matemática relacional que exige que el vuelto sea exactamente la diferencia entre el monto recibido y el monto cobrado.
* **Asignación Atómica de Correlativos:** Función de asignación de numeración electrónica SUNAT mediante bloqueos exclusivos de fila (`UPDATE ... RETURNING`), libre de condiciones de carrera (TOCTOU).
* **Logs de Auditoría:** Log centralizado (`registros_auditoria`) que registra diferencias de estados anteriores y nuevos en formato JSONB.

---

## 🗃️ Módulos y Tablas Implementadas

La base de datos se organiza en los siguientes dominios de negocio:

### 1. Core SaaS & Facturación
Gestiona los planes de suscripción de la plataforma, el catálogo de periodos comerciales, el registro principal de inquilinos (empresas/tenants) y transacciones de pago de membresía.
* **Tablas:** `planes`, `planes_periodos`, `empresas`, `suscripciones`, `pagos`, `estados_empresa`, `estados_suscripcion`, `estados_pago`, `metodos_pago`.

### 2. Identidad y Accesos (RBAC & Sesiones)
Controla la autenticación, los roles, permisos granulares, asignación multi-tenant de usuarios y trazabilidad de eventos de sesión.
* **Tablas:** `usuarios`, `roles`, `permisos`, `rol_permisos`, `usuario_roles`, `sesiones`, `session_events`.

### 3. Configuración y Menú (Productos e Inventario)
Estructura la parametrización de locales, categorías de menú y catálogo de productos con soporte para precios y stock diferenciado por sucursal.
* **Tablas:** `configuracion_empresa`, `categorias_menu`, `productos`, `producto_sucursales`, `stock_sucursal`.

### 4. Operaciones POS (Ventas y Cajas)
Registra las sucursales del restaurante, apertura y cierres diarios de turnos de caja, comandas y flujos de egresos/ingresos operativos.
* **Tablas:** `sucursales`, `usuario_sucursales`, `ordenes`, `items_orden`, `tipos_orden`, `estados_orden`, `secuencias_empresa`, `aperturas_caja`, `movimientos_caja`, `estados_caja`, `tipos_movimiento_caja`, `pagos_orden`.

### 5. Facturación Electrónica SUNAT
Gestiona la emisión de Facturas, Boletas, Notas de Crédito, Notas de Débito, catálogos de códigos SUNAT y el registro append-only de intentos de envío y CDRs.
* **Tablas:** `comprobantes`, `comprobante_detalles`, `series_comprobante`, `envios_sunat`, `ordenes_comprobantes`, `notas_credito`, `notas_credito_detalles`, `notas_debito`, `notas_debito_detalles`, `tipos_comprobante`, `estados_comprobante`, `estados_operacionales`, `estados_nota`, `motivos_nota_credito`, `motivos_nota_debito`, `credenciales_sunat`, `clientes`, `tipos_documento_fiscal`.

---

## 🛠️ Utilidad CLI de Gestión (`maokep`)

El CLI está escrito en Go y cuenta con un comportamiento **híbrido** gobernado por la variable de entorno `APP_ENV` para facilitar tanto el desarrollo local como el despliegue atómico en producción (VPS).

### Configuración del Entorno (`APP_ENV`)

| Valor de `APP_ENV` | Origen de los archivos SQL | Caso de Uso |
| :--- | :--- | :--- |
| **`development`** (Default) | Directorio físico local (`database/migrations/`). | Desarrollo local: podés modificar scripts SQL en caliente y correr `make migrate` sin recompilar. |
| **`production`** | Memoria interna del binario (**`embed.FS`**). | Producción en VPS: no necesitás copiar ninguna carpeta SQL al servidor. El binario ejecuta las migraciones de forma autocontenida. |

### Comandos del Entorno (Makefile)

* `make build`: Compila el ejecutable independiente en `bin/maokep`.
* `make up`: Levanta el contenedor Postgres y ejecuta las migraciones pendientes.
* `make status`: Muestra la tabla de migraciones aplicadas vs pendientes leídas desde `migraciones_esquema`.
* `make migrate`: Ejecuta todas las migraciones SQL pendientes.
* `make rollback`: Revierte la última migración aplicada en la base de datos.
* `make reset`: Destruye el esquema (DROP CASCADE) y lo reconstruye desde cero.
* `make migration name=<nombre>`: Crea una plantilla de migración SQL atómica up/down.
