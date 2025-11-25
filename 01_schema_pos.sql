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