#!/usr/bin/env python3
"""
Sistema de notificaciones por correo para POS
Procesa las notificaciones almacenadas en la base de datos y las envía
"""

import smtplib
import mysql.connector
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from datetime import datetime
import logging
import time
from configparser import ConfigParser

# Configuración de logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('notificaciones_pos.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

class ConfiguradorNotificaciones:
    """Carga y gestiona la configuración del sistema"""
    
    def __init__(self, archivo_config='config_notificaciones.ini'):
        self.config = ConfigParser()
        self.config.read(archivo_config)
    
    def obtener_configuracion_bd(self):
        """Obtiene configuración de base de datos"""
        return {
            'host': self.config.get('base_datos', 'host', fallback='localhost'),
            'user': self.config.get('base_datos', 'user', fallback='root'),
            'password': self.config.get('base_datos', 'password', fallback=''),
            'database': self.config.get('base_datos', 'database', fallback='pos_system')
        }
    
    def obtener_configuracion_correo(self):
        """Obtiene configuración de correo"""
        return {
            'smtp_server': self.config.get('correo', 'smtp_server', fallback='smtp.gmail.com'),
            'smtp_port': self.config.getint('correo', 'smtp_port', fallback=587),
            'remitente': self.config.get('correo', 'remitente'),
            'contraseña': self.config.get('correo', 'contraseña')
        }

class GestorBaseDatos:
    """Gestiona la conexión y operaciones con la base de datos"""
    
    def __init__(self, config_bd):
        self.config_bd = config_bd
        self.conexion = None
    
    def conectar(self):
        """Establece conexión con la base de datos"""
        try:
            self.conexion = mysql.connector.connect(**self.config_bd)
            logger.info("Conexión a base de datos establecida")
            return True
        except mysql.connector.Error as error:
            logger.error(f"Error al conectar a la base de datos: {error}")
            return False
    
    def desconectar(self):
        """Cierra la conexión"""
        if self.conexion and self.conexion.is_connected():
            self.conexion.close()
            logger.info("Conexión cerrada")
    
    def obtener_notificaciones_pendientes(self):
        """Obtiene notificaciones no enviadas"""
        try:
            cursor = self.conexion.cursor(dictionary=True)
            query = """
                SELECT id_notificacion, destinatario, asunto, cuerpo, 
                       tipo_notificacion, fecha_creacion
                FROM notificaciones_correo
                WHERE enviada = FALSE
                ORDER BY fecha_creacion ASC
                LIMIT 50
            """
            cursor.execute(query)
            notificaciones = cursor.fetchall()
            cursor.close()
            return notificaciones
        except mysql.connector.Error as error:
            logger.error(f"Error al obtener notificaciones: {error}")
            return []
    
    def marcar_notificacion_enviada(self, id_notificacion):
        """Marca una notificación como enviada"""
        try:
            cursor = self.conexion.cursor()
            query = """
                UPDATE notificaciones_correo
                SET enviada = TRUE, fecha_envio = NOW()
                WHERE id_notificacion = %s
            """
            cursor.execute(query, (id_notificacion,))
            self.conexion.commit()
            cursor.close()
            return True
        except mysql.connector.Error as error:
            logger.error(f"Error al marcar notificación: {error}")
            return False
    
    def registrar_error_envio(self, id_notificacion, error):
        """Registra un error al enviar notificación"""
        try:
            cursor = self.conexion.cursor()
            query = """
                UPDATE notificaciones_correo
                SET cuerpo = CONCAT(cuerpo, '\n\n[ERROR: ', %s, ']')
                WHERE id_notificacion = %s
            """
            cursor.execute(query, (str(error), id_notificacion))
            self.conexion.commit()
            cursor.close()
        except mysql.connector.Error as error:
            logger.error(f"Error al registrar error: {error}")

class GestorCorreo:
    """Gestiona el envío de correos electrónicos"""
    
    def __init__(self, config_correo):
        self.config_correo = config_correo
    
    def enviar_correo(self, destinatario, asunto, cuerpo):
        """Envía un correo electrónico"""
        try:
            # Crear mensaje
            mensaje = MIMEMultipart('alternative')
            mensaje['Subject'] = asunto
            mensaje['From'] = self.config_correo['remitente']
            mensaje['To'] = destinatario
            
            # Convertir texto a HTML
            html = self._convertir_a_html(cuerpo)
            
            # Añadir partes al mensaje
            parte_texto = MIMEText(cuerpo, 'plain')
            parte_html = MIMEText(html, 'html')
            
            mensaje.attach(parte_texto)
            mensaje.attach(parte_html)
            
            # Enviar correo
            servidor_smtp = smtplib.SMTP(
                self.config_correo['smtp_server'],
                self.config_correo['smtp_port']
            )
            servidor_smtp.starttls()
            servidor_smtp.login(
                self.config_correo['remitente'],
                self.config_correo['contraseña']
            )
            servidor_smtp.send_message(mensaje)
            servidor_smtp.quit()
            
            logger.info(f"Correo enviado exitosamente a {destinatario}")
            return True
            
        except smtplib.SMTPException as error:
            logger.error(f"Error SMTP al enviar correo: {error}")
            return False
        except Exception as error:
            logger.error(f"Error inesperado al enviar correo: {error}")
            return False
    
    @staticmethod
    def _convertir_a_html(texto):
        """Convierte texto plano a HTML formateado"""
        html = f"""
        <html>
            <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
                <div style="background-color: #f5f5f5; padding: 20px; border-radius: 5px;">
                    <h2 style="color: #2c3e50; border-bottom: 2px solid #3498db; padding-bottom: 10px;">
                        Notificación del Sistema POS
                    </h2>
                    <p style="white-space: pre-wrap; background-color: white; padding: 15px; border-left: 4px solid #3498db;">
                        {texto}
                    </p>
                    <hr style="border: none; border-top: 1px solid #ddd; margin: 20px 0;">
                    <p style="font-size: 12px; color: #666;">
                        Este es un correo automático del Sistema de Punto de Venta.
                        Por favor, no responda a este mensaje.
                    </p>
                </div>
            </body>
        </html>
        """
        return html

class ProcesadorNotificaciones:
    """Procesa y envía notificaciones"""
    
    def __init__(self, config_bd, config_correo):
        self.gestor_bd = GestorBaseDatos(config_bd)
        self.gestor_correo = GestorCorreo(config_correo)
    
    def procesar_notificaciones(self):
        """Procesa todas las notificaciones pendientes"""
        # Conectar a base de datos
        if not self.gestor_bd.conectar():
            logger.error("No se pudo conectar a la base de datos")
            return False
        
        try:
            # Obtener notificaciones pendientes
            notificaciones = self.gestor_bd.obtener_notificaciones_pendientes()
            
            if not notificaciones:
                logger.info("No hay notificaciones pendientes")
                return True
            
            logger.info(f"Procesando {len(notificaciones)} notificaciones")
            
            # Procesar cada notificación
            for notif in notificaciones:
                try:
                    logger.info(f"Enviando notificación {notif['id_notificacion']} a {notif['destinatario']}")
                    
                    # Enviar correo
                    if self.gestor_correo.enviar_correo(
                        notif['destinatario'],
                        notif['asunto'],
                        notif['cuerpo']
                    ):
                        # Marcar como enviada
                        self.gestor_bd.marcar_notificacion_enviada(notif['id_notificacion'])
                        logger.info(f"Notificación {notif['id_notificacion']} marcada como enviada")
                    else:
                        logger.error(f"Fallo al enviar notificación {notif['id_notificacion']}")
                        self.gestor_bd.registrar_error_envio(
                            notif['id_notificacion'],
                            "Fallo al conectar con servidor SMTP"
                        )
                    
                    # Pequeña pausa entre correos
                    time.sleep(1)
                    
                except Exception as error:
                    logger.error(f"Error procesando notificación {notif['id_notificacion']}: {error}")
                    self.gestor_bd.registrar_error_envio(notif['id_notificacion'], str(error))
            
            return True
            
        finally:
            self.gestor_bd.desconectar()
    
    def ejecutar_continuamente(self, intervalo_segundos=300):
        """Ejecuta el procesador continuamente"""
        logger.info(f"Iniciando procesador de notificaciones (intervalo: {intervalo_segundos}s)")
        
        try:
            while True:
                logger.info("Verificando notificaciones pendientes...")
                self.procesar_notificaciones()
                
                logger.info(f"Próxima revisión en {intervalo_segundos} segundos")
                time.sleep(intervalo_segundos)
                
        except KeyboardInterrupt:
            logger.info("Procesador detenido por el usuario")
        except Exception as error:
            logger.error(f"Error fatal: {error}")

def main():
    """Función principal"""
    try:
        # Cargar configuración
        configurador = ConfiguradorNotificaciones()
        config_bd = configurador.obtener_configuracion_bd()
        config_correo = configurador.obtener_configuracion_correo()
        
        # Crear procesador
        procesador = ProcesadorNotificaciones(config_bd, config_correo)
        
        # Ejecutar continuamente
        procesador.ejecutar_continuamente(intervalo_segundos=300)
        
    except Exception as error:
        logger.error(f"Error en función principal: {error}")

if __name__ == '__main__':
    main()
