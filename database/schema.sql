CREATE DATABASE IF NOT EXISTS computienda CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE computienda;

CREATE TABLE Productos (
  codigo_producto INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(120) NOT NULL,
  descripcion VARCHAR(255) NOT NULL,
  cantidad_inventario INT NOT NULL,
  precio_venta DECIMAL(12,2) NOT NULL,
  CHECK (cantidad_inventario >= 0),
  CHECK (precio_venta > 0)
) ENGINE=InnoDB;

CREATE TABLE Clientes (
  id_cliente INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(120) NOT NULL,
  direccion VARCHAR(180) NOT NULL,
  correo_electronico VARCHAR(120) NOT NULL UNIQUE,
  numero_telefono VARCHAR(25) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE Compras (
  id_compra BIGINT AUTO_INCREMENT PRIMARY KEY,
  fecha DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  id_cliente INT NOT NULL,
  codigo_producto INT NOT NULL,
  cantidad_comprada INT NOT NULL,
  precio_unitario DECIMAL(12,2) NOT NULL,
  estado ENUM('CONFIRMADA','CANCELADA') NOT NULL DEFAULT 'CONFIRMADA',
  CONSTRAINT fk_compra_cliente FOREIGN KEY (id_cliente) REFERENCES Clientes(id_cliente),
  CONSTRAINT fk_compra_producto FOREIGN KEY (codigo_producto) REFERENCES Productos(codigo_producto),
  CHECK (cantidad_comprada > 0),
  CHECK (precio_unitario > 0)
) ENGINE=InnoDB;

CREATE TABLE Facturas (
  id_factura BIGINT AUTO_INCREMENT PRIMARY KEY,
  fecha DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  id_compra BIGINT NOT NULL UNIQUE,
  nombre_cliente VARCHAR(120) NOT NULL,
  id_cliente INT NOT NULL,
  codigo_producto INT NOT NULL,
  cantidad_comprada INT NOT NULL,
  precio_unitario DECIMAL(12,2) NOT NULL,
  total_factura DECIMAL(12,2) NOT NULL,
  estado_entrega ENUM('PENDIENTE','ENVIADA','ENTREGADA','CANCELADA') NOT NULL DEFAULT 'PENDIENTE',
  CONSTRAINT fk_factura_compra FOREIGN KEY (id_compra) REFERENCES Compras(id_compra),
  CONSTRAINT fk_factura_cliente FOREIGN KEY (id_cliente) REFERENCES Clientes(id_cliente),
  CONSTRAINT fk_factura_producto FOREIGN KEY (codigo_producto) REFERENCES Productos(codigo_producto),
  CHECK (cantidad_comprada > 0),
  CHECK (precio_unitario > 0),
  CHECK (total_factura = cantidad_comprada * precio_unitario)
) ENGINE=InnoDB;

DELIMITER //
CREATE PROCEDURE registrar_compra(
  IN p_cliente INT, IN p_producto INT, IN p_cantidad INT
)
BEGIN
  DECLARE v_existencias INT;
  DECLARE v_precio DECIMAL(12,2);
  DECLARE v_compra BIGINT;
  DECLARE v_nombre VARCHAR(120);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;
  IF p_cantidad IS NULL OR p_cantidad <= 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La cantidad debe ser positiva';
  END IF;
  SELECT nombre INTO v_nombre FROM Clientes WHERE id_cliente = p_cliente;
  IF v_nombre IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cliente inexistente';
  END IF;
  SELECT cantidad_inventario, precio_venta INTO v_existencias, v_precio
    FROM Productos WHERE codigo_producto = p_producto FOR UPDATE;
  IF v_existencias IS NULL OR v_existencias < p_cantidad THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Inventario insuficiente';
  END IF;
  INSERT INTO Compras (id_cliente, codigo_producto, cantidad_comprada, precio_unitario)
    VALUES (p_cliente, p_producto, p_cantidad, v_precio);
  SET v_compra = LAST_INSERT_ID();
  UPDATE Productos SET cantidad_inventario = cantidad_inventario - p_cantidad
    WHERE codigo_producto = p_producto;
  INSERT INTO Facturas (id_compra, nombre_cliente, id_cliente, codigo_producto, cantidad_comprada, precio_unitario, total_factura)
    VALUES (v_compra, v_nombre, p_cliente, p_producto, p_cantidad, v_precio, p_cantidad * v_precio);
  COMMIT;
END//

CREATE PROCEDURE cancelar_compra(IN p_compra BIGINT)
BEGIN
  DECLARE v_producto INT;
  DECLARE v_cantidad INT;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;
  SELECT codigo_producto, cantidad_comprada INTO v_producto, v_cantidad
    FROM Compras WHERE id_compra = p_compra AND estado = 'CONFIRMADA' FOR UPDATE;
  IF v_producto IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Compra no encontrada o ya cancelada';
  END IF;
  UPDATE Compras SET estado = 'CANCELADA' WHERE id_compra = p_compra;
  UPDATE Facturas SET estado_entrega = 'CANCELADA' WHERE id_compra = p_compra;
  UPDATE Productos SET cantidad_inventario = cantidad_inventario + v_cantidad
    WHERE codigo_producto = v_producto;
  COMMIT;
END//
DELIMITER ;
