# Proyecto Telemáticos - Despliegue Seguro, Monitoreo y Visualización

## 📋 Descripción

Este proyecto implementa un despliegue completo de una aplicación web con Docker, incluyendo:
- Servidor web Apache con SSL/TLS
- Base de datos MySQL
- Sistema de monitoreo con Prometheus y Node Exporter
- Visualización con Grafana

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

## 🚀 Punto 1: Despliegue Local (VM Vagrant)

### Paso 1: Clonar repositorio

```bash
git clone https://github.com/FernandoJ07/Telematicos.git
cd Telematicos/Tercer\ Parcial/MiniWebApp
```

### Paso 2: Levantar VM (automático)

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
   - Grafana
   - cAdvisor

⏱️ **Primera vez: 5-10 minutos**

### Paso 3: Acceder a los servicios

Desde tu navegador Windows:

| Servicio | URL desde Windows | URL desde VM |
|----------|-------------------|--------------|
| WebApp HTTP | http://localhost:8080 | http://192.168.60.3 |
| WebApp HTTPS | https://localhost:8443 | https://192.168.60.3 |
| Grafana | http://localhost:3000 | http://192.168.60.3:3000 |
| Prometheus | http://localhost:9090 | http://192.168.60.3:9090 |

**Credenciales Grafana**: admin / admin123

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

## ☁️ Punto 2: Despliegue en AWS EC2

### Paso 1: Crear instancia EC2

```bash
# En AWS Console
1. EC2 > Lanzar instancia
2. Ubuntu Server 22.04 LTS
3. Tipo: t2.medium
4. Security Group:
   - SSH (22)
   - HTTP (80)
   - HTTPS (443)
   - Grafana (3000)
   - Prometheus (9090)
5. Crear/seleccionar par de claves
```

### Paso 2: Conectarse por SSH

```bash
ssh -i "tu-clave.pem" ubuntu@<IP-PUBLICA-EC2>
```

### Paso 3: Clonar y provisionar

```bash
# Clonar repositorio
git clone https://github.com/FernandoJ07/Telematicos.git
cd Telematicos/Tercer\ Parcial/MiniWebApp

# Ejecutar provisionamiento
./scripts/provision-aws-ec2.sh

# Cerrar y reconectar
exit
ssh -i "tu-clave.pem" ubuntu@<IP-PUBLICA-EC2>
```

### Paso 4: Desplegar aplicación

```bash
cd Telematicos/Tercer\ Parcial/MiniWebApp
./scripts/deploy-aws.sh
```

### Paso 5: Acceder

- WebApp: https://`<IP-EC2>`
- Grafana: http://`<IP-EC2>`:3000
- Prometheus: http://`<IP-EC2>`:9090

## 📊 Servicios Incluidos

**WebApp** (puertos 80, 443)
- Apache 2.4 con mod_wsgi
- Flask application
- SSL/TLS con certificados autofirmados
- Redirección HTTP→HTTPS automática

**MySQL** (puerto 3306)
- Base de datos MySQL 8.0
- Datos persistentes en volumen Docker

**Prometheus** (puerto 9090)
- Recolección de métricas cada 15s
- 12 alertas configuradas (CPU, memoria, disco, servicios)
- Retención de 15 días

**Node Exporter** (puerto 9100)
- Métricas del sistema Linux
- CPU, memoria, disco, red, procesos

**Grafana** (puerto 3000)
- Dashboard personalizado con 8 paneles
- Auto-provisioning de datasources
- Credenciales: admin/admin123

**cAdvisor** (puerto 8080)
- Métricas de contenedores Docker
- Uso de recursos por contenedor

## 📈 Monitoreo con Prometheus

### Métricas Principales

**1. CPU Usage**
```promql
100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```
Mide el porcentaje de uso de CPU. Útil para detectar picos de carga y planificar escalado.

**2. Memory Usage**
```promql
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100
```
Mide el porcentaje de memoria utilizada. Previene OOM (Out of Memory) kills.

**3. Disk Usage**
```promql
(1 - (node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"})) * 100
```
Mide el espacio en disco usado. Crítico para evitar fallos por disco lleno.

### Alertas Configuradas

| Alerta | Condición | Severidad |
|--------|-----------|-----------|
| HighCPUUsage | CPU > 80% por 2min | Warning |
| HighMemoryUsage | Memoria > 85% por 2min | Warning |
| DiskSpaceWarning | Disco > 90% por 5min | Warning |
| DiskSpaceCritical | Disco > 95% por 2min | Critical |
| ServiceDown | up == 0 por 1min | Critical |
| ContainerHighCPU | Container CPU > 80% | Warning |

### Acceso a Prometheus

1. Abrir: http://localhost:9090 (VM local) o http://`<IP-EC2>`:9090 (AWS)
2. **Status > Targets**: Ver todos los endpoints monitoreados
3. **Alerts**: Ver alertas activas
4. **Graph**: Ejecutar consultas PromQL personalizadas

## 📈 Visualización con Grafana

### Dashboard Personalizado

El dashboard incluye:
- Indicadores de CPU, memoria y disco (gauges)
- Gráficos históricos de CPU y memoria
- Evolución del espacio en disco
- Tráfico de red (entrada/salida)
- Estado de los servicios (UP/DOWN)

### Dashboards Adicionales

Se pueden importar desde Grafana Labs:
- Node Exporter Full (ID: 1860)
- Docker Container & Host Metrics (ID: 179)
- MySQL Overview (ID: 7362)

Para importar: Dashboard > Import > [ID] > Load > Seleccionar Prometheus > Import

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

## 💡 Conclusiones Técnicas

### ¿Qué aprendí al integrar Docker, AWS y Prometheus?

La integración de estas tecnologías permitió comprender el ciclo completo de DevOps:

1. **Contenedorización**: Docker facilita el empaquetado y despliegue, garantizando consistencia entre entornos.

2. **Infraestructura como Código**: docker-compose.yml y scripts de provisionamiento permiten versionar y reproducir toda la infraestructura.

3. **Observabilidad**: Prometheus y Grafana son esenciales para entender el comportamiento real de las aplicaciones en producción.

4. **Cloud Computing**: AWS EC2 proporciona flexibilidad y escalabilidad para desplegar infraestructura compleja.

### ¿Qué fue lo más desafiante?

**Desafíos encontrados:**

1. **Configuración de SSL en contenedores**: Integrar Apache con SSL dentro de Docker requirió entender el ciclo de vida de los contenedores.
   - Solución: Health checks y scripts de espera en el entrypoint.

2. **Dependencias entre servicios**: Asegurar que MySQL esté listo antes de que la aplicación intente conectarse.
   - Solución: Health checks y `depends_on` con condiciones.

3. **Persistencia de datos**: Garantizar que los datos no se pierdan al reiniciar contenedores.
   - Solución: Volúmenes de Docker y backups automatizados.

### ¿Qué beneficio aporta la observabilidad?

La observabilidad es fundamental en DevOps:

1. **Detección proactiva**: Las alertas permiten identificar problemas antes de que afecten usuarios.

2. **Toma de decisiones**: Las métricas históricas ayudan a planificar escalado y optimizar recursos.

3. **Debugging rápido**: Cuando ocurre un problema, las métricas permiten identificar la causa raíz.

4. **SLI/SLO/SLA**: Las métricas son la base para definir acuerdos de nivel de servicio.

5. **Mejora continua**: Ver métricas en tiempo real crea conciencia sobre el rendimiento.

6. **Validación de cambios**: Las métricas confirman que los despliegues fueron exitosos.

**Sin observabilidad, se opera a ciegas.**

## 📚 Referencias

- [Docker Documentation](https://docs.docker.com/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [AWS EC2](https://docs.aws.amazon.com/ec2/)

---

**Proyecto**: Despliegue Seguro, Monitoreo y Visualización en la Nube  
**Curso**: Redes Telemáticas - Tercer Parcial
