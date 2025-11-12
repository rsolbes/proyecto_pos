# 🏗️ ARQUITECTURA - Sistema POS

Documentación técnica de la arquitectura del Sistema de Punto de Venta.

## 📊 Diagrama General

```
┌─────────────────────────────────────────────────────────────┐
│                    CLIENTE (Frontend)                        │
│  HTML5 | CSS3 | JavaScript Vanilla | Responsive Design      │
└──────────────────────┬──────────────────────────────────────┘
                       │ HTTP/HTTPS
┌──────────────────────▼──────────────────────────────────────┐
│              SERVIDOR WEB (Flask - Python)                   │
│  - Rutas HTTP/REST                                          │
│  - Validaciones de negocio                                  │
│  - Control de permisos                                      │
│  - Manejo de sesiones                                       │
└──────────────────────┬──────────────────────────────────────┘
                       │
┌──────────────────────┴──────────────────────────────────────┐
│                   CAPAS DE APLICACIÓN                        │
├─────────────────────────────────────────────────────────────┤
│ app_flask.py          - Rutas y endpoints principales       │
│ conexion_pos.py       - Lógica de conexión a BD             │
│ procesador_notificaciones.py - Envío de emails             │
└──────────────────────┬──────────────────────────────────────┘
                       │ MySQL Protocol
┌──────────────────────▼──────────────────────────────────────┐
│            BASE DE DATOS (MySQL 5.7+)                        │
│  - Tablas normalizadas                                      │
│  - Stored Procedures                                        │
│  - Triggers                                                 │
│  - Funciones                                                │
└─────────────────────────────────────────────────────────────┘
```

---

## 🗂️ ESTRUCTURA DE CARPETAS

```
proyecto_pos/
│
├── static/                          # Archivos estáticos
│   ├── css/
│   │   └── style.css               # Estilos CSS (Responsive)
│   └── js/
│       └── app.js                  # Funciones JavaScript globales
│
├── templates/                       # Templates HTML (Jinja2)
│   ├── base.html                   # Template base (Navbar, estructura)
│   ├── login.html                  # Página de login
│   ├── dashboard.html              # Dashboard principal
│   ├── ventas.html                 # Formulario de ventas
│   ├── productos.html              # Listado y búsqueda de productos
│   ├── agregar_productos.html      # Crear/agregar stock a productos
│   ├── clientes.html               # Listado de clientes
│   ├── agregar_clientes.html       # Crear clientes
│   ├── historial_ventas.html       # Historial de ventas (Admin)
│   ├── reportes.html               # Reportes (Admin)
│   ├── usuarios.html               # Gestión de usuarios (Admin)
│   ├── 404.html                    # Página no encontrada
│   └── 500.html                    # Error del servidor
│
├── venv/                           # Entorno virtual (no versionar)
│
├── app_flask.py                    # 🔧 Aplicación principal
│   ├── Rutas GET/POST
│   ├── Decoradores de autenticación
│   ├── Endpoints API REST
│   └── Manejo de errores
│
├── conexion_pos.py                 # 🔌 Conexión a BD
│   ├── Clase ConexionPOS
│   ├── Métodos CRUD
│   ├── Consultas SQL
│   └── Validaciones
│
├── procesador_notificaciones.py    # 📧 Sistema de notificaciones
│   ├── Envío de emails
│   ├── Lectura de configuración
│   └── Logging
│
├── config_notificaciones.ini       # ⚙️ Configuración de emails
│
├── 01_schema_pos.sql               # 🗄️ Schema de BD (tablas)
│
├── procedures_final.sql            # 📝 Stored procedures
│
├── requirements.txt                # 📦 Dependencias Python
│
├── README.md                       # 📖 Guía de uso
│
├── ARQUITECTURA.md                 # 🏗️ Este archivo
│
├── DEPLOYMENT_PRODUCCION.md        # 🚀 Guía de deploy
│
├── .gitignore                      # 🚫 Archivos a ignorar en Git
│
└── notificaciones_pos.log          # 📋 Logs del procesador
```

---

## 🗄️ MODELO DE DATOS

### Tablas Principales

**USUARIOS**
- id_usuario (PK)
- nombre
- email (UNIQUE)
- contraseña (MD5)
- rol (vendedor, gerente, administrador)
- estado (BOOLEAN)
- fecha_creacion

**PRODUCTOS**
- id_producto (PK)
- codigo_producto (UNIQUE)
- nombre_producto
- id_categoria (FK)
- precio_compra
- precio_venta
- stock_actual
- stock_minimo
- estado

**CLIENTES**
- id_cliente (PK)
- nombre_cliente
- apellido_cliente
- email_cliente
- telefono
- tipo_cliente (regular, vip, mayorista)
- documento_identidad
- ciudad

**VENTAS**
- id_venta (PK)
- numero_venta (UNIQUE)
- id_usuario (FK)
- id_cliente (FK)
- subtotal
- impuesto (19% IVA)
- descuento
- total
- metodo_pago
- estado (completada, cancelada)

**DETALLES_VENTA**
- id_detalle (PK)
- id_venta (FK)
- id_producto (FK)
- cantidad
- precio_unitario
- subtotal_linea

**MOVIMIENTOS_INVENTARIO**
- id_movimiento (PK)
- id_producto (FK)
- id_usuario (FK)
- tipo_movimiento
- cantidad_movimiento
- motivo
- cantidad_anterior
- cantidad_nueva

**NOTIFICACIONES_CORREO**
- id_notificacion (PK)
- destinatario
- asunto
- cuerpo
- tipo_notificacion
- enviada
- fecha_creacion
- fecha_envio

---

## 🔄 FLUJO DE DATOS - Registrar una Venta

```
1. Usuario completa formulario de venta
   ↓
2. Frontend valida (cantidad > 0, cliente seleccionado)
   ↓
3. JavaScript envía POST a /api/ventas
   ↓
4. Flask valida permisos (requerir_login)
   ↓
5. app_flask.py llama a conexion_pos.registrar_venta()
   ↓
6. conexion_pos.py ejecuta sp_registrar_venta en BD
   ↓
7. Stored Procedure:
   ├─ Valida stock disponible
   ├─ Valida cantidad positiva
   ├─ Valida descuento no negativo
   ├─ Calcula subtotal, IVA (19%), descuentos
   ├─ Inserta registro en tabla ventas
   ├─ Inserta detalles en detalles_venta
   ├─ Actualiza stock de productos
   └─ Retorna ID de venta
   ↓
8. Trigger trigger_notificar_venta se ejecuta
   ├─ Crea registro en notificaciones_correo
   └─ Enviará email a rsolbes@hotmail.com
   ↓
9. Frontend recibe respuesta exitosa
   ↓
10. Mostrar alerta "Venta registrada exitosamente"
```

---

## 🔐 SEGURIDAD

### Autenticación y Autorización

```python
@requerir_login          # Solo usuarios autenticados
@requerir_admin          # Solo administradores
```

### Validaciones

**Backend:**
- Validación de permisos por rol
- Validación de tipos de datos
- Validación de rangos (stock > 0, precios > 0)
- Validación de emails formato
- No permite stock negativo
- No permite precios negativos
- No permite descuentos negativos

**Frontend:**
- Validación de cantidad positiva
- Validación de cliente seleccionado
- Búsqueda de productos con validación

**Base de Datos:**
- Constraints CHECK en precios y stock
- Constraints UNIQUE en email, codigo_producto
- Triggers para validar movimientos
- Stored Procedures con lógica de negocio

---

## 🌐 ENDPOINTS API REST

### Autenticación
```
POST   /login              → Iniciar sesión
GET    /logout             → Cerrar sesión
```

### Productos
```
GET    /api/productos              → Listar productos
POST   /api/productos              → Crear/Actualizar producto
GET    /api/categorias             → Listar categorías
POST   /api/actualizar-stock       → Agregar stock
```

### Clientes
```
GET    /api/clientes              → Listar clientes
POST   /api/clientes              → Crear cliente
PUT    /api/clientes/<id>         → Actualizar cliente
```

### Ventas
```
POST   /api/ventas                → Registrar venta
GET    /api/ventas-list           → Historial de ventas (Admin)
```

### Reportes (Admin)
```
POST   /api/reportes/ventas       → Reporte de ventas por período
```

### Usuarios (Admin)
```
GET    /api/usuarios              → Listar usuarios
POST   /api/usuarios              → Crear usuario
```

---

## 📧 SISTEMA DE NOTIFICACIONES

### Configuración

```ini
[correo]
smtp_server = smtp.gmail.com
smtp_port = 587
remitente = rsolbes05@gmail.com
contraseña = <contraseña_app>
destinatarios = rsolbes@hotmail.com
```

### Tipos de Notificaciones

1. **venta_realizada** - Cuando se registra una venta
2. **bajo_stock** - Cuando producto alcanza stock mínimo

### Procesamiento

El archivo `procesador_notificaciones.py`:
- Se ejecuta cada 5 minutos
- Lee la tabla `notificaciones_correo`
- Filtra registros no enviados
- Envía email
- Marca como enviado

---

## 🔧 TECNOLOGÍAS UTILIZADAS

| Capa | Tecnología | Versión |
|------|-----------|---------|
| Frontend | HTML5 / CSS3 / JavaScript | ES6+ |
| Backend | Flask | 3.0+ |
| Base de Datos | MySQL | 5.7+ |
| Python | Python | 3.8+ |
| Servidor | Werkzeug (desarrollo) | - |

---

## 👥 ROLES Y PERMISOS

| Función | Vendedor | Gerente | Admin |
|---------|----------|---------|-------|
| Ver Dashboard | ✓ | ✓ | ✓ |
| Registrar Ventas | ✓ | ✓ | ✓ |
| Ver Productos | ✓ | ✓ | ✓ |
| Agregar Productos | ✗ | ✗ | ✓ |
| Editar Productos | ✗ | ✗ | ✓ |
| Ver Clientes | ✓ | ✓ | ✓ |
| Agregar Clientes | ✗ | ✗ | ✓ |
| Editar Clientes | ✗ | ✗ | ✓ |
| Ver Historial | ✗ | ✓ | ✓ |
| Ver Reportes | ✗ | ✓ | ✓ |
| Gestionar Usuarios | ✗ | ✗ | ✓ |

