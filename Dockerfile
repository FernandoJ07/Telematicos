# Dockerfile para MiniWebApp con Apache y SSL
FROM python:3.9-slim

# Instalar dependencias del sistema
RUN apt-get update && apt-get install -y \
    apache2 \
    apache2-dev \
    default-libmysqlclient-dev \
    default-mysql-client \
    build-essential \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Establecer directorio de trabajo
WORKDIR /var/www/webapp

# Copiar archivos de la aplicación
COPY webapp/ /var/www/webapp/

# Instalar dependencias de Python
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt mod_wsgi

# Copiar configuración de Apache
COPY apache-config/webapp.conf /etc/apache2/sites-available/webapp.conf
COPY apache-config/webapp-ssl.conf /etc/apache2/sites-available/webapp-ssl.conf
COPY apache-config/webapp.wsgi /var/www/webapp/webapp.wsgi

# Crear directorio para certificados SSL
RUN mkdir -p /etc/apache2/ssl

# Configurar mod_wsgi compilado
RUN mod_wsgi-express install-module > /etc/apache2/mods-available/wsgi_express.load \
    && echo "WSGIPythonHome /usr/local" >> /etc/apache2/mods-available/wsgi_express.load \
    && a2enmod wsgi_express

# Habilitar módulos de Apache necesarios
RUN a2enmod ssl \
    && a2enmod rewrite \
    && a2enmod headers \
    && a2enmod status

# Deshabilitar sitio por defecto y habilitar nuestra aplicación
RUN a2dissite 000-default.conf \
    && a2ensite webapp.conf \
    && a2ensite webapp-ssl.conf

# Crear script de inicio
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Exponer puertos
EXPOSE 80 443

# Comando de inicio
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2ctl", "-D", "FOREGROUND"]
