-- CREAMOS LA BASE DE DATOS

DROP DATABASE IF EXISTS pos_system;
CREATE DATABASE pos_system CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE pos_system;

-- CREAMOS LAS TABLAS

-- 1. CATEGORÍAS
CREATE TABLE categorias (
    id_categoria INT PRIMARY KEY AUTO_INCREMENT,
    nombre_categoria VARCHAR(100) NOT NULL UNIQUE,
    descripcion TEXT,
    estado BOOLEAN DEFAULT TRUE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. PRODUCTOS
CREATE TABLE productos (
    id_producto INT PRIMARY KEY AUTO_INCREMENT,
    codigo_producto VARCHAR(50) NOT NULL UNIQUE,
    nombre_producto VARCHAR(150) NOT NULL,
    id_categoria INT NOT NULL,
    precio_compra DECIMAL(10, 2) NOT NULL CHECK (precio_compra >= 0),
    precio_venta DECIMAL(10, 2) NOT NULL CHECK (precio_venta >= 0),
    stock_actual INT NOT NULL DEFAULT 0 CHECK (stock_actual >= 0),
    stock_minimo INT NOT NULL DEFAULT 10 CHECK (stock_minimo >= 0),
    estado BOOLEAN DEFAULT TRUE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_categoria) REFERENCES categorias(id_categoria),
    INDEX idx_codigo (codigo_producto),
    INDEX idx_nombre (nombre_producto),
    INDEX idx_stock (stock_actual)
);

-- 3. USUARIOS
CREATE TABLE usuarios (
    id_usuario INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    contraseña VARCHAR(255) NOT NULL,
    rol ENUM('vendedor', 'gerente', 'administrador') DEFAULT 'vendedor',
    estado BOOLEAN DEFAULT TRUE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ultimo_acceso TIMESTAMP NULL,
    INDEX idx_email (email),
    INDEX idx_rol (rol)
);

-- 4. CLIENTES
CREATE TABLE clientes (
    id_cliente INT PRIMARY KEY AUTO_INCREMENT,
    nombre_cliente VARCHAR(100) NOT NULL,
    apellido_cliente VARCHAR(100) NOT NULL,
    email_cliente VARCHAR(100),
    telefono VARCHAR(20),
    tipo_cliente ENUM('regular', 'vip', 'mayorista') DEFAULT 'regular',
    documento_identidad VARCHAR(50),
    ciudad VARCHAR(100),
    estado BOOLEAN DEFAULT TRUE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_documento (documento_identidad),
    INDEX idx_nombre (nombre_cliente),
    INDEX idx_tipo (tipo_cliente)
);

-- 5. VENTAS
CREATE TABLE ventas (
    id_venta INT PRIMARY KEY AUTO_INCREMENT,
    numero_venta VARCHAR(50) NOT NULL UNIQUE,
    id_usuario INT NOT NULL,
    id_cliente INT NOT NULL,
    subtotal DECIMAL(12, 2) NOT NULL DEFAULT 0 CHECK (subtotal >= 0),
    impuesto DECIMAL(12, 2) NOT NULL DEFAULT 0 CHECK (impuesto >= 0),
    descuento DECIMAL(12, 2) NOT NULL DEFAULT 0 CHECK (descuento >= 0),
    total DECIMAL(12, 2) NOT NULL DEFAULT 0 CHECK (total >= 0),
    metodo_pago VARCHAR(50) NOT NULL,
    estado ENUM('completada', 'cancelada') DEFAULT 'completada',
    notas TEXT,
    fecha_venta TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario),
    FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente),
    INDEX idx_numero (numero_venta),
    INDEX idx_fecha (fecha_venta),
    INDEX idx_usuario (id_usuario),
    INDEX idx_estado (estado)
);

-- 6. DETALLES VENTA
CREATE TABLE detalles_venta (
    id_detalle INT PRIMARY KEY AUTO_INCREMENT,
    id_venta INT NOT NULL,
    id_producto INT NOT NULL,
    cantidad INT NOT NULL CHECK (cantidad > 0),
    precio_unitario DECIMAL(10, 2) NOT NULL CHECK (precio_unitario > 0),
    descuento_linea DECIMAL(10, 2) DEFAULT 0 CHECK (descuento_linea >= 0),
    subtotal_linea DECIMAL(12, 2) NOT NULL CHECK (subtotal_linea >= 0),
    FOREIGN KEY (id_venta) REFERENCES ventas(id_venta) ON DELETE CASCADE,
    FOREIGN KEY (id_producto) REFERENCES productos(id_producto),
    INDEX idx_venta (id_venta),
    INDEX idx_producto (id_producto)
);

-- 7. MOVIMIENTOS DE INVENTARIO
CREATE TABLE movimientos_inventario (
    id_movimiento INT PRIMARY KEY AUTO_INCREMENT,
    id_producto INT NOT NULL,
    id_usuario INT NOT NULL,
    tipo_movimiento VARCHAR(50) NOT NULL,
    cantidad_movimiento INT NOT NULL,
    motivo VARCHAR(200),
    cantidad_anterior INT NOT NULL,
    cantidad_nueva INT NOT NULL,
    fecha_movimiento TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_producto) REFERENCES productos(id_producto),
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario),
    INDEX idx_producto (id_producto),
    INDEX idx_fecha (fecha_movimiento),
    INDEX idx_tipo (tipo_movimiento)
);

-- 8. NOTIFICACIONES POR CORREO
CREATE TABLE notificaciones_correo (
    id_notificacion INT PRIMARY KEY AUTO_INCREMENT,
    destinatario VARCHAR(100) NOT NULL,
    asunto VARCHAR(255) NOT NULL,
    cuerpo LONGTEXT NOT NULL,
    tipo_notificacion VARCHAR(50) NOT NULL,
    enviada BOOLEAN DEFAULT FALSE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_envio TIMESTAMP NULL,
    INDEX idx_enviada (enviada),
    INDEX idx_tipo (tipo_notificacion),
    INDEX idx_fecha (fecha_creacion)
);

-- POBLAMOS LA BASE DE DATOS (DATOS PROPUESTOS POR IA)

-- Categorías
INSERT INTO categorias (nombre_categoria, descripcion) VALUES
('Electrónica', 'Productos electrónicos en general'),
('Ropa', 'Prendas de vestir'),
('Alimentos', 'Productos alimentarios'),
('Accesorios', 'Accesorios y complementos'),
('Servicios', 'Servicios diversos');

-- Productos de ejemplo
INSERT INTO productos (codigo_producto, nombre_producto, id_categoria, precio_compra, precio_venta, stock_actual, stock_minimo) VALUES
('PROD001', 'Laptop HP', 1, 500.00, 750.00, 5, 5),
('PROD002', 'Mouse inalámbrico', 1, 15.00, 25.00, 20, 10),
('PROD003', 'Teclado mecánico', 1, 60.00, 100.00, 8, 5),
('PROD004', 'Monitor 24"', 1, 150.00, 250.00, 3, 2),
('PROD005', 'Camiseta básica', 2, 10.00, 20.00, 50, 20),
('PROD006', 'Pantalón jeans', 2, 30.00, 60.00, 25, 15),
('PROD007', 'Café premium 1kg', 3, 8.00, 15.00, 100, 50),
('PROD008', 'Auriculares Bluetooth', 1, 30.00, 60.00, 15, 10),
('PROD009', 'Mochila laptop', 4, 40.00, 80.00, 12, 5),
('PROD010', 'Cargador rápido', 1, 20.00, 40.00, 30, 15);

-- Usuarios iniciales
INSERT INTO usuarios (nombre, email, contraseña, rol) VALUES
('Admin Sistema', 'admin@empresa.com', MD5('admin123'), 'administrador'),
('Juan Pérez', 'juan@empresa.com', MD5('juan123'), 'vendedor'),
('María García', 'maria@empresa.com', MD5('maria123'), 'vendedor'),
('Carlos Rodríguez', 'carlos@empresa.com', MD5('carlos123'), 'gerente'),
('Roberto López', 'roberto@empresa.com', MD5('roberto123'), 'vendedor'),
('Rodrigo Solbes', 'rsolbes@hotmail.com', MD5('rodrigo123'), 'administrador');

-- Clientes iniciales
INSERT INTO clientes (nombre_cliente, apellido_cliente, email_cliente, telefono, tipo_cliente, documento_identidad, ciudad) VALUES
('Juan', 'Ramírez', 'juan.ramirez@email.com', '3001234567', 'regular', '1023456789', 'Bogotá'),
('María', 'González', 'maria.gonzalez@email.com', '3109876543', 'vip', '1098765432', 'Medellín'),
('Carlos', 'Martínez', 'carlos.martinez@email.com', '3215555555', 'mayorista', '1111111111', 'Cali'),
('Ana', 'López', 'ana.lopez@email.com', '3187654321', 'regular', '1222222222', 'Barranquilla'),
('Pedro', 'Sánchez', 'pedro.sanchez@email.com', '3203333333', 'regular', '1333333333', 'Bogotá');

-- CREAMOS LOS TRIGGERS

DELIMITER $$

-- Validamos los detalles de la venta
CREATE TRIGGER trigger_validar_detalle_venta
BEFORE INSERT ON detalles_venta
FOR EACH ROW
BEGIN
    DECLARE v_precio_unitario DECIMAL(10, 2);
    SELECT precio_venta INTO v_precio_unitario
    FROM productos
    WHERE id_producto = NEW.id_producto;
    IF v_precio_unitario != NEW.precio_unitario THEN
        SET NEW.precio_unitario = v_precio_unitario;
    END IF;
    SET NEW.subtotal_linea = (NEW.cantidad * NEW.precio_unitario) - COALESCE(NEW.descuento_linea, 0);
END$$

-- Notificamos cuando hay stock bajo
CREATE TRIGGER trigger_notificar_bajo_stock
AFTER UPDATE ON productos
FOR EACH ROW
BEGIN
  IF NEW.stock_actual <= NEW.stock_minimo AND OLD.stock_actual > OLD.stock_minimo THEN
    INSERT INTO notificaciones_correo (destinatario, asunto, cuerpo, tipo_notificacion)
    VALUES (
      'rsolbes@hotmail.com',
      'ALERTA: Producto con stock bajo',
      CONCAT(
        'El producto ', NEW.nombre_producto, ' (', NEW.codigo_producto, ') ',
        'ha alcanzado el stock mínimo.

Stock actual: ', NEW.stock_actual, '
Stock mínimo: ', NEW.stock_minimo, '

Por favor, realice un nuevo pedido.'
      ),
      'bajo_stock'
    );
  END IF;
END$$

-- Notifica cuadno se registra una venta
CREATE TRIGGER trigger_notificar_venta
AFTER INSERT ON ventas
FOR EACH ROW
BEGIN
  INSERT INTO notificaciones_correo (destinatario, asunto, cuerpo, tipo_notificacion)
  VALUES (
    'rsolbes@hotmail.com',
    'Nueva venta registrada',
    CONCAT(
      'Se ha registrado una nueva venta.

Número de venta: ', NEW.numero_venta, '
Vendedor: ', (SELECT nombre FROM usuarios WHERE id_usuario = NEW.id_usuario), '
Cliente: ', (SELECT CONCAT(nombre_cliente, ' ', apellido_cliente) FROM clientes WHERE id_cliente = NEW.id_cliente), '
Total: $', FORMAT(NEW.total, 2), '
Método de pago: ', NEW.metodo_pago, '
Fecha: ', DATE_FORMAT(NEW.fecha_venta, '%d/%m/%Y %H:%i:%s')
    ),
    'venta_realizada'
  );
END$$

DELIMITER ;


-- STORED PROCEDURES

USE pos_system;

-- Revisar si las procedures ya existen, si existen se borran para volverlas a hacer.
DROP PROCEDURE IF EXISTS sp_crear_usuario;
DROP PROCEDURE IF EXISTS sp_productos_bajo_stock;
DROP PROCEDURE IF EXISTS sp_actualizar_stock;
DROP PROCEDURE IF EXISTS sp_reporte_ventas;
DROP PROCEDURE IF EXISTS sp_reporte_productos;
DROP PROCEDURE IF EXISTS sp_registrar_venta;
DROP PROCEDURE IF EXISTS sp_cancelar_venta;
DROP FUNCTION IF EXISTS obtener_nombre_cliente;

DELIMITER $$

CREATE FUNCTION obtener_nombre_cliente(p_id_cliente INT)
RETURNS VARCHAR(201) DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_nombre_completo VARCHAR(201);
    
    SELECT CONCAT(nombre_cliente, ' ', apellido_cliente)
    INTO v_nombre_completo
    FROM clientes
    WHERE id_cliente = p_id_cliente;
    
    RETURN COALESCE(v_nombre_completo, 'Cliente Desconocido');
END$$

CREATE PROCEDURE sp_crear_usuario(
    IN p_nombre VARCHAR(100),
    IN p_email VARCHAR(100),
    IN p_contraseña VARCHAR(255),
    IN p_rol VARCHAR(50),
    OUT p_id_usuario INT,
    OUT p_mensaje VARCHAR(500)
)
sp_block: BEGIN
    DECLARE v_usuario_existe INT;
    
    IF p_email IS NULL OR p_email = '' THEN
        SET p_mensaje = 'El email es requerido';
        SET p_id_usuario = -1;
        LEAVE sp_block;
    END IF;
    
    IF p_contraseña IS NULL OR p_contraseña = '' THEN
        SET p_mensaje = 'La contraseña es requerida';
        SET p_id_usuario = -1;
        LEAVE sp_block;
    END IF;
    
    SELECT COUNT(*) INTO v_usuario_existe
    FROM usuarios
    WHERE email = p_email;

    IF v_usuario_existe > 0 THEN
        SET p_mensaje = 'El email ya está registrado';
        SET p_id_usuario = -1;
    ELSE
        INSERT INTO usuarios (nombre, email, contraseña, rol, estado)
        VALUES (p_nombre, p_email, MD5(p_contraseña), p_rol, TRUE);
        
        SET p_id_usuario = LAST_INSERT_ID();
        SET p_mensaje = 'Usuario creado exitosamente';
    END IF;
END$$

CREATE PROCEDURE sp_productos_bajo_stock()
BEGIN
    SELECT
        id_producto,
        codigo_producto,
        nombre_producto,
        stock_actual,
        stock_minimo,
        (stock_minimo - stock_actual) as deficit,
        precio_compra,
        (stock_minimo - stock_actual) * precio_compra as costo_deficit
    FROM productos
    WHERE stock_actual <= stock_minimo
    AND estado = TRUE
    ORDER BY deficit DESC;
END$$

CREATE PROCEDURE sp_actualizar_stock(
    IN p_id_producto INT,
    IN p_cantidad INT,
    IN p_tipo_movimiento VARCHAR(50),
    IN p_id_usuario INT,
    IN p_motivo VARCHAR(200),
    OUT p_mensaje VARCHAR(500)
)
sp_block: BEGIN
    DECLARE v_stock_anterior INT;
    DECLARE v_stock_nuevo INT;
    DECLARE v_producto_existe INT;

    IF p_cantidad < 0 THEN
        SET p_mensaje = 'La cantidad no puede ser negativa';
        LEAVE sp_block;
    END IF;

    SELECT COUNT(*) INTO v_producto_existe
    FROM productos
    WHERE id_producto = p_id_producto;
    
    IF v_producto_existe = 0 THEN
        SET p_mensaje = 'El producto no existe';
        LEAVE sp_block;
    END IF;

    SELECT stock_actual INTO v_stock_anterior
    FROM productos
    WHERE id_producto = p_id_producto;

    IF p_tipo_movimiento = 'entrada' THEN
        SET v_stock_nuevo = v_stock_anterior + p_cantidad;
    ELSEIF p_tipo_movimiento = 'salida' OR p_tipo_movimiento = 'devolucion' THEN
        SET v_stock_nuevo = v_stock_anterior - p_cantidad;
    ELSEIF p_tipo_movimiento = 'ajuste' THEN
        SET v_stock_nuevo = p_cantidad;
    ELSE
        SET p_mensaje = 'Tipo de movimiento no válido';
        LEAVE sp_block;
    END IF;

    IF v_stock_nuevo < 0 THEN
        SET p_mensaje = CONCAT('No hay stock suficiente. Stock disponible: ', v_stock_anterior);
        LEAVE sp_block;
    ELSE
        UPDATE productos
        SET stock_actual = v_stock_nuevo
        WHERE id_producto = p_id_producto;

        INSERT INTO movimientos_inventario (
            id_producto, id_usuario, tipo_movimiento,
            cantidad_movimiento, motivo, cantidad_anterior,
            cantidad_nueva
        ) VALUES (
            p_id_producto, p_id_usuario, p_tipo_movimiento,
            p_cantidad, p_motivo, v_stock_anterior, v_stock_nuevo
        );

        SET p_mensaje = 'Stock actualizado exitosamente';
    END IF;
END$$

CREATE PROCEDURE sp_reporte_ventas(
    IN p_fecha_inicio DATE,
    IN p_fecha_fin DATE
)
BEGIN
    SELECT
        DATE(v.fecha_venta) as fecha,
        COUNT(*) as cantidad_transacciones,
        SUM(v.subtotal) as subtotal_total,
        SUM(v.impuesto) as impuesto_total,
        SUM(v.total) as total_venta,
        v.metodo_pago,
        u.nombre as vendedor
    FROM ventas v
    JOIN usuarios u ON v.id_usuario = u.id_usuario
    WHERE DATE(v.fecha_venta) BETWEEN p_fecha_inicio AND p_fecha_fin
    AND v.estado = 'completada'
    GROUP BY DATE(v.fecha_venta), v.metodo_pago, u.nombre
    ORDER BY DATE(v.fecha_venta) DESC;
END$$

CREATE PROCEDURE sp_reporte_productos()
BEGIN
    SELECT
        p.id_producto,
        p.codigo_producto,
        p.nombre_producto,
        c.nombre_categoria,
        p.stock_actual,
        p.stock_minimo,
        p.precio_compra,
        p.precio_venta,
        (p.precio_venta - p.precio_compra) as ganancia_unitaria,
        ((p.precio_venta - p.precio_compra) / p.precio_compra * 100) as porcentaje_ganancia,
        p.estado
    FROM productos p
    JOIN categorias c ON p.id_categoria = c.id_categoria
    WHERE p.estado = TRUE
    ORDER BY c.nombre_categoria, p.nombre_producto;
END$$

CREATE PROCEDURE sp_registrar_venta(
    IN p_id_usuario INT,
    IN p_id_cliente INT,
    IN p_metodo_pago VARCHAR(50),
    IN p_productos_json JSON,
    IN p_descuento DECIMAL(10, 2),
    OUT p_id_venta_generada INT,
    OUT p_numero_venta VARCHAR(50),
    OUT p_mensaje VARCHAR(500)
)
sp_block: BEGIN
    DECLARE v_subtotal DECIMAL(12, 2) DEFAULT 0;
    DECLARE v_impuesto DECIMAL(12, 2) DEFAULT 0;
    DECLARE v_total DECIMAL(12, 2) DEFAULT 0;
    DECLARE v_id_producto INT;
    DECLARE v_cantidad INT;
    DECLARE v_precio_unitario DECIMAL(10, 2);
    DECLARE v_stock_actual INT;
    DECLARE v_subtotal_linea DECIMAL(12, 2);
    DECLARE v_total_items INT;
    DECLARE v_descuento_valido DECIMAL(10, 2);
    DECLARE contador_iteracion INT DEFAULT 0;

    SET v_total_items = JSON_LENGTH(p_productos_json);
    SET v_descuento_valido = COALESCE(p_descuento, 0);
    
    IF v_descuento_valido < 0 THEN
        SET p_mensaje = 'El descuento no puede ser negativo';
        SET p_id_venta_generada = -1;
        LEAVE sp_block;
    END IF;
    
    IF v_total_items = 0 THEN
        SET p_mensaje = 'No hay productos en la venta';
        SET p_id_venta_generada = -1;
        LEAVE sp_block;
    END IF;

    SET p_numero_venta = CONCAT('V-', DATE_FORMAT(NOW(), '%Y%m%d'), '-', LPAD(FLOOR(RAND() * 10000), 5, '0'));

    WHILE contador_iteracion < v_total_items DO
        SET v_id_producto = JSON_UNQUOTE(JSON_EXTRACT(p_productos_json, CONCAT('$[', contador_iteracion, '].id_producto')));
        SET v_cantidad = JSON_UNQUOTE(JSON_EXTRACT(p_productos_json, CONCAT('$[', contador_iteracion, '].cantidad')));

        IF v_cantidad <= 0 THEN
            SET p_mensaje = CONCAT('La cantidad debe ser positiva para producto ID: ', v_id_producto);
            SET p_id_venta_generada = -1;
            LEAVE sp_block;
        END IF;

        SELECT precio_venta, stock_actual
        INTO v_precio_unitario, v_stock_actual
        FROM productos
        WHERE id_producto = v_id_producto;

        IF v_stock_actual < v_cantidad THEN
            SET p_mensaje = CONCAT('Stock insuficiente para producto ID: ', v_id_producto, ' (Disponible: ', v_stock_actual, ')');
            SET p_id_venta_generada = -1;
            LEAVE sp_block;
        END IF;

        SET v_subtotal_linea = v_cantidad * v_precio_unitario;
        SET v_subtotal = v_subtotal + v_subtotal_linea;
        SET contador_iteracion = contador_iteracion + 1;
    END WHILE;

    SET v_impuesto = ROUND(v_subtotal * 0.19, 2);
    SET v_total = v_subtotal + v_impuesto - v_descuento_valido;

    INSERT INTO ventas (
        id_usuario, id_cliente, numero_venta, subtotal, 
        impuesto, descuento, total, metodo_pago, estado
    ) VALUES (
        p_id_usuario, p_id_cliente, p_numero_venta, v_subtotal,
        v_impuesto, v_descuento_valido, v_total, p_metodo_pago, 'completada'
    );

    SET p_id_venta_generada = LAST_INSERT_ID();

    SET contador_iteracion = 0;
    WHILE contador_iteracion < v_total_items DO
        SET v_id_producto = JSON_UNQUOTE(JSON_EXTRACT(p_productos_json, CONCAT('$[', contador_iteracion, '].id_producto')));
        SET v_cantidad = JSON_UNQUOTE(JSON_EXTRACT(p_productos_json, CONCAT('$[', contador_iteracion, '].cantidad')));

        SELECT precio_venta INTO v_precio_unitario FROM productos WHERE id_producto = v_id_producto;

        SET v_subtotal_linea = v_cantidad * v_precio_unitario;

        INSERT INTO detalles_venta (
            id_venta, id_producto, cantidad, 
            precio_unitario, descuento_linea, subtotal_linea
        ) VALUES (
            p_id_venta_generada, v_id_producto, v_cantidad,
            v_precio_unitario, 0, v_subtotal_linea
        );

        UPDATE productos
        SET stock_actual = stock_actual - v_cantidad
        WHERE id_producto = v_id_producto;

        SET contador_iteracion = contador_iteracion + 1;
    END WHILE;

    SET p_mensaje = 'Venta registrada exitosamente';
END$$

CREATE PROCEDURE sp_cancelar_venta(
    IN p_id_venta INT,
    IN p_motivo VARCHAR(200),
    OUT p_mensaje VARCHAR(500)
)
sp_block: BEGIN
    DECLARE v_venta_existe INT;
    DECLARE v_estado_venta VARCHAR(20);
    DECLARE v_id_producto INT;
    DECLARE v_cantidad INT;
    DECLARE v_cursor_done INT DEFAULT FALSE;
    DECLARE cursor_detalles CURSOR FOR
        SELECT id_producto, cantidad FROM detalles_venta WHERE id_venta = p_id_venta;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_cursor_done = TRUE;

    SELECT COUNT(*), estado INTO v_venta_existe, v_estado_venta
    FROM ventas
    WHERE id_venta = p_id_venta;

    IF v_venta_existe = 0 THEN
        SET p_mensaje = 'La venta no existe';
        LEAVE sp_block;
    END IF;

    IF v_estado_venta = 'cancelada' THEN
        SET p_mensaje = 'La venta ya ha sido cancelada';
        LEAVE sp_block;
    END IF;

    OPEN cursor_detalles;
    cursor_loop: LOOP
        FETCH cursor_detalles INTO v_id_producto, v_cantidad;
        IF v_cursor_done THEN
            LEAVE cursor_loop;
        END IF;

        UPDATE productos
        SET stock_actual = stock_actual + v_cantidad
        WHERE id_producto = v_id_producto;
    END LOOP;
    CLOSE cursor_detalles;

    UPDATE ventas
    SET estado = 'cancelada', notas = CONCAT('Cancelada: ', p_motivo)
    WHERE id_venta = p_id_venta;

    SET p_mensaje = 'Venta cancelada y stock restaurado exitosamente';
END$$

DELIMITER ;