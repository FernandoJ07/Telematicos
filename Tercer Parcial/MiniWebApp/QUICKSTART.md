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
./scripts/deploy-aws.sh
```

**Acceder a los servicios:**
- WebApp: https://TU-IP-PUBLICA
- Grafana: http://TU-IP-PUBLICA:3000 (admin/admin123)
- Prometheus: http://TU-IP-PUBLICA:9090

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
