# Proyecto CloudNova - Despliegue Seguro, Monitoreo y Visualización

## 📋 Descripción

La empresa ficticia **CloudNova** desea migrar su aplicación web de desarrollo a un entorno de producción seguro y monitoreado. Este proyecto implementa un despliegue completo con las siguientes tecnologías:

- Servidor web Apache con SSL/TLS
- Base de datos MySQL
- Sistema de monitoreo con Prometheus y Node Exporter
- Visualización con Grafana
- Despliegue en AWS EC2

**Objetivo**: Garantizar disponibilidad, seguridad y visibilidad del rendimiento mediante herramientas de código abierto y servicios en la nube.

## ⚠️ CONCEPTO IMPORTANTE

**Todo corre DENTRO de una máquina virtual**, NO directamente en tu computadora:

- **Punto 1 (Local)**: Docker corre dentro de una VM Vagrant
- **Punto 2 (AWS)**: Docker corre dentro de una instancia EC2

Tu máquina Windows solo necesita Vagrant y VirtualBox.

## 🔧 Requisitos

**En tu máquina (Windows/Mac/Linux):**
- Vagrant 2.0+
- VirtualBox 6.0+
- Git
- 8GB RAM mínimo
- 20GB espacio en disco

**Para AWS EC2:**
- Cuenta AWS activa
- Par de claves SSH

## 🚀 Punto 1: Empaquetado y Despliegue Local con Docker (1.5 puntos)

### Objetivo
Configurar un servidor web con HTTPS, crear archivos Docker para orquestar la aplicación y verificar su funcionamiento local.

### Paso 1: Clonar repositorio

```bash
git clone https://github.com/FernandoJ07/Telematicos.git
cd Telematicos/Tercer\ Parcial/MiniWebApp
```

### Paso 2: Levantar VM con Vagrant (automático)

```bash
vagrant up
```

**Qué hace este comando:**
1. Crea VM Ubuntu 22.04 (4GB RAM, 2 CPUs)
2. Instala Docker y Docker Compose EN LA VM
3. Construye imágenes Docker
4. Levanta 6 servicios:
   - WebApp (Apache + Flask + SSL)
   - MySQL
   - Prometheus
   - Node Exporter
   - Apache Exporter
   - Grafana

⏱️ **Primera vez: 5-10 minutos**

### Paso 3: Verificar funcionamiento

**Acceder desde tu navegador Windows:**

| Servicio | URL desde Windows | URL desde VM |
|----------|-------------------|--------------|
| WebApp HTTP | http://localhost:8080 | http://192.168.60.3 |
| WebApp HTTPS | https://localhost:8443 | https://192.168.60.3 |
| Grafana | http://localhost:3000 | http://192.168.60.3:3000 |
| Prometheus | http://localhost:9090 | http://192.168.60.3:9090 |

**Credenciales Grafana**: admin / admin123

### Paso 4: Verificar redirección HTTP → HTTPS

Accede a http://localhost:8080 y verifica que automáticamente te redirija a https://localhost:8443.

**Archivos clave creados:**
- `Dockerfile`: Define la imagen del contenedor de la aplicación
- `docker-compose.yml`: Orquesta todos los servicios (webapp, MySQL, Prometheus, Grafana)
- `apache-config/webapp-ssl.conf`: Configuración de Apache con SSL y redirección HTTP→HTTPS

### Paso 4: Comandos útiles

```bash
# Conectarse a la VM
vagrant ssh

# Dentro de la VM
cd /vagrant
docker-compose ps          # Ver servicios
docker-compose logs -f     # Ver logs
docker-compose restart     # Reiniciar

# Salir de la VM
exit

# Desde tu máquina
vagrant halt               # Apagar VM
vagrant up                 # Encender VM
vagrant destroy -f         # Destruir VM
```

---

## ☁️ Punto 2: Despliegue en la Nube con AWS EC2 (1.0 punto)

### Objetivo
Desplegar la aplicación en una instancia EC2 de AWS y configurar las reglas de seguridad necesarias para acceso remoto.

### Paso 1: Crear instancia EC2

```bash
# En AWS Console
1. EC2 > Lanzar instancia
2. Ubuntu Server 22.04 LTS
3. Tipo: t2.medium (2 vCPUs, 4GB RAM)
4. Security Group (Reglas de entrada):
   - SSH (22) - Tu IP
   - HTTP (80) - 0.0.0.0/0
   - HTTPS (443) - 0.0.0.0/0
   - Grafana (3000) - 0.0.0.0/0
   - Prometheus (9090) - 0.0.0.0/0
5. Crear/seleccionar par de claves (.pem)
6. Configurar almacenamiento: 20GB SSD
```

### Paso 2: Conectarse por SSH

```bash
# Cambiar permisos de la clave
chmod 400 tu-clave.pem

# Conectar a la instancia
ssh -i "tu-clave.pem" ubuntu@<IP-PUBLICA-EC2>
```

### Paso 3: Instalar Docker en EC2

```bash
# Clonar repositorio
git clone https://github.com/FernandoJ07/Telematicos.git
cd Telematicos/Tercer\ Parcial/MiniWebApp

# Ejecutar script de provisionamiento
chmod +x scripts/provision-aws-ec2.sh
./scripts/provision-aws-ec2.sh

# Cerrar sesión y reconectar para aplicar cambios de grupo
exit
ssh -i "tu-clave.pem" ubuntu@<IP-PUBLICA-EC2>
```

### Paso 4: Desplegar aplicación con Docker Compose

```bash
cd Telematicos/Tercer\ Parcial/MiniWebApp

# Ejecutar script de despliegue
chmod +x scripts/deploy-aws.sh
./scripts/deploy-aws.sh

# Verificar que los contenedores estén corriendo
docker-compose ps
```

### Paso 5: Verificar acceso remoto

Accede desde tu navegador:
- **WebApp HTTPS**: https://`<IP-PUBLICA-EC2>`
- **Grafana**: http://`<IP-PUBLICA-EC2>`:3000 (admin/admin123)
- **Prometheus**: http://`<IP-PUBLICA-EC2>`:9090

**Nota**: Acepta la advertencia del certificado SSL autofirmado en tu navegador.

---

## 📊 Punto 3: Monitoreo con Prometheus y Node Exporter (1.5 puntos)

### Objetivo
Configurar Prometheus para recolectar métricas del sistema, documentar métricas específicas y configurar alertas básicas.

### Instalación y Configuración

Prometheus y Node Exporter ya están incluidos en `docker-compose.yml`:

```yaml
prometheus:
  image: prom/prometheus:latest
  volumes:
    - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
    - ./prometheus/alerts.yml:/etc/prometheus/alerts.yml

node-exporter:
  image: prom/node-exporter:latest
  command:
    - '--path.procfs=/host/proc'
    - '--path.sysfs=/host/sys'
```

### Configuración de prometheus.yml

El archivo `prometheus/prometheus.yml` define los targets a monitorear:

```yaml
scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']

  - job_name: 'apache-exporter'
    static_configs:
      - targets: ['apache-exporter:9117']
```

### Tres Métricas Específicas Documentadas

#### 1. **CPU Usage** - Uso de CPU del sistema

**Query PromQL:**
```promql
100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```

**¿Qué mide?**  
Porcentaje de CPU utilizada por el sistema (calculado como el inverso del tiempo ocioso).

**Utilidad en monitoreo Linux:**
- **Detección de picos de carga**: Identifica cuando el sistema está sobrecargado
- **Planificación de capacidad**: Ayuda a determinar cuándo escalar recursos
- **Análisis de rendimiento**: Identifica procesos que consumen CPU excesiva
- **Prevención de degradación**: Alerta antes de que el servicio se vuelva lento

---

#### 2. **Memory Usage** - Uso de memoria RAM

**Query PromQL:**
```promql
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100
```

**¿Qué mide?**  
Porcentaje de memoria RAM utilizada del total disponible en el sistema.

**Utilidad en monitoreo Linux:**
- **Prevención de OOM (Out of Memory)**: Evita que el kernel mate procesos críticos
- **Detección de memory leaks**: Identifica aplicaciones con fugas de memoria
- **Optimización de recursos**: Determina si hay memoria suficiente para nuevos servicios
- **Swapping**: Previene uso excesivo de swap que degrada rendimiento

---

#### 3. **Disk Usage** - Uso de espacio en disco

**Query PromQL:**
```promql
(1 - (node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"})) * 100
```

**¿Qué mide?**  
Porcentaje de espacio en disco utilizado en la partición raíz (/).

**Utilidad en monitoreo Linux:**
- **Prevención de fallos críticos**: Un disco lleno puede causar caída del sistema
- **Gestión de logs**: Identifica cuando los logs están consumiendo mucho espacio
- **Planificación de almacenamiento**: Ayuda a decidir cuándo ampliar capacidad
- **Aplicaciones**: Evita errores de escritura por falta de espacio

---

### Alertas Básicas Configuradas

El archivo `prometheus/alerts.yml` contiene las siguientes alertas:

---

### Alertas Básicas Configuradas

El archivo `prometheus/alerts.yml` contiene las siguientes alertas:

| Alerta | Condición | Severidad | Descripción |
|--------|-----------|-----------|-------------|
| HighCPUUsage | CPU > 80% por 2min | Warning | Alerta cuando la CPU supera el 80% de uso |
| HighMemoryUsage | Memoria > 85% por 2min | Warning | Alerta cuando la memoria RAM supera el 85% |
| DiskSpaceWarning | Disco > 90% por 5min | Warning | Alerta cuando el disco supera el 90% de uso |
| DiskSpaceCritical | Disco > 95% por 2min | Critical | Alerta crítica cuando el disco supera el 95% |
| ServiceDown | up == 0 por 1min | Critical | Alerta cuando un servicio monitoreado está caído |
| ContainerHighCPU | Container CPU > 80% | Warning | Alerta cuando un contenedor consume más del 80% CPU |

### Acceso a Prometheus

**Acceder a la interfaz web:**
- Local: http://localhost:9090
- AWS: http://`<IP-EC2>`:9090

**Rutas importantes:**
1. **Status > Targets**: Ver todos los endpoints monitoreados y su estado (UP/DOWN)
2. **Alerts**: Ver alertas activas y su estado (Pending/Firing)
3. **Graph**: Ejecutar consultas PromQL personalizadas
4. **Status > Configuration**: Ver configuración actual de Prometheus

---

## 📈 Punto 4: Visualización con Grafana (1.0 punto)

### Objetivo
Instalar Grafana, conectarlo a Prometheus y crear dashboards para visualizar métricas.

### Instalación

Grafana ya está incluido en `docker-compose.yml`:

```yaml
grafana:
  image: grafana/grafana:latest
  ports:
    - "3000:3000"
  environment:
    - GF_SECURITY_ADMIN_USER=admin
    - GF_SECURITY_ADMIN_PASSWORD=admin123
```

### Acceso a Grafana

**URL de acceso:**
- Local: http://localhost:3000
- AWS: http://`<IP-EC2>`:3000

**Credenciales:**
- Usuario: `admin`
- Contraseña: `admin123`

### Conexión a Prometheus

La conexión a Prometheus se configura automáticamente mediante provisioning:

**Archivo**: `grafana/provisioning/datasources/prometheus.yml`

```yaml
datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
```

### Dashboard Personalizado Creado

El dashboard incluye **dos paneles obligatorios más paneles adicionales**:

#### Panel 1: Uso de CPU y Memoria (Graph)
- Muestra tendencia histórica de CPU y RAM
- Permite identificar patrones de consumo
- Útil para planificación de capacidad

#### Panel 2: Espacio en Disco (Gauge)
- Indicador visual tipo velocímetro
- Muestra porcentaje de disco utilizado
- Colores: Verde (<70%), Amarillo (70-90%), Rojo (>90%)

#### Paneles Adicionales:
- **Network Traffic**: Tráfico de red (entrada/salida)
- **System Load**: Carga del sistema (1m, 5m, 15m)
- **Service Status**: Estado de servicios (UP/DOWN)
- **Container Metrics**: Métricas de contenedores Docker

### Importar Dashboard Preconfigurado

Grafana permite importar dashboards desde su biblioteca oficial:

**Paso 1**: En Grafana, ir a **Dashboards > Import**

**Paso 2**: Ingresar el ID del dashboard:
- **Node Exporter Full** (ID: 1860) - Métricas completas del sistema
- **Docker Container & Host Metrics** (ID: 179) - Métricas de contenedores
- **MySQL Overview** (ID: 7362) - Métricas de base de datos

**Paso 3**: Click en **Load**

**Paso 4**: Seleccionar **Prometheus** como datasource

**Paso 5**: Click en **Import**

**Verificación**: El dashboard importado debe mostrar métricas en tiempo real automáticamente.

---

## 📦 Servicios Incluidos en el Proyecto

### Resumen de Componentes

| Servicio | Puerto | Descripción |
|----------|--------|-------------|
| **WebApp** | 80, 443 | Apache + Flask con SSL/TLS |
| **MySQL** | 3306 | Base de datos MySQL 8.0 |
| **Prometheus** | 9090 | Sistema de monitoreo y alertas |
| **Node Exporter** | 9100 | Métricas del sistema Linux |
| **Apache Exporter** | 9117 | Métricas del servidor Apache |
| **Grafana** | 3000 | Visualización de métricas |

---

## 🔒 Seguridad

### SSL/TLS

Certificados autofirmados (desarrollo):
```bash
./scripts/generate-ssl-cert.sh localhost
```

Certificados Let's Encrypt (producción):
```bash
sudo apt-get install certbot python3-certbot-apache
sudo certbot --apache -d tudominio.com
```

### Headers de Seguridad

- Strict-Transport-Security: Forzar HTTPS
- X-Frame-Options: Prevenir clickjacking
- X-Content-Type-Options: Prevenir MIME sniffing
- X-XSS-Protection: Protección contra XSS

### Firewall (UFW)

Puertos abiertos:
- SSH: 22
- HTTP: 80
- HTTPS: 443
- Grafana: 3000
- Prometheus: 9090

## 🛠️ Scripts de Automatización

**provision-vm.sh**: Provisiona VM Vagrant con Docker

**provision-aws-ec2.sh**: Instala Docker en EC2

**deploy-aws.sh**: Despliega aplicación en EC2

**generate-ssl-cert.sh**: Genera certificados SSL
```bash
./scripts/generate-ssl-cert.sh [dominio]
```

**health-check.sh**: Verifica estado de servicios
```bash
./scripts/health-check.sh
```

**backup.sh**: Backup de base de datos
```bash
./scripts/backup.sh
```

## 🔍 Troubleshooting

### No se puede acceder a la aplicación

```bash
# En la VM
vagrant ssh
cd /vagrant
docker-compose ps          # Ver estado
docker-compose logs webapp # Ver logs
docker-compose restart webapp
```

### Error de conexión a MySQL

```bash
docker-compose logs db
docker-compose restart db
docker-compose exec webapp mysql -h db -u root -proot -e "SELECT 1"
```

### Prometheus no muestra métricas

```bash
docker-compose logs prometheus
# Verificar targets en: http://localhost:9090/targets
```

### Comandos útiles

```bash
# Ver todos los logs
docker-compose logs -f

# Reiniciar servicios
docker-compose restart

# Detener todo
docker-compose down

# Ver uso de recursos
docker stats

# Entrar a un contenedor
docker-compose exec webapp bash

# Limpiar recursos
docker system prune -a
```

## Conclusión Técnica

### ¿Qué aprendí al integrar Docker, AWS y Prometheus?

Aprendí cómo funciona el ciclo completo de despliegue de aplicaciones web. Docker me ayudó a empaquetar todo en contenedores para que funcione igual en cualquier lugar. AWS me mostró cómo poner aplicaciones en la nube de forma real. Y con Prometheus y Grafana entendí la importancia de poder ver qué está pasando con el servidor y la aplicación en tiempo real, para poder detectar problemas antes de que se vuelvan graves.

---

### ¿Qué fue lo más desafiante y cómo lo resolvería en un entorno real?

Lo más difícil fue configurar el SSL en Docker y hacer que todos los servicios se inicien en el orden correcto. A veces MySQL no estaba listo cuando la aplicación intentaba conectarse y daba error. También fue complicado entender bien cómo funcionan las métricas de Prometheus al principio.

En un entorno real usaría certificados válidos de Let's Encrypt en lugar de autofirmados, haría respaldos automáticos de la base de datos, y tendría varias instancias de la aplicación en diferentes servidores para que si uno falla los demás sigan funcionando.

---

### ¿Qué beneficio aporta la observabilidad en el ciclo DevOps?

La observabilidad te permite saber qué está pasando con tu aplicación en todo momento. Es como tener un tablero de instrumentos en un carro: puedes ver la velocidad, la gasolina, la temperatura del motor, etc. Sin eso, no sabrías si algo está mal hasta que el carro se apague.

Con Prometheus y Grafana puedes ver si el servidor está consumiendo mucha CPU o memoria, si el disco se está llenando, o si algún servicio dejó de funcionar. Las alertas te avisan antes de que haya un problema grave. También puedes revisar el historial para entender qué pasó cuando algo falló. Básicamente, te da control y tranquilidad de que todo está funcionando bien, y si no, sabes exactamente dónde está el problema.

---

## 📚 Referencias y Recursos

## 📚 Referencias y Recursos

### Documentación Oficial
- [Docker Documentation](https://docs.docker.com/) - Contenedorización y Docker Compose
- [Prometheus Documentation](https://prometheus.io/docs/) - Sistema de monitoreo y alertas
- [Grafana Documentation](https://grafana.com/docs/) - Visualización de métricas
- [AWS EC2 Documentation](https://docs.aws.amazon.com/ec2/) - Instancias en la nube
- [Apache HTTP Server](https://httpd.apache.org/docs/) - Servidor web y SSL/TLS

### Recursos Adicionales Utilizados
- [Asegurar Apache con SSL en Docker](https://www.digitalocean.com/community/tutorials/how-to-secure-apache-with-let-s-encrypt-on-ubuntu)
- [Guía de instalación de Prometheus en Ubuntu](https://prometheus.io/docs/prometheus/latest/installation/)
- [Node Exporter en GitHub](https://github.com/prometheus/node_exporter)
- [Integración Grafana + Prometheus](https://prometheus.io/docs/visualization/grafana/)

---

## 📁 Estructura del Repositorio

```
MiniWebApp/
├── README.md                      # Este archivo
├── QUICKSTART.md                  # Guía rápida de inicio
├── METRICS.md                     # Documentación de métricas
├── Dockerfile                     # Imagen de la aplicación
├── docker-compose.yml             # Orquestación de servicios
├── docker-compose.prod.yml        # Configuración para producción
├── requirements.txt               # Dependencias Python
├── Vagrantfile                    # VM para desarrollo local
├── apache-config/
│   ├── webapp.conf                # VirtualHost HTTP
│   ├── webapp-ssl.conf            # VirtualHost HTTPS
│   └── webapp.wsgi                # Configuración WSGI
├── prometheus/
│   ├── prometheus.yml             # Configuración de Prometheus
│   └── alerts.yml                 # Reglas de alertas
├── grafana/
│   ├── dashboards/
│   │   └── system-monitoring.json # Dashboard personalizado
│   └── provisioning/
│       ├── datasources/
│       │   └── prometheus.yml     # Datasource Prometheus
│       └── dashboards/
│           └── dashboards.yml     # Provisioning de dashboards
├── scripts/
│   ├── provision-vm.sh            # Provisionar VM Vagrant
│   ├── provision-aws-ec2.sh       # Instalar Docker en EC2
│   └── deploy-aws.sh              # Desplegar en AWS
└── webapp/
    ├── run.py                     # Aplicación Flask
    ├── config.py                  # Configuración
    └── users/                     # Módulo de usuarios
```

---

## Entrega de Resultados

Repositorio público en GitHub con todos los archivos de configuración, scripts, dashboards y este README explicativo. Incluye evidencias del despliegue mediante capturas de pantalla o video corto.

**Link del repositorio**: https://github.com/FernandoJ07/Telematicos

---

**Proyecto**: CloudNova - Despliegue Seguro, Monitoreo y Visualización  
**Empresa Ficticia**: CloudNova  
**Curso**: Redes Telemáticas - Tercer Parcial  
**Tecnologías**: Docker, AWS EC2, Prometheus, Grafana, Apache, MySQL
