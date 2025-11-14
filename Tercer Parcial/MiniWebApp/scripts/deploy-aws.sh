#!/bin/bash
# Script simplificado de despliegue en AWS EC2
# Uso: ./deploy-aws.sh

set -e

echo "=========================================="
echo "Despliegue en AWS EC2"
echo "=========================================="

# Variables
REPO_URL="https://github.com/FernandoJ07/Telematicos.git"
APP_DIR="/home/ubuntu/webapp"
BRANCH="main"
DOCKER_INSTALLED=false

# 1. Instalar Docker y Docker Compose si no están instalados
if ! command -v docker &> /dev/null; then
    echo "Instalando Docker..."
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc
    
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    # Agregar usuario al grupo docker
    sudo usermod -aG docker $USER
    DOCKER_INSTALLED=true
    echo "Docker instalado exitosamente."
fi

# 2. Clonar o actualizar repositorio
if [ -d "$APP_DIR" ]; then
    echo "Actualizando repositorio..."
    cd $APP_DIR
    git pull origin $BRANCH
else
    echo "Clonando repositorio..."
    git clone -b $BRANCH $REPO_URL $APP_DIR
fi

cd "$APP_DIR/Tercer Parcial/MiniWebApp"

# Definir comando docker (usar sudo si acabamos de instalar Docker)
if [ "$DOCKER_INSTALLED" = true ]; then
    echo "Usando sudo para Docker (recién instalado)..."
    DOCKER_CMD="sudo docker"
    COMPOSE_CMD="sudo docker compose"
else
    DOCKER_CMD="docker"
    COMPOSE_CMD="docker compose"
fi

# Usar docker-compose.prod.yml si existe (imagen pre-built), sino usar docker-compose.yml (build local)
if [ -f "docker-compose.prod.yml" ]; then
    echo "Usando docker-compose.prod.yml (imagen pre-built de Docker Hub - rápido)..."
    COMPOSE_FILE="docker-compose.prod.yml"
else
    echo "Usando docker-compose.yml (build local - puede tardar 10-15 min)..."
    COMPOSE_FILE="docker-compose.yml"
fi

COMPOSE_CMD="$COMPOSE_CMD -f $COMPOSE_FILE"

# 3. Ejecutar init.sql para crear tablas (si es primera vez)
echo "Inicializando base de datos..."
$COMPOSE_CMD up -d db
sleep 10
$COMPOSE_CMD exec -T db mysql -uroot -proot myflaskapp < init.sql 2>/dev/null || echo "Base de datos ya inicializada"

# 4. Levantar todos los servicios
echo "Levantando servicios..."
$COMPOSE_CMD up -d --build

# 5. Verificar estado
echo ""
echo "Esperando a que los servicios estén listos..."
sleep 20

echo ""
echo "Estado de los servicios:"
$COMPOSE_CMD ps

echo ""
echo "=========================================="
echo "Despliegue completado"
echo "=========================================="
echo ""
echo "Acceda a la aplicación en:"
echo "  - WebApp: https://$(curl -s ifconfig.me):443"
echo "  - Prometheus: http://$(curl -s ifconfig.me):9090"
echo "  - Grafana: http://$(curl -s ifconfig.me):3000 (admin/admin123)"
echo ""


# Mostrar logs
echo ""
echo "Últimos logs de los contenedores:"
$COMPOSE_CMD logs --tail=20

# Obtener IP pública
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 || echo "No disponible")

echo ""
echo "=========================================="
echo "Despliegue completado exitosamente"
echo "=========================================="
echo ""
echo "Servicios disponibles:"
echo "  - WebApp (HTTP):  http://$PUBLIC_IP"
echo "  - WebApp (HTTPS): https://$PUBLIC_IP"
echo "  - Grafana:        http://$PUBLIC_IP:3000"
echo "  - Prometheus:     http://$PUBLIC_IP:9090"
echo ""
echo "Credenciales de Grafana:"
echo "  Usuario: admin"
echo "  Contraseña: admin123"
echo ""
echo "Para ver los logs en tiempo real:"
if [ "$DOCKER_INSTALLED" = true ]; then
    echo "  sudo docker compose logs -f"
    echo ""
    echo "NOTA: Docker se instaló en esta sesión."
    echo "      Cierre sesión y vuelva a conectarse para usar docker sin sudo."
else
    echo "  docker compose logs -f"
fi
echo ""
