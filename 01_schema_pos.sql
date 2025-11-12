-- =====================================================
-- SISTEMA DE PUNTO DE VENTA (POS) - BASE DE DATOS
-- =====================================================

DROP DATABASE IF EXISTS pos_system;
CREATE DATABASE pos_system;
USE pos_system;

-- =====================================================
-- 1. TABLAS DEL SISTEMA
-- =====================================================

CREATE TABLE usuarios (
    id_usuario INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    contraseña VARCHAR(255) NOT NULL,
    rol ENUM('administrador', 'vendedor', 'gerente') NOT NULL DEFAULT 'vendedor',
    estado BOOLEAN DEFAULT TRUE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT chk_email_valido CHECK (email LIKE '%@%.%')
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE categorias (
    id_categoria INT PRIMARY KEY AUTO_INCREMENT,
    nombre_categoria VARCHAR(100) NOT NULL UNIQUE,
    descripcion TEXT,
    estado BOOLEAN DEFAULT TRUE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_nombre_categoria CHECK (LENGTH(nombre_categoria) > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE productos (
    id_producto INT PRIMARY KEY AUTO_INCREMENT,
    id_categoria INT NOT NULL,
    codigo_producto VARCHAR(50) UNIQUE NOT NULL,
    nombre_producto VARCHAR(150) NOT NULL,
    descripcion TEXT,
    precio_compra DECIMAL(10, 2) NOT NULL,
    precio_venta DECIMAL(10, 2) NOT NULL,
    stock_actual INT NOT NULL DEFAULT 0,
    stock_minimo INT DEFAULT 10,
    imagen_url VARCHAR(255),
    estado BOOLEAN DEFAULT TRUE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (id_categoria) REFERENCES categorias(id_categoria) ON DELETE RESTRICT,
    CONSTRAINT chk_precio_compra CHECK (precio_compra > 0),
    CONSTRAINT chk_precio_venta CHECK (precio_venta > 0),
    CONSTRAINT chk_precio_venta_mayor CHECK (precio_venta >= precio_compra),
    CONSTRAINT chk_stock CHECK (stock_actual >= 0),
    CONSTRAINT chk_stock_minimo CHECK (stock_minimo >= 0),
    INDEX idx_categoria (id_categoria),
    INDEX idx_codigo (codigo_producto)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE clientes (
    id_cliente INT PRIMARY KEY AUTO_INCREMENT,
    nombre_cliente VARCHAR(100) NOT NULL,
    apellido_cliente VARCHAR(100) NOT NULL,
    email_cliente VARCHAR(100),
    telefono VARCHAR(20),
    direccion VARCHAR(255),
    ciudad VARCHAR(50),
    documento_identidad VARCHAR(50) UNIQUE,
    tipo_cliente ENUM('regular', 'vip', 'mayorista') DEFAULT 'regular',
    estado BOOLEAN DEFAULT TRUE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT chk_nombre_cliente CHECK (LENGTH(nombre_cliente) > 0),
    CONSTRAINT chk_email_cliente CHECK (email_cliente IS NULL OR email_cliente LIKE '%@%.%'),
    INDEX idx_documento (documento_identidad)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE ventas (
    id_venta INT PRIMARY KEY AUTO_INCREMENT,
    id_usuario INT NOT NULL,
    id_cliente INT,
    numero_venta VARCHAR(50) UNIQUE NOT NULL,
    fecha_venta TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    subtotal DECIMAL(12, 2) NOT NULL,
    impuesto DECIMAL(12, 2) DEFAULT 0,
    descuento DECIMAL(12, 2) DEFAULT 0,
    total DECIMAL(12, 2) NOT NULL,
    metodo_pago ENUM('efectivo', 'tarjeta', 'transferencia', 'cheque') NOT NULL,
    estado ENUM('completada', 'cancelada', 'pendiente') DEFAULT 'completada',
    notas TEXT,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario) ON DELETE RESTRICT,
    FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente) ON DELETE SET NULL,
    CONSTRAINT chk_total_venta CHECK (total > 0),
    CONSTRAINT chk_subtotal_venta CHECK (subtotal > 0),
    CONSTRAINT chk_impuesto_venta CHECK (impuesto >= 0),
    CONSTRAINT chk_descuento_venta CHECK (descuento >= 0),
    INDEX idx_usuario (id_usuario),
    INDEX idx_cliente (id_cliente),
    INDEX idx_fecha_venta (fecha_venta)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE detalles_venta (
    id_detalle INT PRIMARY KEY AUTO_INCREMENT,
    id_venta INT NOT NULL,
    id_producto INT NOT NULL,
    cantidad INT NOT NULL,
    precio_unitario DECIMAL(10, 2) NOT NULL,
    descuento_linea DECIMAL(10, 2) DEFAULT 0,
    subtotal_linea DECIMAL(12, 2) NOT NULL,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_venta) REFERENCES ventas(id_venta) ON DELETE CASCADE,
    FOREIGN KEY (id_producto) REFERENCES productos(id_producto) ON DELETE RESTRICT,
    CONSTRAINT chk_cantidad_detalle CHECK (cantidad > 0),
    CONSTRAINT chk_precio_unitario CHECK (precio_unitario > 0),
    CONSTRAINT chk_subtotal_detalle CHECK (subtotal_linea > 0),
    INDEX idx_venta (id_venta),
    INDEX idx_producto (id_producto)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE movimientos_inventario (
    id_movimiento INT PRIMARY KEY AUTO_INCREMENT,
    id_producto INT NOT NULL,
    id_usuario INT NOT NULL,
    tipo_movimiento ENUM('entrada', 'salida', 'ajuste', 'devolucion') NOT NULL,
    cantidad_movimiento INT NOT NULL,
    motivo VARCHAR(200),
    cantidad_anterior INT NOT NULL,
    cantidad_nueva INT NOT NULL,
    fecha_movimiento TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_producto) REFERENCES productos(id_producto) ON DELETE RESTRICT,
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario) ON DELETE RESTRICT,
    CONSTRAINT chk_cantidad_movimiento CHECK (cantidad_movimiento > 0),
    INDEX idx_producto_inventario (id_producto),
    INDEX idx_fecha_inventario (fecha_movimiento)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE notificaciones_correo (
    id_notificacion INT PRIMARY KEY AUTO_INCREMENT,
    destinatario VARCHAR(100) NOT NULL,
    asunto VARCHAR(200) NOT NULL,
    cuerpo LONGTEXT NOT NULL,
    tipo_notificacion ENUM('bajo_stock', 'venta_realizada', 'usuario_creado', 'error_sistema') NOT NULL,
    enviada BOOLEAN DEFAULT FALSE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_envio TIMESTAMP NULL,
    CONSTRAINT chk_email_notificacion CHECK (destinatario LIKE '%@%.%'),
    INDEX idx_enviada (enviada),
    INDEX idx_tipo_notificacion (tipo_notificacion)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =====================================================
-- 2. FUNCIONES SQL
-- =====================================================

DELIMITER //

CREATE FUNCTION calcular_iva(monto DECIMAL(12, 2))
RETURNS DECIMAL(12, 2) DETERMINISTIC
READS SQL DATA
BEGIN
    RETURN ROUND(monto * 0.19, 2);
END//

CREATE FUNCTION validar_email(email VARCHAR(100))
RETURNS BOOLEAN DETERMINISTIC
BEGIN
    RETURN email REGEXP '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$';
END//

CREATE FUNCTION obtener_nombre_cliente(id_cliente_param INT)
RETURNS VARCHAR(201) READS SQL DATA
BEGIN
    DECLARE nombre_completo VARCHAR(201);
    SELECT CONCAT(nombre_cliente, ' ', apellido_cliente)
    INTO nombre_completo
    FROM clientes
    WHERE id_cliente = id_cliente_param;
    RETURN COALESCE(nombre_completo, 'Consumidor Final');
END//

CREATE FUNCTION total_ventas_periodo(fecha_inicio DATE, fecha_fin DATE)
RETURNS DECIMAL(15, 2) READS SQL DATA
BEGIN
    DECLARE total DECIMAL(15, 2);
    SELECT SUM(total)
    INTO total
    FROM ventas
    WHERE DATE(fecha_venta) BETWEEN fecha_inicio AND fecha_fin
    AND estado = 'completada';
    RETURN COALESCE(total, 0);
END//

CREATE FUNCTION verificar_stock(id_producto_param INT, cantidad_param INT)
RETURNS BOOLEAN READS SQL DATA
BEGIN
    DECLARE stock_disponible INT;
    SELECT stock_actual
    INTO stock_disponible
    FROM productos
    WHERE id_producto = id_producto_param;
    RETURN stock_disponible >= cantidad_param;
END//

DELIMITER ;

-- =====================================================
-- 3. TRIGGERS
-- =====================================================

DELIMITER //

CREATE TRIGGER trigger_notificar_bajo_stock
AFTER UPDATE ON productos
FOR EACH ROW
BEGIN
    IF NEW.stock_actual <= NEW.stock_minimo AND OLD.stock_actual > OLD.stock_minimo THEN
        INSERT INTO notificaciones_correo (
            destinatario, asunto, cuerpo, tipo_notificacion
        ) VALUES (
            'gerente@empresa.com',
            'ALERTA: Producto con stock bajo',
            CONCAT(
                'El producto ', NEW.nombre_producto, ' (', NEW.codigo_producto, ') ',
                'ha alcanzado el stock mínimo.\n\n',
                'Stock actual: ', NEW.stock_actual, '\n',
                'Stock mínimo: ', NEW.stock_minimo, '\n\n',
                'Por favor, realice un nuevo pedido.'
            ),
            'bajo_stock'
        );
    END IF;
END//

CREATE TRIGGER trigger_notificar_venta_realizada
AFTER INSERT ON ventas
FOR EACH ROW
BEGIN
    DECLARE v_nombre_usuario VARCHAR(100);
    DECLARE v_nombre_cliente VARCHAR(201);

    SELECT nombre INTO v_nombre_usuario FROM usuarios WHERE id_usuario = NEW.id_usuario;
    SET v_nombre_cliente = obtener_nombre_cliente(NEW.id_cliente);

    IF NEW.estado = 'completada' THEN
        INSERT INTO notificaciones_correo (
            destinatario, asunto, cuerpo, tipo_notificacion
        ) VALUES (
            'gerente@empresa.com',
            'Nueva venta registrada',
            CONCAT(
                'Se ha registrado una nueva venta.\n\n',
                'Número de venta: ', NEW.numero_venta, '\n',
                'Vendedor: ', v_nombre_usuario, '\n',
                'Cliente: ', v_nombre_cliente, '\n',
                'Total: $', FORMAT(NEW.total, 2), '\n',
                'Método de pago: ', NEW.metodo_pago, '\n',
                'Fecha: ', DATE_FORMAT(NEW.fecha_venta, '%d/%m/%Y %H:%i:%s')
            ),
            'venta_realizada'
        );
    END IF;
END//

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
END//

DELIMITER ;

-- =====================================================
-- 4. INSERTAR DATOS DE PRUEBA
-- =====================================================

INSERT INTO usuarios (nombre, email, contraseña, rol, estado) VALUES
('Admin Sistema', 'admin@empresa.com', MD5('admin123'), 'administrador', TRUE),
('Juan Pérez', 'juan@empresa.com', MD5('juan123'), 'vendedor', TRUE),
('María García', 'maria@empresa.com', MD5('maria123'), 'vendedor', TRUE),
('Carlos Rodríguez', 'carlos@empresa.com', MD5('carlos123'), 'gerente', TRUE);

INSERT INTO categorias (nombre_categoria, descripcion, estado) VALUES
('Electrónica', 'Productos electrónicos', TRUE),
('Ropa', 'Prendas de vestir', TRUE),
('Alimentos', 'Productos alimenticios', TRUE),
('Libros', 'Libros y publicaciones', TRUE);

INSERT INTO productos (id_categoria, codigo_producto, nombre_producto, descripcion, precio_compra, precio_venta, stock_actual, stock_minimo, estado) VALUES
(1, 'PROD001', 'Laptop HP', 'Laptop HP 15 pulgadas', 450.00, 650.00, 15, 5, TRUE),
(1, 'PROD002', 'Mouse Inalámbrico', 'Mouse USB inalámbrico', 8.00, 15.00, 100, 20, TRUE),
(1, 'PROD003', 'Teclado Mecánico', 'Teclado mecánico RGB', 40.00, 75.00, 25, 10, TRUE),
(2, 'PROD004', 'Camiseta Básica', 'Camiseta 100% algodón', 5.00, 12.00, 200, 50, TRUE),
(2, 'PROD005', 'Pantalón Vaquero', 'Pantalón denim azul', 20.00, 45.00, 80, 25, TRUE),
(3, 'PROD006', 'Café Premium', 'Café grano 500g', 8.00, 15.00, 150, 30, TRUE),
(4, 'PROD007', 'Programación en Python', 'Libro de referencia', 25.00, 45.00, 40, 10, TRUE);

INSERT INTO clientes (nombre_cliente, apellido_cliente, email_cliente, telefono, documento_identidad, tipo_cliente, estado) VALUES
('Juan', 'Ramírez', 'juan.ramirez@email.com', '3001234567', '1015234567', 'regular', TRUE),
('María', 'López', 'maria.lopez@email.com', '3009876543', '1025643890', 'vip', TRUE),
('Carlos', 'Martínez', 'carlos@email.com', '3154563210', '1035987654', 'mayorista', TRUE),
('Ana', 'González', NULL, '3187654321', '1045321098', 'regular', TRUE);

-- =====================================================
-- Fin del script
-- =====================================================