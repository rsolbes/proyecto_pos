-- =====================================================
-- STORED PROCEDURES Y FUNCIONES PARA POS - CORREGIDOS
-- =====================================================

USE pos_system;

-- Limpiar procedures antiguos
DROP PROCEDURE IF EXISTS sp_crear_usuario;
DROP PROCEDURE IF EXISTS sp_productos_bajo_stock;
DROP PROCEDURE IF EXISTS sp_actualizar_stock;
DROP PROCEDURE IF EXISTS sp_reporte_ventas;
DROP PROCEDURE IF EXISTS sp_reporte_productos;
DROP PROCEDURE IF EXISTS sp_registrar_venta;
DROP PROCEDURE IF EXISTS sp_cancelar_venta;
DROP FUNCTION IF EXISTS obtener_nombre_cliente;

DELIMITER $$

-- FUNCIÓN: obtener_nombre_cliente
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

-- SP 1: CREAR USUARIO
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

-- SP 2: PRODUCTOS BAJO STOCK
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

-- SP 3: ACTUALIZAR STOCK
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

-- SP 4: REPORTE VENTAS
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

-- SP 5: REPORTE PRODUCTOS
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

-- SP 6: REGISTRAR VENTA
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

-- SP 7: CANCELAR VENTA
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