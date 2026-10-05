USE computienda;

-- INSERCIÓN Y COMMIT: compra, descuento de inventario y factura.
BEGIN;
INSERT INTO Compras (id_cliente, codigo_producto, cantidad_comprada, precio_unitario)
SELECT 1, codigo_producto, 1, precio_venta FROM Productos WHERE codigo_producto = 2;
SET @compra_id = LAST_INSERT_ID();
UPDATE Productos SET cantidad_inventario = cantidad_inventario - 1 WHERE codigo_producto = 2 AND cantidad_inventario >= 1;
INSERT INTO Facturas (id_compra, nombre_cliente, id_cliente, codigo_producto, cantidad_comprada, precio_unitario, total_factura)
SELECT @compra_id, 'Ana Torres', 1, codigo_producto, 1, precio_venta, precio_venta FROM Productos WHERE codigo_producto = 2;
COMMIT;

-- ACTUALIZACIÓN Y ROLLBACK: prueba que no altera el precio definitivo.
BEGIN;
UPDATE Productos SET precio_venta = precio_venta * 0.90 WHERE codigo_producto = 3;
ROLLBACK;

-- ELIMINACIÓN Y ROLLBACK: elimina un registro real sin dependencias.
BEGIN;
INSERT INTO Clientes(nombre,direccion,correo_electronico,numero_telefono)
VALUES ('Cliente de prueba','Dirección de prueba','crud-delete@example.com','0000000000');
SET @cliente_temporal = LAST_INSERT_ID();
COMMIT;
BEGIN;
DELETE FROM Clientes WHERE id_cliente = @cliente_temporal;
SELECT COUNT(*) = 0 AS borrado_dentro_transaccion FROM Clientes WHERE id_cliente = @cliente_temporal;
ROLLBACK;
SELECT COUNT(*) = 1 AS rollback_delete_ok FROM Clientes WHERE id_cliente = @cliente_temporal;
BEGIN;
DELETE FROM Clientes WHERE id_cliente = @cliente_temporal;
COMMIT;
SELECT COUNT(*) = 0 AS commit_delete_ok FROM Clientes WHERE id_cliente = @cliente_temporal;

-- Procedimientos con control de errores y bloqueo de fila.
CALL registrar_compra(2, 1, 1);
CALL cancelar_compra(@compra_id);

SELECT * FROM Productos;
SELECT * FROM Compras;
SELECT * FROM Facturas;
