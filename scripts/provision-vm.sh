#!/bin/bash
# Script de provisionamiento para VM Vagrant
# Instala Docker, Docker Compose y levanta todos los servicios

set -e

echo "=========================================="
echo "Provisionando VM para Telemáticos"
echo "=========================================="

# Actualizar sistema
echo "Actualizando sistema..."
apt-get update
apt-get upgrade -y

# Instalar dependencias
echo "Instalando dependencias..."
apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Instalar Docker
echo "Instalando Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
rm get-docker.sh

# Añadir usuario vagrant al grupo docker
usermod -aG docker vagrant

# Verificar instalación
echo "Verificando instalación..."
docker --version
docker compose version

# Navegar al directorio del proyecto
cd /vagrant

# Construir y levantar servicios
echo "Construyendo imágenes Docker..."
docker compose build

echo "Levantando servicios..."
docker compose up -d

# Esperar a que los servicios estén listos
echo "Esperando a que los servicios estén listos..."
sleep 30

# Verificar estado
echo "Verificando estado de los servicios..."
docker compose ps

echo "=========================================="
echo "Provisionamiento completado!"
echo "=========================================="
echo ""
echo "Acceder a los servicios:"
echo "  WebApp (HTTP):  http://192.168.60.3 o http://localhost:8080"
echo "  WebApp (HTTPS): https://192.168.60.3 o https://localhost:8443"
echo "  Grafana:        http://192.168.60.3:3000 o http://localhost:3000"
echo "  Prometheus:     http://192.168.60.3:9090 o http://localhost:9090"
echo ""
echo "Credenciales Grafana: admin / admin123"
echo ""
