#!/bin/bash
set -e

# Generar certificado SSL autofirmado si no existe
if [ ! -f /etc/apache2/ssl/server.crt ]; then
    echo "Generando certificado SSL autofirmado..."
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/apache2/ssl/server.key \
        -out /etc/apache2/ssl/server.crt \
        -subj "/C=CO/ST=State/L=City/O=Organization/OU=IT/CN=localhost"
    chmod 600 /etc/apache2/ssl/server.key
    chmod 644 /etc/apache2/ssl/server.crt
    echo "Certificado SSL generado exitosamente"
fi

# Esperar a que MySQL esté disponible
echo "Esperando a que MySQL esté disponible..."
until mysql -h"${MYSQL_HOST:-db}" -u"${MYSQL_USER:-root}" -p"${MYSQL_PASSWORD:-root}" --skip-ssl -e "SELECT 1" >/dev/null 2>&1; do
    echo "MySQL no está listo - esperando..."
    sleep 2
done
echo "MySQL está disponible!"

# Ejecutar el comando proporcionado
exec "$@"
