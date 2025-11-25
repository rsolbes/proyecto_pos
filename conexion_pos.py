import mysql.connector
from mysql.connector import Error
from hashlib import md5

class ConexionPOS:
    def __init__(self):
        try:
            self.conexion = mysql.connector.connect(
                host='localhost',
                user='root',
                password='Rsolbdav1209.',
                database='pos_system'
            )
            self.cursor = self.conexion.cursor(dictionary=True)
            print(f"Conectado a la base de datos: pos_system")
        except Error as e:
            print(f"Error: {e}")
            self.conexion = None
            self.cursor = None

    def cerrar(self):
        if self.conexion and self.conexion.is_connected():
            self.cursor.close()
            self.conexion.close()
            print("Conexión cerrada")

    def autenticar_usuario(self, email, contraseña):
        try:
            contraseña_encriptada = md5(contraseña.encode()).hexdigest()
            query = "SELECT id_usuario, nombre, email, rol, estado FROM usuarios WHERE email = %s AND contraseña = %s"
            self.cursor.execute(query, (email, contraseña_encriptada))
            return self.cursor.fetchone()
        except Exception as e:
            print(f"Error: {e}")
            return None

    def crear_usuario(self, nombre, email, contraseña, rol):
        try:
            contraseña_encriptada = md5(contraseña.encode()).hexdigest()
            query = "INSERT INTO usuarios (nombre, email, contraseña, rol, estado) VALUES (%s, %s, %s, %s, TRUE)"
            self.cursor.execute(query, (nombre, email, contraseña_encriptada, rol))
            self.conexion.commit()
            return True, "Usuario creado"
        except Exception as e:
            return False, str(e)

    def obtener_productos(self):
        try:
            query = """
            SELECT p.id_producto, p.codigo_producto, p.nombre_producto, 
                   c.nombre_categoria, p.precio_compra, p.precio_venta, 
                   p.stock_actual, p.stock_minimo, p.estado
            FROM productos p
            JOIN categorias c ON p.id_categoria = c.id_categoria
            WHERE p.estado = TRUE
            """
            self.cursor.execute(query)
            productos = self.cursor.fetchall()
            return productos if productos else []
        except Exception as e:
            print(f"Error: {e}")
            return []

    def obtener_clientes(self):
        try:
            query = """
            SELECT id_cliente, nombre_cliente, apellido_cliente, 
                   email_cliente, telefono, tipo_cliente, documento_identidad, ciudad
            FROM clientes WHERE estado = TRUE
            """
            self.cursor.execute(query)
            clientes = self.cursor.fetchall()
            return clientes if clientes else []
        except Exception as e:
            print(f"Error: {e}")
            return []

    def obtener_ventas(self):
        try:
            query = """
            SELECT v.id_venta, v.numero_venta, v.fecha_venta, 
                   CONCAT(c.nombre_cliente, ' ', c.apellido_cliente) as cliente,
                   u.nombre as nombre_vendedor, v.total, v.metodo_pago, v.estado
            FROM ventas v
            JOIN clientes c ON v.id_cliente = c.id_cliente
            JOIN usuarios u ON v.id_usuario = u.id_usuario
            ORDER BY v.fecha_venta DESC LIMIT 100
            """
            self.cursor.execute(query)
            ventas = self.cursor.fetchall()
            return ventas if ventas else []
        except Exception as e:
            print(f"Error: {e}")
            return []

    def obtener_ventas_hoy(self):
        try:
            query = "SELECT COALESCE(SUM(total), 0) as total FROM ventas WHERE DATE(fecha_venta) = CURDATE()"
            self.cursor.execute(query)
            resultado = self.cursor.fetchone()
            return float(resultado['total']) if resultado else 0
        except Exception as e:
            print(f"Error: {e}")
            return 0

    def obtener_ventas_mes(self):
        try:
            query = """
            SELECT COALESCE(SUM(total), 0) as total FROM ventas 
            WHERE YEAR(fecha_venta) = YEAR(CURDATE()) 
            AND MONTH(fecha_venta) = MONTH(CURDATE())
            """
            self.cursor.execute(query)
            resultado = self.cursor.fetchone()
            return float(resultado['total']) if resultado else 0
        except Exception as e:
            print(f"Error: {e}")
            return 0

    def contar_productos(self):
        try:
            query = "SELECT COUNT(*) as total FROM productos WHERE estado = TRUE"
            self.cursor.execute(query)
            resultado = self.cursor.fetchone()
            return resultado['total'] if resultado else 0
        except Exception as e:
            return 0

    def contar_bajo_stock(self):
        try:
            query = "SELECT COUNT(*) as total FROM productos WHERE stock_actual <= stock_minimo AND estado = TRUE"
            self.cursor.execute(query)
            resultado = self.cursor.fetchone()
            return resultado['total'] if resultado else 0
        except Exception as e:
            return 0

    def registrar_venta(self, id_usuario, id_cliente, metodo_pago, productos_json, descuento):
        try:
            args = [id_usuario, id_cliente, metodo_pago, productos_json, descuento, 0, '', '']
            self.cursor.callproc('sp_registrar_venta', args)
            self.conexion.commit()
            return True, "Venta registrada"
        except Exception as e:
            return False, str(e)

    def obtener_usuarios(self):
        try:
            query = "SELECT id_usuario, nombre, email, rol, estado, fecha_creacion FROM usuarios"
            self.cursor.execute(query)
            usuarios = self.cursor.fetchall()
            return usuarios if usuarios else []
        except Exception as e:
            return []

    def obtener_reporte_ventas(self, fecha_inicio, fecha_fin):
        try:
            query = """
            SELECT DATE(v.fecha_venta) as fecha, COUNT(*) as cantidad_transacciones,
                   SUM(v.subtotal) as subtotal_total, SUM(v.impuesto) as impuesto_total,
                   SUM(v.total) as total_venta, v.metodo_pago, u.nombre as vendedor
            FROM ventas v
            JOIN usuarios u ON v.id_usuario = u.id_usuario
            WHERE DATE(v.fecha_venta) BETWEEN %s AND %s
            GROUP BY DATE(v.fecha_venta), v.metodo_pago, u.nombre
            ORDER BY DATE(v.fecha_venta) DESC
            """
            self.cursor.execute(query, (fecha_inicio, fecha_fin))
            reporte = self.cursor.fetchall()
            return reporte if reporte else []
        except Exception as e:
            return []
        
    def obtener_categorias(self):
        try:
            query = "SELECT id_categoria, nombre_categoria FROM categorias WHERE estado = TRUE"
            self.cursor.execute(query)
            return self.cursor.fetchall() or []
        except Exception as e:
            print(f"Error: {e}")
            return []

    def obtener_producto_por_id(self, id_producto):
        """Obtiene un producto por ID"""
        try:
            query = "SELECT id_producto, nombre_producto, stock_actual FROM productos WHERE id_producto = %s"
            self.cursor.execute(query, (id_producto,))
            return self.cursor.fetchone()
        except Exception as e:
            print(f"Error: {e}")
            return None

    def crear_producto(self, codigo, nombre, id_categoria, precio_compra, precio_venta, stock, stock_minimo):
        """Crea un nuevo producto"""
        try:
            query = """
            INSERT INTO productos (codigo_producto, nombre_producto, id_categoria, 
                                precio_compra, precio_venta, stock_actual, stock_minimo, estado)
            VALUES (%s, %s, %s, %s, %s, %s, %s, TRUE)
            """
            self.cursor.execute(query, (codigo, nombre, id_categoria, precio_compra, precio_venta, stock, stock_minimo))
            self.conexion.commit()
            return True, "Producto creado exitosamente"
        except Exception as e:
            return False, str(e)

    def crear_cliente(self, nombre, apellido, email, telefono, tipo_cliente, documento, ciudad):
        """Crea un nuevo cliente"""
        try:
            query = """
            INSERT INTO clientes (nombre_cliente, apellido_cliente, email_cliente, telefono, 
                                tipo_cliente, documento_identidad, ciudad, estado)
            VALUES (%s, %s, %s, %s, %s, %s, %s, TRUE)
            """
            self.cursor.execute(query, (nombre, apellido, email, telefono, tipo_cliente, documento, ciudad))
            self.conexion.commit()
            return True, "Cliente creado exitosamente"
        except Exception as e:
            return False, str(e)

    def actualizar_stock(self, id_producto, cantidad, tipo_movimiento, id_usuario, motivo):
        try:
            args = [id_producto, cantidad, tipo_movimiento, id_usuario, motivo, '']
            self.cursor.callproc('sp_actualizar_stock', args)
            self.conexion.commit()
            return True, "Stock actualizado"
        except Exception as e:
            return False, str(e)
        
    def actualizar_stock_producto(self, codigo_producto, nuevo_stock):
        """Actualiza el stock de un producto por código"""
        try:
            query = "UPDATE productos SET stock_actual = %s WHERE codigo_producto = %s"
            self.cursor.execute(query, (nuevo_stock, codigo_producto))
            self.conexion.commit()
            return True, "Stock actualizado"
        except Exception as e:
            return False, str(e)
        
    def actualizar_producto(self, codigo, nombre, precio_compra, precio_venta, stock, stock_minimo):
        """Actualiza un producto existente"""
        try:
            query = """
            UPDATE productos 
            SET nombre_producto = %s, precio_compra = %s, precio_venta = %s, 
                stock_actual = %s, stock_minimo = %s
            WHERE codigo_producto = %s
            """
            self.cursor.execute(query, (nombre, precio_compra, precio_venta, stock, stock_minimo, codigo))
            self.conexion.commit()
            return True, "Producto actualizado exitosamente"
        except Exception as e:
            return False, str(e)

    def actualizar_cliente(self, id_cliente, nombre, apellido, email, telefono, tipo, ciudad):
        """Actualiza un cliente existente"""
        try:
            query = """
            UPDATE clientes
            SET nombre_cliente = %s, apellido_cliente = %s, email_cliente = %s,
                telefono = %s, tipo_cliente = %s, ciudad = %s
            WHERE id_cliente = %s
            """
            self.cursor.execute(query, (nombre, apellido, email, telefono, tipo, ciudad, id_cliente))
            self.conexion.commit()
            return True, "Cliente actualizado exitosamente"
        except Exception as e:
            return False, str(e)