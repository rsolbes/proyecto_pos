# GUÍA DE DEPLOYMENT - SISTEMA POS

## 🚀 Deployment en Producción

Esta guía cubre cómo deployar el sistema POS en diferentes entornos.

---

## 📋 Pre-requisitos

- Servidor con Linux (Ubuntu 18.04+)
- Acceso SSH
- Dominio configurado (opcional)
- SSL Certificate (recomendado)

---

## 1️⃣ SETUP EN SERVIDOR LINUX

### Paso 1: Actualizar el Sistema

```bash
sudo apt update
sudo apt upgrade -y
```

### Paso 2: Instalar Dependencias Básicas

```bash
# MySQL
sudo apt install -y mysql-server

# Python y pip
sudo apt install -y python3 python3-pip python3-venv

# Herramientas útiles
sudo apt install -y git curl wget
```

### Paso 3: Configurar MySQL

```bash
# Asegurar MySQL
sudo mysql_secure_installation

# Conectar a MySQL
sudo mysql -u root -p

# Crear base de datos
CREATE DATABASE pos_system;

# Crear usuario
CREATE USER 'pos_user'@'localhost' IDENTIFIED BY 'contraseña_segura';
GRANT ALL PRIVILEGES ON pos_system.* TO 'pos_user'@'localhost';
FLUSH PRIVILEGES;

# Importar schema
exit
mysql -u pos_user -p pos_system < 01_schema_pos.sql
```

### Paso 4: Crear Carpeta del Proyecto

```bash
# Crear carpeta
sudo mkdir -p /var/www/pos
cd /var/www/pos

# Descargar/copiar archivos
# (Copiar todos los archivos del proyecto aquí)

# Cambiar permisos
sudo chown -R $USER:$USER /var/www/pos
chmod -R 755 /var/www/pos
```

---

## 2️⃣ SETUP DE PYTHON Y DEPENDENCIAS

### Paso 1: Crear Entorno Virtual

```bash
cd /var/www/pos
python3 -m venv venv
source venv/bin/activate
```

### Paso 2: Instalar Dependencias

```bash
pip install --upgrade pip
pip install -r requirements.txt

# Instalar gunicorn para producción
pip install gunicorn
```

### Paso 3: Configurar Variables de Entorno

```bash
# Copiar archivo de ejemplo
cp .env.example .env

# Editar archivo
nano .env
```

Actualizar los valores:
```env
DB_HOST=localhost
DB_USER=pos_user
DB_PASSWORD=contraseña_segura
DB_NAME=pos_system
SECRET_KEY=generar_valor_aleatorio_seguro
FLASK_ENV=production
FLASK_DEBUG=False
```

---

## 3️⃣ CONFIGURAR GUNICORN

### Paso 1: Crear Archivo de Configuración

```bash
nano gunicorn_config.py
```

```python
import multiprocessing

# Configuración de Gunicorn
bind = "127.0.0.1:8000"
workers = multiprocessing.cpu_count() * 2 + 1
worker_class = "sync"
worker_connections = 1000
timeout = 60
keepalive = 2

# Logging
accesslog = "/var/www/pos/logs/access.log"
errorlog = "/var/www/pos/logs/error.log"
loglevel = "info"

# Procesos
daemon = False
pidfile = "/var/www/pos/gunicorn.pid"
```

### Paso 2: Crear Carpeta de Logs

```bash
mkdir -p /var/www/pos/logs
```

---

## 4️⃣ CONFIGURAR NGINX

### Paso 1: Instalar Nginx

```bash
sudo apt install -y nginx
```

### Paso 2: Crear Configuración de Sitio

```bash
sudo nano /etc/nginx/sites-available/pos
```

```nginx
upstream pos_app {
    server 127.0.0.1:8000;
}

server {
    listen 80;
    server_name tu_dominio.com www.tu_dominio.com;

    # Redirigir HTTP a HTTPS (descomentar después de SSL)
    # return 301 https://$server_name$request_uri;

    location / {
        proxy_pass http://pos_app;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Archivos estáticos
    location /static/ {
        alias /var/www/pos/static/;
        expires 30d;
    }

    # Archivos media
    location /media/ {
        alias /var/www/pos/media/;
        expires 30d;
    }
}
```

### Paso 3: Habilitar Sitio

```bash
sudo ln -s /etc/nginx/sites-available/pos /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

---

## 5️⃣ CONFIGURAR SSL CON CERTBOT

### Paso 1: Instalar Certbot

```bash
sudo apt install -y certbot python3-certbot-nginx
```

### Paso 2: Obtener Certificado

```bash
sudo certbot --nginx -d tu_dominio.com -d www.tu_dominio.com
```

### Paso 3: Configurar Renovación Automática

```bash
sudo systemctl enable certbot.timer
sudo systemctl start certbot.timer
```

---

## 6️⃣ CONFIGURAR SYSTEMD SERVICE

### Paso 1: Crear Servicio para Aplicación

```bash
sudo nano /etc/systemd/system/pos-app.service
```

```ini
[Unit]
Description=POS Application
After=network.target

[Service]
Type=notify
User=usuario
WorkingDirectory=/var/www/pos
Environment="PATH=/var/www/pos/venv/bin"
ExecStart=/var/www/pos/venv/bin/gunicorn \
    --config gunicorn_config.py \
    --bind 127.0.0.1:8000 \
    app_flask:app

Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

### Paso 2: Crear Servicio para Notificaciones

```bash
sudo nano /etc/systemd/system/pos-notificaciones.service
```

```ini
[Unit]
Description=POS Notifications Service
After=network.target

[Service]
Type=simple
User=usuario
WorkingDirectory=/var/www/pos
Environment="PATH=/var/www/pos/venv/bin"
ExecStart=/var/www/pos/venv/bin/python procesador_notificaciones.py

Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

### Paso 3: Iniciar Servicios

```bash
sudo systemctl daemon-reload
sudo systemctl enable pos-app.service
sudo systemctl start pos-app.service

sudo systemctl enable pos-notificaciones.service
sudo systemctl start pos-notificaciones.service

# Verificar estado
sudo systemctl status pos-app.service
sudo systemctl status pos-notificaciones.service
```

---

## 7️⃣ CONFIGURAR RESPALDOS AUTOMÁTICOS

### Paso 1: Crear Script de Respaldo

```bash
nano /var/www/pos/backup.sh
```

```bash
#!/bin/bash

BACKUP_DIR="/var/www/pos/backups"
DATE=$(date +"%Y%m%d_%H%M%S")
DB_USER="pos_user"
DB_PASSWORD="contraseña_segura"
DB_NAME="pos_system"

# Crear directorio si no existe
mkdir -p $BACKUP_DIR

# Realizar backup
mysqldump -u $DB_USER -p$DB_PASSWORD $DB_NAME > \
    $BACKUP_DIR/pos_backup_$DATE.sql

# Comprimir
gzip $BACKUP_DIR/pos_backup_$DATE.sql

# Eliminar backups antiguos (más de 30 días)
find $BACKUP_DIR -name "*.sql.gz" -mtime +30 -delete

echo "Backup completado: pos_backup_$DATE.sql.gz"
```

### Paso 2: Hacer Ejecutable

```bash
chmod +x /var/www/pos/backup.sh
```

### Paso 3: Agregar a Crontab

```bash
# Editar crontab
crontab -e

# Agregar línea para backup diario a las 2:00 AM
0 2 * * * /var/www/pos/backup.sh >> /var/www/pos/logs/backup.log 2>&1
```

---

## 8️⃣ MONITOREO Y LOGS

### Ver Logs de Aplicación

```bash
# Logs de acceso
tail -f /var/www/pos/logs/access.log

# Logs de error
tail -f /var/www/pos/logs/error.log

# Estado del servicio
sudo journalctl -u pos-app.service -f
sudo journalctl -u pos-notificaciones.service -f
```

### Configurar Rotación de Logs

```bash
sudo nano /etc/logrotate.d/pos
```

```
/var/www/pos/logs/*.log {
    daily
    rotate 14
    compress
    delaycompress
    notifempty
    create 0640 usuario usuario
    sharedscripts
    postrotate
        systemctl reload nginx > /dev/null 2>&1 || true
    endscript
}
```

---

## 9️⃣ MONITOREO CON PM2 (Alternativa)

### Instalación

```bash
# Instalar PM2 globalmente
sudo npm install -g pm2

# Crear archivo ecosystem.config.js
cat > /var/www/pos/ecosystem.config.js << EOF
module.exports = {
  apps: [
    {
      name: 'pos-app',
      script: './venv/bin/gunicorn',
      args: '--config gunicorn_config.py app_flask:app',
      cwd: '/var/www/pos',
      instances: 'max',
      exec_mode: 'cluster',
      env: {
        NODE_ENV: 'production'
      },
      watch: false,
      ignore_watch: ['node_modules', 'logs', '__pycache__'],
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      error_file: '/var/www/pos/logs/error.log',
      out_file: '/var/www/pos/logs/access.log'
    },
    {
      name: 'pos-notifications',
      script: './venv/bin/python',
      args: 'procesador_notificaciones.py',
      cwd: '/var/www/pos',
      env: {
        NODE_ENV: 'production'
      },
      restart_delay: 5000,
      error_file: '/var/www/pos/logs/notif_error.log',
      out_file: '/var/www/pos/logs/notif_access.log'
    }
  ]
};
EOF

# Iniciar con PM2
pm2 start ecosystem.config.js

# Guardar configuración
pm2 save
pm2 startup
```

---

## 🔟 VERIFICACIÓN FINAL

### Checklist de Deployment

- [ ] Base de datos importada correctamente
- [ ] Archivo .env configurado con valores de producción
- [ ] SSL/HTTPS habilitado
- [ ] Servicios iniciados y activos
- [ ] Logs monitoreados
- [ ] Respaldos configurados
- [ ] Firewall configurado
- [ ] Backups probados y funcionando
- [ ] URL accesible desde navegador
- [ ] Login funciona correctamente

### Pruebas de Conectividad

```bash
# Verificar que la aplicación responde
curl http://localhost:8000

# Verificar que nginx redirecciona correctamente
curl -I http://tu_dominio.com

# Verificar conexión a base de datos
mysql -u pos_user -p -h localhost pos_system -e "SELECT COUNT(*) FROM usuarios;"
```

---

## ⚙️ OPTIMIZACIONES DE PRODUCCIÓN

### 1. Aumentar Límites de Conexión MySQL

```sql
SET GLOBAL max_connections = 1000;
SET GLOBAL wait_timeout = 28800;
```

### 2. Configurar Caché

```nginx
# Agregar a nginx.conf
proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=pos_cache:10m;

location / {
    proxy_cache pos_cache;
    proxy_cache_valid 200 10m;
}
```

### 3. Habilitar Gzip

```nginx
gzip on;
gzip_types text/plain text/css text/javascript application/json;
gzip_min_length 1000;
```

---

## 🆘 TROUBLESHOOTING

### Error: "Connection refused"

```bash
# Verificar que servicios estén activos
sudo systemctl status pos-app.service
sudo systemctl status pos-notificaciones.service

# Reiniciar servicios
sudo systemctl restart pos-app.service
```

### Error: "Database connection error"

```bash
# Verificar MySQL
sudo systemctl status mysql

# Comprobar credenciales
mysql -u pos_user -p -h localhost pos_system -e "SELECT 1;"
```

### Logs Llenos

```bash
# Limpiar logs
sudo truncate -s 0 /var/www/pos/logs/*.log

# O usar logrotate manualmente
sudo logrotate -f /etc/logrotate.d/pos
```

---

## 📞 CONTACTO Y SOPORTE

Para soporte contactar al equipo de desarrollo o consultar la documentación de cada tecnología.

**URLs Útiles:**
- [Flask Documentation](https://flask.palletsprojects.com/)
- [Gunicorn Documentation](https://gunicorn.org/)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [MySQL Documentation](https://dev.mysql.com/doc/)
