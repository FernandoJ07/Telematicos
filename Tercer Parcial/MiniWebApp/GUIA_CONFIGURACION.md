# Guía de Configuración del Proyecto

## Paso 1: Empaquetado y Despliegue Local con Docker (1.5 puntos)

### 1.1 Configuración del Servidor Web Apache con HTTPS

**Objetivo**: Configurar Apache para servir la aplicación mediante HTTPS con certificado SSL autofirmado y redirección automática HTTP → HTTPS.

#### Archivos de Configuración Apache

**`apache-config/webapp.conf`** (VirtualHost HTTP - Puerto 80):
```apache
<VirtualHost *:80>
    ServerName localhost
    ServerAdmin webmaster@localhost
    
    # Endpoint de métricas para Apache Exporter (sin redirect HTTPS)
    <Location /server-status>
        SetHandler server-status
        Require local
        Require ip 172.16.0.0/12
    </Location>
    
    # Redirección automática HTTP → HTTPS (excepto /server-status)
    RewriteEngine On
    RewriteCond %{REQUEST_URI} !^/server-status
    RewriteCond %{HTTPS} off
    RewriteRule ^ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]
    
    ErrorLog ${APACHE_LOG_DIR}/webapp_error.log
    CustomLog ${APACHE_LOG_DIR}/webapp_access.log combined
</VirtualHost>
```

**`apache-config/webapp-ssl.conf`** (VirtualHost HTTPS - Puerto 443):
```apache
<VirtualHost *:443>
    ServerName localhost
    ServerAdmin webmaster@localhost
    
    # Configuración SSL
    SSLEngine on
    SSLCertificateFile /etc/apache2/ssl/server.crt
    SSLCertificateKeyFile /etc/apache2/ssl/server.key
    
    # Headers de Seguridad
    Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"
    Header always set X-Frame-Options "SAMEORIGIN"
    Header always set X-Content-Type-Options "nosniff"
    Header always set X-XSS-Protection "1; mode=block"
    
    # Configuración WSGI para Flask
    WSGIDaemonProcess webapp user=www-data group=www-data threads=5 python-home=/usr/local python-path=/var/www/webapp
    WSGIScriptAlias / /var/www/webapp/webapp.wsgi
    
    <Directory /var/www/webapp>
        WSGIProcessGroup webapp
        WSGIApplicationGroup %{GLOBAL}
        Require all granted
    </Directory>
    
    # Archivos estáticos
    Alias /static /var/www/webapp/web/static
    <Directory /var/www/webapp/web/static>
        Require all granted
    </Directory>
    
    # Server Status para métricas
    <Location /server-status>
        SetHandler server-status
        Require local
        Require ip 172.16.0.0/12
        Require ip 172.20.0.0/16
    </Location>
    
    ErrorLog ${APACHE_LOG_DIR}/webapp_ssl_error.log
    CustomLog ${APACHE_LOG_DIR}/webapp_ssl_access.log combined
    
    # Protocolos y Cifrados SSL
    SSLProtocol all -SSLv3 -TLSv1 -TLSv1.1
    SSLCipherSuite HIGH:!aNULL:!MD5
    SSLHonorCipherOrder on
</VirtualHost>
```

#### Dockerfile

**Función**: Construir la imagen de la aplicación con Apache, SSL y mod_wsgi.

```dockerfile
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

WORKDIR /var/www/webapp

# Copiar aplicación
COPY webapp/ /var/www/webapp/

# Instalar dependencias Python + mod_wsgi (compilado para Python 3.9)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt mod_wsgi

# Copiar configuraciones Apache
COPY apache-config/webapp.conf /etc/apache2/sites-available/webapp.conf
COPY apache-config/webapp-ssl.conf /etc/apache2/sites-available/webapp-ssl.conf
COPY apache-config/webapp.wsgi /var/www/webapp/webapp.wsgi

# Crear directorio para certificados SSL
RUN mkdir -p /etc/apache2/ssl

# Configurar mod_wsgi compilado
RUN mod_wsgi-express install-module > /etc/apache2/mods-available/wsgi_express.load \
    && echo "WSGIPythonHome /usr/local" >> /etc/apache2/mods-available/wsgi_express.load \
    && a2enmod wsgi_express

# Habilitar módulos Apache
RUN a2enmod ssl \
    && a2enmod rewrite \
    && a2enmod headers \
    && a2enmod status

# Deshabilitar sitio por defecto y habilitar aplicación
RUN a2dissite 000-default.conf \
    && a2ensite webapp.conf \
    && a2ensite webapp-ssl.conf

# Script de inicio
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 80 443

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2ctl", "-D", "FOREGROUND"]
```

**Puntos Clave**:
- `mod_wsgi` compilado via pip (evita segmentation fault con Python 3.9)
- Módulos habilitados: ssl, rewrite, headers, status
- Certificados SSL se generan automáticamente en el entrypoint

#### docker-entrypoint.sh

**Función**: Script que ejecuta antes de iniciar Apache para:
1. Esperar a que MySQL esté listo
2. Generar certificados SSL si no existen
3. Inicializar base de datos

```bash
#!/bin/bash
set -e

# Esperar a que MySQL esté listo
echo "Esperando a MySQL..."
until mysql -h"${MYSQL_HOST:-db}" -u"${MYSQL_USER:-root}" -p"${MYSQL_PASSWORD:-root}" --skip-ssl -e "SELECT 1" &>/dev/null; do
    echo "MySQL no está listo, esperando..."
    sleep 2
done
echo "MySQL está listo!"

# Generar certificados SSL si no existen
if [ ! -f /etc/apache2/ssl/server.crt ]; then
    echo "Generando certificados SSL..."
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/apache2/ssl/server.key \
        -out /etc/apache2/ssl/server.crt \
        -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"
    echo "Certificados SSL generados!"
fi

# Ejecutar comando principal (Apache)
exec "$@"
```

**Nota Importante**: Se usa `--skip-ssl` en MySQL para evitar errores de verificación de certificados.

#### docker-compose.yml

**Función**: Orquestar todos los servicios del proyecto.

```yaml
services:
  # Base de datos MySQL
  db:
    image: mysql:8.0
    container_name: mysql_db
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: root
      MYSQL_DATABASE: myflaskapp
      MYSQL_USER: appuser
      MYSQL_PASSWORD: apppass
    volumes:
      - mysql_data:/var/lib/mysql
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql
    ports:
      - "3306:3306"
    networks:
      - app_network
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-u", "root", "-proot"]
      interval: 10s
      timeout: 5s
      retries: 5

  # Aplicación Web con Apache y SSL
  webapp:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: webapp
    restart: always
    environment:
      MYSQL_HOST: db
      MYSQL_USER: root
      MYSQL_PASSWORD: root
      MYSQL_DB: myflaskapp
      FLASK_ENV: production
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./webapp:/var/www/webapp
      - ./ssl:/etc/apache2/ssl
    depends_on:
      db:
        condition: service_healthy
    networks:
      - app_network
    healthcheck:
      test: ["CMD", "curl", "-f", "-k", "https://localhost"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  # Prometheus para monitoreo
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    restart: always
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--storage.tsdb.retention.time=15d'
      - '--web.enable-lifecycle'
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
      - ./prometheus/alerts.yml:/etc/prometheus/alerts.yml
      - prometheus_data:/prometheus
    ports:
      - "9090:9090"
    networks:
      - app_network
    depends_on:
      - node-exporter

  # Node Exporter para métricas del sistema
  node-exporter:
    image: prom/node-exporter:latest
    container_name: node_exporter
    restart: always
    command:
      - '--path.procfs=/host/proc'
      - '--path.rootfs=/rootfs'
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    ports:
      - "9100:9100"
    networks:
      - app_network

  # Apache Exporter para métricas HTTP
  apache-exporter:
    image: lusotycoon/apache-exporter:latest
    container_name: apache_exporter
    restart: always
    command:
      - '--scrape_uri=https://webapp:443/server-status?auto'
      - '--insecure'
    ports:
      - "9117:9117"
    networks:
      - app_network
    depends_on:
      - webapp

  # Grafana para visualización
  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    restart: always
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=admin123
      - GF_USERS_ALLOW_SIGN_UP=false
      - GF_SERVER_ROOT_URL=http://localhost:3000
      - GF_INSTALL_PLUGINS=grafana-clock-panel,grafana-simple-json-datasource
    volumes:
      - grafana_data:/var/lib/grafana
      - ./grafana/provisioning:/etc/grafana/provisioning
      - ./grafana/dashboards:/var/lib/grafana/dashboards
    ports:
      - "3000:3000"
    networks:
      - app_network
    depends_on:
      - prometheus

networks:
  app_network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16

volumes:
  mysql_data:
    driver: local
  prometheus_data:
    driver: local
  grafana_data:
    driver: local
```

**Puntos Clave**:
- **6 servicios**: MySQL, WebApp, Prometheus, Node Exporter, Apache Exporter, Grafana
- **Healthchecks**: Aseguran que los servicios estén listos antes de iniciar dependencias
- **Red personalizada**: Subnet 172.20.0.0/16 para comunicación interna
- **Volúmenes persistentes**: Datos de MySQL, Prometheus y Grafana persisten entre reinicios

### 1.2 Verificación Local

```bash
# Levantar servicios
vagrant up

# Acceder a la aplicación
https://localhost:8443

# Verificar redirect HTTP → HTTPS
curl -I http://localhost:8080
# Debe retornar: 301 Moved Permanently
```

---

## Paso 2: Despliegue en AWS EC2 (1.0 punto)

### Script de Despliegue Automatizado

**`scripts/deploy-aws.sh`**: Script que instala Docker, clona el repo e inicia los servicios.

```bash
#!/bin/bash

# Actualizar sistema
sudo apt-get update -y
sudo apt-get upgrade -y

# Instalar Docker
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Agregar usuario actual a grupo docker
sudo usermod -aG docker $USER

# Habilitar Docker al inicio
sudo systemctl enable docker
sudo systemctl start docker

# Clonar repositorio
cd /home/ubuntu
git clone https://github.com/TU_USUARIO/TU_REPO.git
cd TU_REPO

# Inicializar base de datos
docker compose up -d db
sleep 30
docker exec mysql_db mysql -uroot -proot myflaskapp < init.sql

# Levantar todos los servicios
docker compose up -d

echo "Despliegue completado!"
echo "Accede a la aplicación en: https://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
```

### Configuración de Security Groups AWS

**Puertos a abrir en el Security Group**:
- **22** (SSH): Para administración remota
- **80** (HTTP): Tráfico web (redirige a HTTPS)
- **443** (HTTPS): Tráfico web seguro
- **3000** (Grafana): Dashboard de monitoreo
- **9090** (Prometheus): Interfaz de métricas

### Pasos de Despliegue

1. **Crear instancia EC2**:
   - AMI: Ubuntu 22.04 LTS
   - Tipo: t2.medium (2 vCPUs, 4GB RAM)
   - Storage: 20GB

2. **Configurar Security Group** (ver tabla arriba)

3. **Conectar por SSH**:
   ```bash
   ssh -i tu-key.pem ubuntu@IP_PUBLICA
   ```

4. **Ejecutar script de despliegue**:
   ```bash
   chmod +x deploy-aws.sh
   ./deploy-aws.sh
   ```

5. **Verificar servicios**:
   ```bash
   docker ps
   # Deben estar corriendo 6 contenedores
   ```

---

## Paso 3: Monitoreo con Prometheus y Node Exporter (1.5 puntos)

### 3.1 Configuración de Prometheus

**`prometheus/prometheus.yml`**: Define qué métricas recolectar y de dónde.

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

alerting:
  alertmanagers:
    - static_configs:
        - targets: []

rule_files:
  - "alerts.yml"

scrape_configs:
  # Prometheus se monitorea a sí mismo
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  # Node Exporter (métricas del sistema)
  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']

  # Apache Exporter (métricas HTTP)
  - job_name: 'apache'
    static_configs:
      - targets: ['apache-exporter:9117']
```

**Explicación**:
- `scrape_interval: 15s`: Prometheus recolecta métricas cada 15 segundos
- `scrape_configs`: Lista de "jobs" (fuentes de métricas)
- `targets`: Direcciones de los exporters (usa nombres DNS de Docker)

### 3.2 Configuración de Alertas

**`prometheus/alerts.yml`**: Define alertas basadas en umbrales de métricas.

```yaml
groups:
  - name: system_alerts
    interval: 30s
    rules:
      # Alerta: CPU > 80% por 2 minutos
      - alert: HighCPUUsage
        expr: 100 - (avg(irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "Alto uso de CPU"
          description: "CPU al {{ $value }}%"

      # Alerta: Memoria > 85% por 2 minutos
      - alert: HighMemoryUsage
        expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 85
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "Alto uso de memoria"
          description: "Memoria al {{ $value }}%"

      # Alerta: Disco > 90% por 5 minutos
      - alert: DiskSpaceWarning
        expr: (1 - (node_filesystem_avail_bytes{mountpoint="/",fstype!="tmpfs"} / node_filesystem_size_bytes{mountpoint="/",fstype!="tmpfs"})) * 100 > 90
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Espacio en disco crítico"
          description: "Disco al {{ $value }}%"
```

**Componentes de una Alerta**:
- `alert`: Nombre de la alerta
- `expr`: Consulta PromQL que define la condición
- `for`: Tiempo que debe cumplirse la condición antes de disparar
- `labels`: Etiquetas para clasificar (severity, team, etc.)
- `annotations`: Mensajes descriptivos

### 3.3 Node Exporter: Métricas Recolectadas

Node Exporter expone métricas del sistema operativo en el endpoint `http://node-exporter:9100/metrics`.

**Métricas principales documentadas** (ver METRICS.md para detalles completos):

#### 1. CPU Usage (Uso de CPU)
**Query PromQL**:
```promql
100 - (avg(irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```

**Qué mide**: Porcentaje de CPU utilizada (invierte el tiempo idle).

**Utilidad**:
- Identificar picos de carga
- Planificar escalado vertical/horizontal
- Detectar procesos que consumen recursos

**Umbrales**:
- Normal: 0-70%
- Warning: 70-85%
- Critical: >85%

#### 2. Memory Usage (Uso de Memoria)
**Query PromQL**:
```promql
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100
```

**Qué mide**: Porcentaje de memoria RAM utilizada.

**Utilidad**:
- Prevenir OOM Killer (Linux mata procesos cuando no hay RAM)
- Detectar memory leaks
- Dimensionar instancias correctamente

**Umbrales**:
- Normal: 0-75%
- Warning: 75-90%
- Critical: >90%

#### 3. Disk Usage (Uso de Disco)
**Query PromQL**:
```promql
(1 - (node_filesystem_avail_bytes{mountpoint="/",fstype!="tmpfs"} / node_filesystem_size_bytes{mountpoint="/",fstype!="tmpfs"})) * 100
```

**Qué mide**: Porcentaje de espacio en disco utilizado en el filesystem raíz (`/`).

**Utilidad**:
- Prevenir disco lleno (causa fallos de aplicaciones)
- Detectar logs sin rotación
- Planificar crecimiento de almacenamiento

**Umbrales**:
- Normal: 0-80%
- Warning: 80-90%
- Critical: >90%

### 3.4 Apache Exporter: Métricas HTTP

**Métricas adicionales** (bonificación):

#### 4. HTTP Request Rate
```promql
rate(apache_accesses_total[1m])
```
Mide peticiones HTTP por segundo. Útil para detectar picos de tráfico o ataques DDoS.

#### 5. Apache Workers
```promql
apache_workers{state="busy"}
apache_workers{state="idle"}
```
Monitorea si el servidor tiene capacidad para manejar más peticiones.

#### 6. Data Transfer Rate
```promql
rate(apache_sent_kilobytes_total[1m])
```
Mide KB/segundo enviados. Útil para monitorear ancho de banda.

### 3.5 Verificación de Prometheus

```bash
# Acceder a Prometheus
http://localhost:9090

# Verificar targets (Status → Targets)
# Deben estar en estado UP:
- prometheus
- node-exporter
- apache

# Verificar alertas (Alerts)
# Deben aparecer las 3 alertas configuradas
```

---

## Paso 4: Visualización con Grafana (1.0 punto)

### 4.1 Provisioning Automático de Grafana

**Estructura de archivos**:
```
grafana/
├── provisioning/
│   ├── datasources/
│   │   └── prometheus.yml    # Configura Prometheus como datasource
│   └── dashboards/
│       └── dashboard.yml      # Apunta a los dashboards JSON
└── dashboards/
    └── system-monitoring.json # Dashboard personalizado
```

**`grafana/provisioning/datasources/prometheus.yml`**:
```yaml
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: false
```

**Función**: Grafana se conecta automáticamente a Prometheus sin configuración manual.

**`grafana/provisioning/dashboards/dashboard.yml`**:
```yaml
apiVersion: 1

providers:
  - name: 'default'
    orgId: 1
    folder: ''
    type: file
    disableDeletion: false
    updateIntervalSeconds: 10
    allowUiUpdates: true
    options:
      path: /var/lib/grafana/dashboards
```

**Función**: Carga automáticamente dashboards desde el directorio especificado.

### 4.2 Dashboard Personalizado

**`grafana/dashboards/system-monitoring.json`**: Dashboard con 7 paneles.

**Paneles incluidos**:

1. **CPU Usage** (Gauge)
   - Query: `100 - (avg(irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)`
   - Umbrales: Verde <70%, Amarillo 70-85%, Rojo >85%

2. **Memory Usage** (Gauge)
   - Query: `(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100`
   - Umbrales: Verde <70%, Amarillo 70-85%, Rojo >85%

3. **Disk Usage** (Gauge)
   - Query: `(1 - (node_filesystem_avail_bytes{mountpoint="/",fstype!="tmpfs"} / node_filesystem_size_bytes{mountpoint="/",fstype!="tmpfs"})) * 100`
   - Umbrales: Verde <80%, Amarillo 80-90%, Rojo >90%

4. **HTTP Requests Rate** (Time Series)
   - Query: `rate(apache_accesses_total[1m])`
   - Muestra peticiones por segundo en tiempo real

5. **Total HTTP Requests** (Gauge)
   - Query: `apache_accesses_total`
   - Contador acumulado desde inicio

6. **Apache Workers Status** (Pie Chart)
   - Queries: `apache_workers{state="busy"}` y `apache_workers{state="idle"}`
   - Visualiza distribución porcentual

7. **Apache Data Transfer Rate** (Gauge)
   - Query: `rate(apache_sent_kilobytes_total[1m])`
   - KB/segundo transferidos

### 4.3 Acceso a Grafana

```bash
# URL: http://localhost:3000
# Usuario: admin
# Contraseña: admin123

# Dashboard preconfigurado: "System Monitoring"
```

---

## Resumen de Configuraciones Clave

| Servicio | Puerto | Función | Configuración Principal |
|----------|--------|---------|------------------------|
| WebApp | 80, 443 | Aplicación Flask con Apache + SSL | `apache-config/webapp-ssl.conf` |
| MySQL | 3306 | Base de datos | `init.sql` con schema |
| Prometheus | 9090 | Recolección de métricas | `prometheus/prometheus.yml` |
| Node Exporter | 9100 | Métricas del sistema | Volumenes de /proc, /sys |
| Apache Exporter | 9117 | Métricas HTTP | Scrape de /server-status |
| Grafana | 3000 | Visualización | Provisioning automático |

---

## Comandos Útiles

```bash
# Ver logs de un servicio
docker logs webapp
docker logs prometheus

# Reiniciar un servicio
docker compose restart webapp

# Ver métricas en crudo
curl http://localhost:9100/metrics  # Node Exporter
curl http://localhost:9117/metrics  # Apache Exporter

# Verificar targets en Prometheus
curl http://localhost:9090/api/v1/targets | jq

# Rebuild completo
docker compose down
docker compose up -d --build
```

---

## Troubleshooting Común

### Problema: Apache no inicia
**Solución**: Verificar que el puerto 80/443 no esté ocupado.
```bash
netstat -tulpn | grep :80
```

### Problema: Prometheus no scrape métricas
**Solución**: Verificar que los servicios estén en la misma red Docker.
```bash
docker network inspect vagrant_app_network
```

### Problema: Grafana no muestra datos
**Solución**: Verificar que Prometheus esté configurado como datasource.
```bash
# En Grafana: Configuration → Data Sources → Prometheus
# URL debe ser: http://prometheus:9090
```

### Problema: Certificado SSL no válido
**Solución**: Es normal con certificados autofirmados. En producción usar Let's Encrypt.
```bash
# Regenerar certificados
docker exec webapp rm -rf /etc/apache2/ssl/*
docker compose restart webapp
```
