# CompuTienda - Sistema transaccional distribuido

Proyecto académico para la asignatura **Sistemas Transaccionales**, semana 6.

Autor: Luis Felipe Diaz Correa  
Docente: Angela Consuelo Rodriguez Gaitan

## Propósito

El proyecto modela una tienda de electrónicos. Garantiza que cada compra descuente inventario, genere la factura y deje la entrega pendiente dentro de una única transacción de MySQL.

## Ejecutar la base de datos

1. Instale Docker Desktop.
2. Desde esta carpeta ejecute `docker compose up -d --build`.
3. Conéctese a `localhost:3307` con el usuario `computienda` y contraseña `computienda2026` (credenciales exclusivas de demostración).
4. Abra `database/transactions.sql` para ejecutar y evidenciar inserciones, actualizaciones, eliminaciones, `BEGIN`, `COMMIT` y `ROLLBACK`.

La inicialización crea la base de datos, las tablas Productos, Clientes, Compras y Facturas, datos de ejemplo, y procedimientos para compra y cancelación.

## Abrir en NetBeans

Abra la carpeta `app/` como proyecto Maven y ejecute `edu.computienda.Main` para consultar el catálogo. Con los argumentos `1 2 1`, compra una unidad del producto 2 para el cliente 1. Configure `DB_URL`, `DB_USER` y `DB_PASSWORD` si cambia la conexión.

El Dockerfile construye la imagen propia `computienda-mysql:semana6` a partir de MySQL 8.4. Los scripts se inicializan únicamente en un volumen nuevo. No elimine un volumen con datos que quiera conservar.

## Estructura

```
database/      Esquema, procedimientos y pruebas de transacciones
app/           Cliente Java Maven compatible con NetBeans
docker-compose.yml  Contenedor MySQL 8.4
```

## Flujo distribuido propuesto

El cliente Java se comunica por JDBC con MySQL en otro proceso o equipo. El servicio de ventas inicia una transacción ACID: bloquea el producto, valida existencias, registra la compra, actualiza inventario y genera una factura con entrega pendiente. Si falla un paso, aplica `ROLLBACK`. El despacho físico requiere actualizar el estado tras comprobar el envío o la recepción. El diseño usa una base transaccional central y no implementa XA ni alta disponibilidad.
