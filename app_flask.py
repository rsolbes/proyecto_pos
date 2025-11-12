from flask import Flask, render_template, request, session, redirect, url_for, jsonify
from functools import wraps
from conexion_pos import ConexionPOS
import json

app = Flask(__name__)
app.secret_key = 'tu_clave_secreta_super_segura_12345'

def requerir_login(f):
    @wraps(f)
    def decorador(*args, **kwargs):
        if 'usuario_id' not in session:
            return redirect(url_for('login'))
        return f(*args, **kwargs)
    return decorador

def requerir_admin(f):
    @wraps(f)
    def decorador(*args, **kwargs):
        if 'usuario_id' not in session:
            return redirect(url_for('login'))
        if session.get('usuario_rol') != 'administrador':
            return redirect(url_for('dashboard'))
        return f(*args, **kwargs)
    return decorador

@app.route('/')
def index():
    if 'usuario_id' in session:
        return redirect(url_for('dashboard'))
    return redirect(url_for('login'))

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        email = request.form.get('email', '').strip()
        contraseña = request.form.get('contraseña', '')
        
        if not email or not contraseña:
            return render_template('login.html', error='Email y contraseña son requeridos')
        
        try:
            conn = ConexionPOS()
            usuario = conn.autenticar_usuario(email, contraseña)
            conn.cerrar()
            
            if usuario:
                session['usuario_id'] = usuario['id_usuario']
                session['usuario_nombre'] = usuario['nombre']
                session['usuario_email'] = usuario['email']
                session['usuario_rol'] = usuario['rol']
                session['usuario_autenticado'] = True
                return redirect(url_for('dashboard'))
            else:
                return render_template('login.html', error='Email o contraseña incorrectos')
        except Exception as e:
            return render_template('login.html', error='Error al conectar con la base de datos')
    
    return render_template('login.html')

@app.route('/logout')
def logout():
    session.clear()
    return redirect(url_for('login'))

@app.route('/dashboard')
@requerir_login
def dashboard():
    try:
        conn = ConexionPOS()
        ventas_hoy = conn.obtener_ventas_hoy()
        ventas_mes = conn.obtener_ventas_mes()
        cantidad_productos = conn.contar_productos()
        bajo_stock = conn.contar_bajo_stock()
        conn.cerrar()
        
        return render_template('dashboard.html',
                             usuario_nombre=session.get('usuario_nombre'),
                             usuario_rol=session.get('usuario_rol'),
                             usuario_autenticado=True,
                             total_hoy=ventas_hoy,
                             total_mes=ventas_mes,
                             cantidad_productos=cantidad_productos,
                             bajo_stock=bajo_stock)
    except Exception as e:
        print(f"Error: {e}")
        return render_template('dashboard.html',
                             usuario_nombre=session.get('usuario_nombre'),
                             usuario_rol=session.get('usuario_rol'),
                             usuario_autenticado=True,
                             total_hoy=0,
                             total_mes=0,
                             cantidad_productos=0,
                             bajo_stock=0)

@app.route('/ventas')
@requerir_login
def ventas():
    return render_template('ventas.html',
                         usuario_autenticado=True,
                         usuario_nombre=session.get('usuario_nombre'),
                         usuario_rol=session.get('usuario_rol'))

@app.route('/productos')
@requerir_login
def productos():
    return render_template('productos.html',
                         usuario_autenticado=True,
                         usuario_nombre=session.get('usuario_nombre'),
                         usuario_rol=session.get('usuario_rol'))

@app.route('/agregar-productos')
@requerir_admin
def agregar_productos():
    try:
        conn = ConexionPOS()
        categorias = conn.obtener_categorias()
        conn.cerrar()
        
        return render_template('agregar_productos.html',
                             usuario_autenticado=True,
                             usuario_nombre=session.get('usuario_nombre'),
                             usuario_rol=session.get('usuario_rol'),
                             categorias=categorias)
    except Exception as e:
        return render_template('agregar_productos.html',
                             usuario_autenticado=True,
                             usuario_nombre=session.get('usuario_nombre'),
                             usuario_rol=session.get('usuario_rol'),
                             categorias=[])

@app.route('/clientes')
@requerir_login
def clientes():
    return render_template('clientes.html',
                         usuario_autenticado=True,
                         usuario_nombre=session.get('usuario_nombre'),
                         usuario_rol=session.get('usuario_rol'))

@app.route('/agregar-clientes')
@requerir_admin
def agregar_clientes():
    return render_template('agregar_clientes.html',
                         usuario_autenticado=True,
                         usuario_nombre=session.get('usuario_nombre'),
                         usuario_rol=session.get('usuario_rol'))

@app.route('/historial-ventas')
@requerir_admin
def historial_ventas():
    return render_template('historial_ventas.html',
                         usuario_autenticado=True,
                         usuario_nombre=session.get('usuario_nombre'),
                         usuario_rol=session.get('usuario_rol'))

@app.route('/reportes')
@requerir_admin
def reportes():
    return render_template('reportes.html',
                         usuario_autenticado=True,
                         usuario_nombre=session.get('usuario_nombre'),
                         usuario_rol=session.get('usuario_rol'))

@app.route('/usuarios')
@requerir_admin
def usuarios():
    return render_template('usuarios.html',
                         usuario_autenticado=True,
                         usuario_nombre=session.get('usuario_nombre'),
                         usuario_rol=session.get('usuario_rol'))

# ==================== API ROUTES - PRODUCTOS ====================

@app.route('/api/productos', methods=['GET'])
@requerir_login
def api_productos():
    try:
        conn = ConexionPOS()
        productos = conn.obtener_productos()
        conn.cerrar()
        return jsonify(productos if productos else [])
    except Exception as e:
        print(f"Error: {e}")
        return jsonify([])

@app.route('/api/productos', methods=['POST'])
@requerir_admin
def api_crear_producto():
    try:
        datos = request.get_json()
        
        # Validaciones
        if not datos.get('codigo_producto') or not datos.get('nombre_producto'):
            return jsonify({'exito': False, 'error': 'Código y nombre son requeridos'})
        
        precio_compra = float(datos.get('precio_compra', 0))
        precio_venta = float(datos.get('precio_venta', 0))
        stock = int(datos.get('stock_actual', 0))
        stock_minimo = int(datos.get('stock_minimo', 0))
        
        if precio_compra <= 0 or precio_venta <= 0:
            return jsonify({'exito': False, 'error': 'Los precios deben ser mayores a 0'})
        
        if stock < 0 or stock_minimo < 0:
            return jsonify({'exito': False, 'error': 'El stock no puede ser negativo'})
        
        if precio_venta < precio_compra:
            return jsonify({'exito': False, 'error': 'El precio de venta debe ser mayor al de compra'})
        
        conn = ConexionPOS()
        
        # Si es actualización
        if datos.get('es_actualizacion'):
            resultado = conn.actualizar_producto(
                datos.get('codigo_producto').strip(),
                datos.get('nombre_producto').strip(),
                precio_compra,
                precio_venta,
                stock,
                stock_minimo
            )
        else:
            # Si es nuevo producto
            resultado = conn.crear_producto(
                datos.get('codigo_producto').strip(),
                datos.get('nombre_producto').strip(),
                int(datos.get('id_categoria', 1)),
                precio_compra,
                precio_venta,
                stock,
                stock_minimo
            )
        
        conn.cerrar()
        
        if resultado[0]:
            return jsonify({'exito': True, 'mensaje': resultado[1]})
        else:
            return jsonify({'exito': False, 'error': resultado[1]})
    except ValueError:
        return jsonify({'exito': False, 'error': 'Formato de datos inválido'})
    except Exception as e:
        return jsonify({'exito': False, 'error': str(e)})
    
@app.route('/api/actualizar-stock', methods=['POST'])
@requerir_admin
def api_actualizar_stock():
    try:
        datos = request.get_json()
        
        if not datos.get('codigo_producto'):
            return jsonify({'exito': False, 'error': 'Código de producto requerido'})
        
        stock = int(datos.get('stock_actual', 0))
        
        if stock < 0:
            return jsonify({'exito': False, 'error': 'El stock no puede ser negativo'})
        
        conn = ConexionPOS()
        resultado = conn.actualizar_stock_producto(
            datos.get('codigo_producto'),
            stock
        )
        conn.cerrar()
        
        if resultado[0]:
            return jsonify({'exito': True})
        else:
            return jsonify({'exito': False, 'error': resultado[1]})
    except ValueError:
        return jsonify({'exito': False, 'error': 'Datos inválidos'})
    except Exception as e:
        return jsonify({'exito': False, 'error': str(e)})

# ==================== API ROUTES - CLIENTES ====================

@app.route('/api/clientes', methods=['GET'])
@requerir_login
def api_clientes():
    try:
        conn = ConexionPOS()
        clientes = conn.obtener_clientes()
        conn.cerrar()
        return jsonify(clientes if clientes else [])
    except Exception as e:
        print(f"Error: {e}")
        return jsonify([])

@app.route('/api/clientes', methods=['POST'])
@requerir_admin
def api_crear_cliente():
    try:
        datos = request.get_json()
        
        # Validaciones
        if not datos.get('nombre_cliente') or not datos.get('apellido_cliente'):
            return jsonify({'exito': False, 'error': 'Nombre y apellido son requeridos'})
        
        if not datos.get('documento_identidad'):
            return jsonify({'exito': False, 'error': 'Documento de identidad es requerido'})
        
        email = datos.get('email_cliente', '').strip()
        if email and '@' not in email:
            return jsonify({'exito': False, 'error': 'Email inválido'})
        
        conn = ConexionPOS()
        resultado = conn.crear_cliente(
            datos.get('nombre_cliente').strip(),
            datos.get('apellido_cliente').strip(),
            email,
            datos.get('telefono', '').strip(),
            datos.get('tipo_cliente', 'regular'),
            datos.get('documento_identidad').strip(),
            datos.get('ciudad', '').strip()
        )
        conn.cerrar()
        
        if resultado[0]:
            return jsonify({'exito': True, 'mensaje': 'Cliente creado exitosamente'})
        else:
            return jsonify({'exito': False, 'error': resultado[1]})
    except Exception as e:
        return jsonify({'exito': False, 'error': str(e)})
    
@app.route('/api/clientes/<int:id_cliente>', methods=['PUT'])
@requerir_admin
def api_actualizar_cliente(id_cliente):
    try:
        datos = request.get_json()
        
        if not datos.get('nombre_cliente') or not datos.get('apellido_cliente'):
            return jsonify({'exito': False, 'error': 'Nombre y apellido son requeridos'})
        
        email = datos.get('email_cliente', '').strip()
        if email and '@' not in email:
            return jsonify({'exito': False, 'error': 'Email inválido'})
        
        conn = ConexionPOS()
        resultado = conn.actualizar_cliente(
            id_cliente,
            datos.get('nombre_cliente').strip(),
            datos.get('apellido_cliente').strip(),
            email,
            datos.get('telefono', '').strip(),
            datos.get('tipo_cliente', 'regular'),
            datos.get('ciudad', '').strip()
        )
        conn.cerrar()
        
        if resultado[0]:
            return jsonify({'exito': True})
        else:
            return jsonify({'exito': False, 'error': resultado[1]})
    except Exception as e:
        return jsonify({'exito': False, 'error': str(e)})

# ==================== API ROUTES - VENTAS ====================

@app.route('/api/ventas-list', methods=['GET'])
@requerir_admin
def api_ventas_list():
    try:
        conn = ConexionPOS()
        ventas = conn.obtener_ventas()
        conn.cerrar()
        return jsonify(ventas if ventas else [])
    except Exception as e:
        print(f"Error: {e}")
        return jsonify([])

@app.route('/api/ventas', methods=['POST'])
@requerir_login
def api_registrar_venta():
    try:
        datos = request.get_json()
        
        # Validaciones
        if not datos.get('id_cliente'):
            return jsonify({'exito': False, 'error': 'Selecciona un cliente'})
        
        productos = datos.get('productos', [])
        if not productos:
            return jsonify({'exito': False, 'error': 'Agrega al menos un producto'})
        
        # Validar que las cantidades sean positivas
        for p in productos:
            if int(p.get('cantidad', 0)) <= 0:
                return jsonify({'exito': False, 'error': 'La cantidad debe ser mayor a 0'})
        
        # Validar stock disponible
        conn = ConexionPOS()
        for p in productos:
            producto = conn.obtener_producto_por_id(p['id_producto'])
            if not producto:
                conn.cerrar()
                return jsonify({'exito': False, 'error': 'Producto no encontrado'})
            
            if p['cantidad'] > producto['stock_actual']:
                conn.cerrar()
                return jsonify({'exito': False, 'error': f"Stock insuficiente para {producto['nombre_producto']}"})
        
        id_usuario = session.get('usuario_id')
        id_cliente = datos.get('id_cliente')
        metodo_pago = datos.get('metodo_pago')
        descuento = max(0, float(datos.get('descuento', 0)))  # No permitir descuentos negativos
        
        productos_json = json.dumps([
            {'id_producto': p['id_producto'], 'cantidad': int(p['cantidad'])}
            for p in productos
        ])
        
        resultado = conn.registrar_venta(
            id_usuario, id_cliente, metodo_pago, productos_json, descuento
        )
        
        conn.cerrar()
        
        if resultado[0]:
            return jsonify({'exito': True, 'mensaje': 'Venta registrada exitosamente'})
        else:
            return jsonify({'exito': False, 'error': resultado[1]})
    except ValueError:
        return jsonify({'exito': False, 'error': 'Datos inválidos'})
    except Exception as e:
        print(f"Error: {e}")
        return jsonify({'exito': False, 'error': str(e)})

# ==================== API ROUTES - USUARIOS ====================

@app.route('/api/usuarios', methods=['GET'])
@requerir_admin
def api_usuarios():
    try:
        conn = ConexionPOS()
        usuarios = conn.obtener_usuarios()
        conn.cerrar()
        return jsonify(usuarios if usuarios else [])
    except Exception as e:
        return jsonify([])

@app.route('/api/usuarios', methods=['POST'])
@requerir_admin
def api_crear_usuario():
    try:
        datos = request.get_json()
        
        # Validaciones
        if not datos.get('nombre') or not datos.get('email') or not datos.get('contraseña'):
            return jsonify({'exito': False, 'error': 'Todos los campos son requeridos'})
        
        if len(datos.get('contraseña', '')) < 6:
            return jsonify({'exito': False, 'error': 'La contraseña debe tener al menos 6 caracteres'})
        
        if '@' not in datos.get('email', ''):
            return jsonify({'exito': False, 'error': 'Email inválido'})
        
        conn = ConexionPOS()
        resultado = conn.crear_usuario(
            datos.get('nombre').strip(),
            datos.get('email').strip(),
            datos.get('contraseña'),
            datos.get('rol')
        )
        conn.cerrar()
        
        if resultado[0]:
            return jsonify({'exito': True})
        else:
            return jsonify({'exito': False, 'error': resultado[1]})
    except Exception as e:
        return jsonify({'exito': False, 'error': str(e)})

# ==================== API ROUTES - REPORTES ====================

@app.route('/api/reportes/ventas', methods=['POST'])
@requerir_admin
def api_reportes_ventas():
    try:
        datos = request.get_json()
        conn = ConexionPOS()
        
        reporte = conn.obtener_reporte_ventas(
            datos.get('fecha_inicio'),
            datos.get('fecha_fin')
        )
        conn.cerrar()
        return jsonify(reporte if reporte else [])
    except Exception as e:
        print(f"Error: {e}")
        return jsonify([])

# ==================== API ROUTES - CATEGORÍAS ====================

@app.route('/api/categorias', methods=['GET'])
@requerir_login
def api_categorias():
    try:
        conn = ConexionPOS()
        categorias = conn.obtener_categorias()
        conn.cerrar()
        return jsonify(categorias if categorias else [])
    except Exception as e:
        return jsonify([])

# ==================== MANEJO DE ERRORES ====================

@app.errorhandler(404)
def no_encontrado(error):
    return render_template('404.html'), 404

@app.errorhandler(500)
def error_servidor(error):
    return render_template('500.html'), 500

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)