# 🏗️ ARQUITECTURA DEL SISTEMA POS

## Diagrama de Componentes

```
┌─────────────────────────────────────────────────────────────────┐
│                     CLIENTE (Frontend)                          │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  Navegador Web                                            │  │
│  │  - Dashboard                                              │  │
│  │  - Registro de Ventas                                     │  │
│  │  - Gestión de Productos                                  │  │
│  │  - Gestión de Clientes                                   │  │
│  │  - Reportes                                              │  │
│  └───────────────────────────────────────────────────────────┘  │
└────────────────────┬────────────────────────────────────────────┘
                     │ HTTP/HTTPS
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│             APLICACIÓN WEB (Backend - Flask)                    │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  Rutas y Controladores                                    │  │
│  │  ├─ /login          → Autenticación                       │  │
│  │  ├─ /ventas         → Gestión de ventas                   │  │
│  │  ├─ /productos      → Gestión de inventario               │  │
│  │  ├─ /clientes       → Gestión de clientes                 │  │
│  │  ├─ /reportes       → Generación de reportes              │  │
│  │  ├─ /api/*          → Endpoints REST                      │  │
│  │  └─ /dashboard      → Panel de control                    │  │
│  │                                                            │  │
│  │  Middleware                                               │  │
│  │  ├─ Autenticación (Session)                               │  │
│  │  ├─ Control de Acceso (Roles)                             │  │
│  │  └─ Manejo de Errores                                     │  │
│  └───────────────────────────────────────────────────────────┘  │
└────────────────┬────────────────────────┬──────────────────────┘
                 │                        │
              TCP:3306              TCP:5432
                 │                        │
    ┌────────────▼────────────┐    ┌──────▼────────────┐
    │  BASE DE DATOS MySQL    │    │  Procesador de    │
    │  ┌───────────────────┐  │    │  Notificaciones   │
    │  │ Tablas            │  │    │  ┌─────────────┐  │
    │  │ ├─ usuarios       │  │    │  │ Python      │  │
    │  │ ├─ productos      │  │    │  │             │  │
    │  │ ├─ categorias     │  │    │  │ Lee: Cola   │  │
    │  │ ├─ clientes       │  │    │  │ notif.      │  │
    │  │ ├─ ventas         │  │    │  │             │  │
    │  │ ├─ detalles_venta │  │    │  │ Envía:      │  │
    │  │ ├─ movimientos    │  │    │  │ Emails SMTP │  │
    │  │ └─ notificaciones │  │    │  └─────────────┘  │
    │  │                   │  │    └──────┬────────────┘
    │  │ Stored Procedures │  │           │
    │  │ ├─ sp_registrar   │  │           │ SMTP:587
    │  │ ├─ sp_crear       │  │           │
    │  │ ├─ sp_reporte     │  │           ▼
    │  │ └─ sp_actualizar  │  │    ┌─────────────────┐
    │  │                   │  │    │ Servidor SMTP   │
    │  │ Funciones         │  │    │ (Gmail, etc.)   │
    │  │ ├─ calcular_iva   │  │    └─────────────────┘
    │  │ ├─ validar_email  │  │
    │  │ └─ verificar_stock│  │
    │  │                   │  │
    │  │ Triggers          │  │
    │  │ ├─ Validaciones   │  │
    │  │ ├─ Auditoría      │  │
    │  │ └─ Notificaciones │  │
    │  └───────────────────┘  │
    └────────────────────────┘
```

## Flujo de Datos - Caso: Registrar Venta

```
USUARIO
  │
  │ (Selecciona productos y cliente)
  ▼
INTERFAZ WEB
  │ (POST /api/ventas)
  ▼
FLASK APP
  │ (Valida sesión y permiso)
  ▼
CONEXION_POS.registrar_venta()
  │
  │ (Prepara JSON de productos)
  ▼
MySQL SP: sp_registrar_venta()
  │
  ├─ Valida usuario
  ├─ Valida cliente
  ├─ Genera número de venta
  ├─ Calcula subtotal y IVA (función calcular_iva)
  ├─ INSERT en tabla ventas
  ├─ INSERT en tabla detalles_venta
  ├─ UPDATE stock en tabla productos
  │
  └─ TRIGGER: trigger_notificar_venta_realizada
      │
      └─ INSERT en tabla notificaciones_correo
          │
          ▼
PROCESADOR_NOTIFICACIONES.py
  │ (Cada 5 minutos)
  ├─ Lee notificaciones_correo (WHERE enviada = FALSE)
  ├─ Envía email por SMTP
  └─ UPDATE notificaciones_correo (enviada = TRUE)
      │
      ▼
GERENTE RECIBE EMAIL
```

## Estructura de Directorios del Proyecto

```
proyecto_pos/
│
├── 📄 Archivos Raíz
│   ├── .env                          # Configuración de entorno
│   ├── .env.example                  # Ejemplo de configuración
│   ├── requirements.txt              # Dependencias Python
│   ├── gunicorn_config.py           # Config para producción
│   └── ecosystem.config.js          # Config PM2
│
├── 🗄️ Base de Datos
│   ├── 01_schema_pos.sql            # Script de creación
│   ├── backup/                      # Respaldos automáticos
│   └── migrations/                  # Migraciones futuras
│
├── 🐍 Backend Python
│   ├── conexion_pos.py              # Clase de conexión
│   ├── app_flask.py                 # Aplicación web principal
│   ├── procesador_notificaciones.py # Servicio de emails
│   ├── ejemplos_uso.py              # Ejemplos de código
│   └── config_notificaciones.ini    # Config de emails
│
├── 🎨 Frontend (Opcional)
│   ├── templates/
│   │   ├── base.html
│   │   ├── login.html
│   │   ├── dashboard.html
│   │   ├── ventas.html
│   │   ├── productos.html
│   │   ├── clientes.html
│   │   └── reportes.html
│   └── static/
│       ├── css/
│       │   └── style.css
│       ├── js/
│       │   └── app.js
│       └── img/
│
├── 📝 Documentación
│   ├── README.md                    # Guía principal
│   ├── INSTALACION_COMPLETA.md      # Instalación detallada
│   ├── DEPLOYMENT_PRODUCCION.md     # Deployment
│   └── ARQUITECTURA.md              # Este archivo
│
├── 📦 Dependencias Instaladas
│   └── venv/                        # Entorno virtual
│       ├── bin/
│       ├── lib/
│       └── include/
│
└── 📊 Logs y Datos
    ├── logs/
    │   ├── access.log
    │   ├── error.log
    │   ├── notificaciones_pos.log
    │   └── gunicorn.pid
    └── backups/
        └── pos_backup_*.sql.gz
```

## Modelo de Datos (ER)

```
┌──────────────────┐
│    USUARIOS      │
├──────────────────┤
│ id_usuario (PK)  │
│ nombre           │
│ email (UNIQUE)   │
│ contraseña       │
│ rol              │
│ estado           │
└────────┬─────────┘
         │
         │ 1:N (Crea)
         │
    ┌────▼─────────────────────────────┐
    │         VENTAS                   │
    ├────────────────────────────────┤
    │ id_venta (PK)                  │
    │ id_usuario (FK) ──────┐        │
    │ id_cliente (FK) ───┐  │        │
    │ numero_venta       │  │        │
    │ fecha_venta        │  │        │
    │ subtotal           │  │        │
    │ impuesto           │  │        │
    │ descuento          │  │        │
    │ total              │  │        │
    │ metodo_pago        │  │        │
    │ estado             │  │        │
    └────┬───────────────┬──┼────────┘
         │               │  │
         │               │  │
         │ 1:N           │  │ 1:N (Realiza)
         │ (Registra)    │  │
         │               │  │
    ┌────▼────────────────────┐       ┌──────────────────┐
    │   DETALLES_VENTA        │       │    CLIENTES      │
    ├─────────────────────────┤       ├──────────────────┤
    │ id_detalle (PK)         │       │ id_cliente (PK)  │
    │ id_venta (FK) ◄─────────┘       │ nombre           │
    │ id_producto (FK) ───┐           │ apellido         │
    │ cantidad            │           │ email            │
    │ precio_unitario     │           │ telefono         │
    │ descuento_linea     │           │ documento        │
    │ subtotal_linea      │           │ tipo_cliente     │
    └─────────────────────┘           │ estado           │
         │                            └──────────────────┘
         │ N:1 (Contiene)
         │
    ┌────▼──────────────────────────┐
    │      PRODUCTOS               │
    ├──────────────────────────────┤
    │ id_producto (PK)             │
    │ id_categoria (FK) ──────┐    │
    │ codigo (UNIQUE)        │    │
    │ nombre                 │    │
    │ descripcion            │    │
    │ precio_compra          │    │
    │ precio_venta           │    │
    │ stock_actual           │    │
    │ stock_minimo           │    │
    │ estado                 │    │
    └────┬─────────────────────────┘
         │                │
         │ N:1            │ 1:N (Tiene)
         │                │
         │          ┌─────▼────────────────┐
         │          │   CATEGORIAS         │
         │          ├──────────────────────┤
         │          │ id_categoria (PK)    │
         │          │ nombre (UNIQUE)      │
         │          │ descripcion          │
         │          │ estado               │
         │          └──────────────────────┘
         │
         │ 1:N (Genera)
         │
    ┌────▼──────────────────────────────┐
    │  MOVIMIENTOS_INVENTARIO           │
    ├───────────────────────────────────┤
    │ id_movimiento (PK)                │
    │ id_producto (FK)                  │
    │ id_usuario (FK)                   │
    │ tipo_movimiento                   │
    │ cantidad_movimiento               │
    │ cantidad_anterior                 │
    │ cantidad_nueva                    │
    │ fecha_movimiento                  │
    └───────────────────────────────────┘

Tabla Adicional (Sin relaciones en diagrama)
┌──────────────────────────────┐
│  NOTIFICACIONES_CORREO       │
├──────────────────────────────┤
│ id_notificacion (PK)         │
│ destinatario                 │
│ asunto                       │
│ cuerpo                       │
│ tipo_notificacion            │
│ enviada                      │
│ fecha_creacion               │
│ fecha_envio                  │
└──────────────────────────────┘
```

## Ciclo de Vida de una Venta

```
1. INICIO
   └─ Usuario inicia sesión
      └─ Sistema valida credenciales

2. PREPARACIÓN
   └─ Usuario selecciona cliente
      └─ Sistema carga datos del cliente

3. SELECCIÓN DE PRODUCTOS
   └─ Usuario agrega productos
      ├─ Valida stock disponible
      ├─ Calcula precio total
      └─ Muestra impuesto (IVA 19%)

4. PROCESAMIENTO DE PAGO
   └─ Usuario selecciona método de pago
      ├─ Efectivo
      ├─ Tarjeta
      ├─ Transferencia
      └─ Cheque

5. REGISTRO EN BD
   ├─ sp_registrar_venta() es llamado
   ├─ Valida usuario y cliente
   ├─ Genera número único de venta
   ├─ Inserta en tabla VENTAS
   ├─ Inserta en tabla DETALLES_VENTA
   ├─ Actualiza PRODUCTOS (stock_actual)
   ├─ Registra movimiento en MOVIMIENTOS_INVENTARIO
   └─ Retorna confirmación

6. TRIGGER AUTOMÁTICO
   ├─ trigger_notificar_venta_realizada se ejecuta
   └─ Inserta notificación en NOTIFICACIONES_CORREO

7. PROCESAMIENTO ASÍNCRONO
   └─ procesador_notificaciones.py
      ├─ Lee notificaciones pendientes
      ├─ Conecta a servidor SMTP
      ├─ Envía email al gerente
      └─ Marca como enviada en BD

8. FINALIZACIÓN
   └─ Usuario recibe confirmación
      ├─ Número de venta
      ├─ Comprobante imprimible
      └─ Opción para nueva venta
```

## Seguridad - Capas de Protección

```
┌─────────────────────────────────┐
│   CAPA 1: FRONTEND              │
│   - Validación de entrada JS    │
│   - HTTPS/SSL                   │
└──────────────┬──────────────────┘
               │
┌──────────────▼──────────────────┐
│   CAPA 2: APLICACIÓN WEB        │
│   - Autenticación (Session)     │
│   - Control de Roles            │
│   - Validación de parámetros    │
│   - Prevención CSRF             │
└──────────────┬──────────────────┘
               │
┌──────────────▼──────────────────┐
│   CAPA 3: BD - CONSTRAINTS      │
│   - Validaciones CHECK          │
│   - Foreign Keys                │
│   - NOT NULL                    │
│   - UNIQUE                      │
└──────────────┬──────────────────┘
               │
┌──────────────▼──────────────────┐
│   CAPA 4: BD - PROCEDIMIENTOS   │
│   - Lógica validación compleja  │
│   - Transacciones ACID          │
│   - Encriptación contraseña     │
└─────────────────────────────────┘
```

## Rendimiento - Índices

```
TABLA: productos
├─ PK: id_producto
├─ IDX: id_categoria
├─ IDX: codigo_producto (búsquedas por código)
├─ IDX: stock_actual (filtrar bajo stock)
└─ IDX: estado

TABLA: ventas
├─ PK: id_venta
├─ FK: id_usuario, id_cliente
├─ IDX: fecha_venta (reportes por período)
├─ IDX: estado (filtrar completadas)
└─ IDX: numero_venta (búsquedas)

TABLA: clientes
├─ PK: id_cliente
├─ IDX: documento_identidad (búsqueda)
├─ IDX: email_cliente (búsqueda)
└─ UNIQUE: documento

TABLA: usuarios
├─ PK: id_usuario
├─ IDX: rol (filtrar por rol)
└─ UNIQUE: email
```

## Integración con Otros Sistemas

```
┌──────────────────────────────────────┐
│    SISTEMA POS                       │
└─────────────┬──────────────────────┬─┘
              │                      │
              │ API REST             │ Base de Datos
              │                      │
      ┌───────▼────────┐    ┌────────▼─────────┐
      │ Integraciones  │    │ Backups          │
      │ - Facturación  │    │ - SQL Dumper     │
      │ - E-commerce   │    │ - Cloud Storage  │
      │ - Contabilidad │    │ - Replicas       │
      │ - Analítica    │    └──────────────────┘
      └────────────────┘
```

## Escalabilidad Futura

```
DESARROLLO ACTUAL (Monolítico)
└─ 1 BD
   └─ 1 Aplicación Web
      └─ 1 Procesador Notificaciones

FASE 2 (Escalado Horizontal)
├─ BD Principal + Réplicas
├─ Load Balancer
├─ N Instancias App Web
└─ Caché Redis

FASE 3 (Microservicios)
├─ Servicio Autenticación
├─ Servicio Ventas
├─ Servicio Inventario
├─ Servicio Notificaciones
└─ API Gateway
```

---

**Documentación de Arquitectura Completa**
