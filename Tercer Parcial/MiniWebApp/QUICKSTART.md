# Guía Rápida de Inicio

## ⚠️ IMPORTANTE

**Todo corre DENTRO de una VM**, no en tu máquina directamente.

Tu Windows solo necesita: Vagrant + VirtualBox + Git

---

## 🚀 Opción 1: Local (VM Vagrant)

```bash
# En tu máquina Windows
git clone https://github.com/FernandoJ07/Telematicos.git
cd "Telematicos/Tercer Parcial/MiniWebApp"

# Levantar VM (instala Docker y levanta servicios AUTOMÁTICAMENTE)
vagrant up

# Esperar 2-3 minutos mientras instala y construye todo
```

**¡Eso es todo!** Vagrant automáticamente:
- Instala Docker
- Construye la imagen webapp
- Levanta los 5 servicios (MySQL, WebApp, Prometheus, Node Exporter, Grafana)
- Crea las tablas de la base de datos

### Acceder a los servicios

Desde tu navegador en Windows:
- **WebApp**: https://localhost:8443
- **Grafana**: http://localhost:3000 (admin/admin123)
- **Prometheus**: http://localhost:9090

---

## ☁️ Opción 2: AWS EC2

### Requisitos
- Instancia EC2 Ubuntu 22.04
- Puertos abiertos: HTTP (80), HTTPS (443), Custom TCP (3000), Custom TCP (9090)

### Despliegue Rápido (Recomendado)

```bash
# Conectarse a la instancia EC2
ssh -i tu-key.pem ubuntu@tu-ip-publica

# Ejecutar script de despliegue automático
bash <(curl -s https://raw.githubusercontent.com/FernandoJ07/Telematicos/main/Tercer%20Parcial/MiniWebApp/scripts/deploy-aws.sh)
```

### O Despliegue Manual

```bash
# 1. Conectarse a la instancia EC2
ssh -i tu-key.pem ubuntu@tu-ip-publica

# 2. Clonar el repositorio
git clone https://github.com/FernandoJ07/Telematicos.git
cd "Telematicos/Tercer Parcial/MiniWebApp"

# 3. Ejecutar script de despliegue
chmod +x ./scripts/deploy-aws.sh
sudo ./scripts/deploy-aws.sh
```

**Acceder a los servicios:**
- WebApp: https://TU-IP-PUBLICA
- Grafana: http://TU-IP-PUBLICA:3000 (admin/admin123)
- Prometheus: http://TU-IP-PUBLICA:9090

### Reiniciar Instancia EC2

Si apagas y vuelves a encender la instancia, los contenedores no se inician automáticamente. 

**⚠️ Importante:** La IP pública cambiará cada vez que detengas/inicies la instancia.

```bash
# Conéctate con la nueva IP
ssh -i tu-key.pem ubuntu@NUEVA-IP-PUBLICA

# Levanta los servicios
cd ~/Telematicos/Tercer\ Parcial/MiniWebApp
sudo docker compose -f docker-compose.prod.yml up -d
```

---

## 🔧 Comandos Útiles

### Vagrant (desarrollo local)

```bash
vagrant status          # Ver estado de la VM
vagrant ssh            # Conectarse a la VM
vagrant reload         # Reiniciar VM
vagrant halt           # Apagar VM
vagrant destroy        # Eliminar VM
```

### Docker (dentro de la VM o EC2)

```bash
# En Vagrant
cd /vagrant

# En EC2 (si clonaste el repositorio)
cd ~/Telematicos/Tercer\ Parcial/MiniWebApp

# Comandos Docker Compose
docker compose ps              # Ver estado de servicios
docker compose logs webapp     # Ver logs de webapp
docker compose restart webapp  # Reiniciar webapp
docker compose down            # Detener todos los servicios
docker compose up -d           # Levantar todos los servicios
```

---

## 🐛 Solución de Problemas

### Build muy lento en AWS EC2 (más de 15 minutos)

Si el build de Docker tarda demasiado en EC2 (instancias pequeñas), usa la imagen pre-built de Docker Hub:

**El proyecto ya tiene dos configuraciones:**
- `docker-compose.yml` - Build local (Vagrant/desarrollo)
- `docker-compose.prod.yml` - Imagen de Docker Hub (AWS rápido)

**Paso 1: Buildear y subir imagen (solo una vez)**

```bash
# En tu PC local (Windows con PowerShell)
cd "c:\Users\User\Desktop\Repositories\Telematicos\Tercer Parcial\MiniWebApp"

# Login en Docker Hub
docker login

# Buildear imagen (5-10 min en PC local)
docker build -t alejandrobi/telematicos-webapp:latest .

# Subir a Docker Hub
docker push alejandrobi/telematicos-webapp:latest
```

**Paso 2: Deploy en EC2 con imagen**

```bash
# En EC2
cd ~/Telematicos/Tercer\ Parcial/MiniWebApp
sudo docker compose -f docker-compose.prod.yml pull
sudo docker compose -f docker-compose.prod.yml up -d
```

¡Listo! Deploy en segundos sin compilar nada.

**Nota:** El script `deploy-aws.sh` automáticamente usa `docker-compose.prod.yml` si existe

---

### WebApp no carga

```bash
# Verificar que la base de datos tenga las tablas
vagrant ssh -c "docker exec mysql_db mysql -uroot -proot myflaskapp -e 'SHOW TABLES;'"

# Si no aparece la tabla 'users', ejecutar:
vagrant ssh -c "docker exec -i mysql_db mysql -uroot -proot < /vagrant/init.sql"
```

### Servicios no arrancan

```bash
# Ver logs de errores
vagrant ssh -c "cd /vagrant && docker compose logs"

# Reconstruir y levantar
vagrant ssh -c "cd /vagrant && docker compose down && docker compose up -d --build"
```

### Prometheus no muestra métricas

```bash
# Verificar targets
# Ir a http://localhost:9090/targets
# Deben estar "UP": prometheus, node-exporter
```

### Grafana no muestra datos

```bash
# Verificar datasource Prometheus
# Ir a http://localhost:3000/datasources
# Debe estar conectado a http://prometheus:9090
```

---

Ver [README.md](README.md) para documentación completa.
