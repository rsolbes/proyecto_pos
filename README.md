# 🛒 Sistema POS (Point of Sale)

Sistema de Punto de Venta desarrollado con Flask, MySQL y JavaScript vanilla.

## USUARIOS (utilizando la schema adjunta)
usuario, contraseña
admin@empresa.com, admin123 (administrador)
juan@empresa.com, juan123, (vendedor),
carlos@empresa.com, carlos123 (gerente)

## Características

- ✅ Gestión de ventas en tiempo real
- ✅ Control de inventario/stock
- ✅ Gestión de clientes
- ✅ Gestión de usuarios (solo admin)
- ✅ Reportes de ventas
- ✅ Notificaciones por email
- ✅ Sistema de permisos por rol
- ✅ Interfaz responsiva y moderna

## Instalación

### Requisitos
- Python 3.8+
- MySQL 5.7+
- pip

### Pasos

1. **Clonar el repositorio**
```bash
git clone <tu-repo>
cd proyecto_pos
```

2. **Crear entorno virtual**
```bash
python3 -m venv venv
source venv/bin/activate  # En Windows: venv\Scripts\activate
```

3. **Instalar dependencias**
```bash
pip install -r requirements.txt
```

4. **Configurar base de datos**
```bash
mysql -u root -p < 01_schema_pos.sql
mysql -u root -p < procedures_final.sql
```

5. **Configurar emails (opcional)**
Edita `config_notificaciones.ini`:
```ini
[correo]
smtp_server = smtp.gmail.com
remitente = tu@gmail.com
contraseña = tu_contraseña_app
destinatarios = destino@gmail.com
```

6. **Ejecutar la aplicación**
```bash
python app_flask.py
```

Accede a: `http://localhost:5000`

## 👥 Roles y Permisos

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

## 📊 Estructura
```
proyecto_pos/
├── app_flask.py              # Aplicación principal
├── conexion_pos.py           # Conexión a BD
├── procesador_notificaciones.py  # Notificaciones
├── static/
│   ├── css/style.css
│   └── js/app.js
├── templates/                # HTML templates
├── 01_schema_pos.sql        # Schema BD
├── procedures_final.sql     # Stored procedures
├── config_notificaciones.ini # Config emails
└── requirements.txt         # Dependencias
```

## 🔐 Seguridad

- Contraseñas encriptadas con MD5
- Validaciones en backend y frontend
- Control de permisos por rol
- Protección contra stock negativo
- Validación de emails

## 📧 Notificaciones

Sistema automático de notificaciones:
- ✓ Nueva venta registrada
- ✓ Producto con stock bajo
- ✓ Actualizaciones de inventario

## 🐛 Troubleshooting

**Error de conexión a BD:**
```bash
mysql -u root -p
# Verifica que pos_system existe
SHOW DATABASES;
```

**Puerto 5000 en uso:**
```bash
# Cambiar puerto en app_flask.py
app.run(port=5001)
```

**Emails no se envían:**
- Verifica credenciales en `config_notificaciones.ini`
- Usa contraseña de aplicación (Google)
- Revisa logs: `notificaciones_pos.log`

## 📝 Licencia

MIT

## 👨‍💻 Autor

Rodrigo Solbes
Emannuel Izaguirre
