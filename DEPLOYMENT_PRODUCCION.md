# 🚀 DEPLOYMENT A PRODUCCIÓN

Guía completa para desplegar Sistema POS en servidor de producción.

---

## 📋 REQUISITOS

### Hardware Mínimo
- **CPU:** 2 cores
- **RAM:** 2GB
- **Disco:** 20GB SSD
- **Ancho de banda:** 10 Mbps

### Software Requerido
- Ubuntu 18.04 LTS o superior
- Python 3.8+
- MySQL 5.7+
- Nginx
- SSL/TLS (Let's Encrypt)

---

## 1️⃣ PREPARACIÓN DEL SERVIDOR

### Conectarse al Servidor

```bash
ssh usuario@tu_servidor.com
cd /home/usuario
```

### Actualizar Sistema

```bash
sudo apt update
sudo apt upgrade -y
sudo apt install -y git curl wget vim
```

### Instalar Dependencias

```bash
# Python y pip
sudo apt install -y python3 python3-pip python3-venv python3-dev

# MySQL Client
sudo apt install -y mysql-client libmysqlclient-dev

# Compiladores
sudo apt install -y build-essential

# Nginx
sudo apt install -y nginx

# Supervisor (para gestionar procesos)
sudo apt install -y supervisor

# Certbot (SSL)
sudo apt install -y certbot python3-certbot-nginx
```

---

## 2️⃣ CLONAR PROYECTO

```bash
# Clonar repositorio
cd /home/usuario
git clone https://github.com/tu_usuario/proyecto_pos.git
cd proyecto_pos

# Crear entorno virtual
python3 -m venv venv
source venv/bin/activate

# Instalar dependencias
pip install --upgrade pip
pip install -r requirements.txt
```

---

## 3️⃣ CONFIGURAR BASE DE DATOS

### Conexión Remota a MySQL

```bash
# Si MySQL está en servidor remoto
mysql -h tu_servidor_db.com -u root -p pos_system < 01_schema_pos.sql
mysql -h tu_servidor_db.com -u root -p pos_system < procedures_final.sql
```

### O instalar MySQL localmente

```bash
sudo apt install -y mysql-server

# Crear BD
mysql -u root -p << EOF
CREATE DATABASE IF NOT EXISTS pos_system CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'pos_user'@'localhost' IDENTIFIED BY 'contraseña_segura';
GRANT ALL PRIVILEGES ON pos_system.* TO 'pos_user'@'localhost';
FLUSH PRIVILEGES;
EOF

# Importar schema
mysql -u pos_user -p pos_system < 01_schema_pos.sql
mysql -u pos_user -p pos_system < procedures_final.sql
```

---

## 4️⃣ CONFIGURAR APLICACIÓN

### Actualizar Credenciales

```bash
nano ~/proyecto_pos/conexion_pos.py
```

Cambiar:
```python
self.conexion = mysql.connector.connect(
    host='localhost',
    user='pos_user',
    password='contraseña_segura',
    database='pos_system'
)
```

### Configurar Email

```bash
nano ~/proyecto_pos/config_notificaciones.ini
```

```ini
[base_datos]
host = localhost
user = pos_user
password = contraseña_segura
database = pos_system

[correo]
smtp_server = smtp.gmail.com
smtp_port = 587
remitente = tu_email@gmail.com
contraseña = tu_contraseña_app
destinatarios = administrador@empresa.com

[notificaciones]
intervalo = 300
notificar_bajo_stock = true
notificar_venta = true
```

### Configurar Flask

```bash
nano ~/proyecto_pos/app_flask.py
```

Cambiar al final:
```python
if __name__ == '__main__':
    app.run(debug=False, host='127.0.0.1', port=5000)
```

---

## 5️⃣ CONFIGURAR GUNICORN

### Instalar Gunicorn

```bash
source ~/proyecto_pos/venv/bin/activate
pip install gunicorn
```

### Probar Gunicorn

```bash
cd ~/proyecto_pos
source venv/bin/activate
gunicorn -w 4 -b 127.0.0.1:5000 app_flask:app
```

---

## 6️⃣ CONFIGURAR SUPERVISOR

### Crear archivo de configuración

```bash
sudo nano /etc/supervisor/conf.d/pos_app.conf
```

```ini
[program:pos_app]
directory=/home/usuario/proyecto_pos
command=/home/usuario/proyecto_pos/venv/bin/gunicorn -w 4 -b 127.0.0.1:5000 app_flask:app
user=usuario
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/home/usuario/proyecto_pos/logs/gunicorn.log

[program:pos_notificaciones]
directory=/home/usuario/proyecto_pos
command=/home/usuario/proyecto_pos/venv/bin/python procesador_notificaciones.py
user=usuario
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/home/usuario/proyecto_pos/logs/notificaciones.log
```

### Crear carpeta de logs

```bash
mkdir -p ~/proyecto_pos/logs
sudo chown usuario:usuario ~/proyecto_pos/logs
```

### Actualizar Supervisor

```bash
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start all

# Ver estado
sudo supervisorctl status
```

---

## 7️⃣ CONFIGURAR NGINX

### Crear configuración

```bash
sudo nano /etc/nginx/sites-available/pos
```

```nginx
upstream pos_app {
    server 127.0.0.1:5000;
}

server {
    listen 80;
    server_name tu_dominio.com www.tu_dominio.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name tu_dominio.com www.tu_dominio.com;

    ssl_certificate /etc/letsencrypt/live/tu_dominio.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/tu_dominio.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;

    access_log /home/usuario/proyecto_pos/logs/nginx_access.log;
    error_log /home/usuario/proyecto_pos/logs/nginx_error.log;

    gzip on;
    gzip_types text/plain text/css text/javascript application/json;
    client_max_body_size 50M;

    location / {
        proxy_pass http://pos_app;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /static {
        alias /home/usuario/proyecto_pos/static;
        expires 30d;
    }
}
```

### Habilitar configuración

```bash
sudo ln -s /etc/nginx/sites-available/pos /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

---

## 8️⃣ CONFIGURAR SSL/TLS

### Generar certificado

```bash
sudo certbot certonly --nginx -d tu_dominio.com -d www.tu_dominio.com
```

### Renovación automática

```bash
sudo systemctl enable certbot.timer
sudo systemctl start certbot.timer
```

---

## 9️⃣ BACKUPS AUTOMÁTICOS

### Script de backup

```bash
sudo nano /usr/local/bin/backup_pos.sh
```

```bash
#!/bin/bash

BACKUP_DIR="/backups/pos_system"
DATE=$(date +%Y%m%d_%H%M%S)
DB_NAME="pos_system"
DB_USER="pos_user"

mkdir -p $BACKUP_DIR

mysqldump -u $DB_USER -p$DB_PASSWORD $DB_NAME | gzip > $BACKUP_DIR/db_$DATE.sql.gz
tar -czf $BACKUP_DIR/files_$DATE.tar.gz /home/usuario/proyecto_pos/
find $BACKUP_DIR -name "*.gz" -mtime +30 -delete

echo "Backup: $DATE" >> /var/log/pos_backup.log
```

### Hacer ejecutable y programar

```bash
sudo chmod +x /usr/local/bin/backup_pos.sh
sudo crontab -e
```

Agregar:
```cron
0 2 * * * /usr/local/bin/backup_pos.sh
```

---

## 🔟 FIREWALL

```bash
sudo ufw enable
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw status
```

---

## ✅ CHECKLIST

- [ ] Servidor actualizado
- [ ] Python 3.8+ instalado
- [ ] MySQL configurado
- [ ] Proyecto clonado
- [ ] Dependencias instaladas
- [ ] BD importada
- [ ] Credenciales actualizadas
- [ ] Email configurado
- [ ] Gunicorn probado
- [ ] Supervisor configurado
- [ ] Nginx configurado
- [ ] SSL certificado
- [ ] Firewall habilitado
- [ ] Backups configurados

---

## 🆘 TROUBLESHOOTING

### Aplicación no inicia

```bash
sudo supervisorctl tail pos_app
tail -f ~/proyecto_pos/logs/gunicorn.log
```

### BD no conecta

```bash
mysql -u pos_user -p -h localhost pos_system -e "SELECT 1;"
```

### Emails no se envían

```bash
tail -f ~/proyecto_pos/logs/notificaciones.log
```