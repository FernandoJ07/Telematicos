# Documentación de Métricas

## Métricas del Sistema con Node Exporter

### 1. CPU Usage (Uso de CPU)

#### Consulta Prometheus
```promql
100 - (avg(irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```

#### Descripción Detallada
Esta métrica calcula el porcentaje de uso de CPU promediando el tiempo que la CPU **NO** está en modo idle (inactivo) en los últimos 5 minutos.

#### Componentes
- `node_cpu_seconds_total`: Contador que registra el tiempo total de CPU en cada modo
- `mode="idle"`: Filtra solo el tiempo que la CPU estuvo inactiva
- `irate(...[5m])`: Calcula la tasa instantánea en una ventana de 5 minutos
- `avg`: Promedia entre todos los cores de CPU
- `100 - ...`: Invierte el resultado para obtener el uso en lugar del idle

#### Utilidad en Monitoreo
- **Identificar picos de carga**: CPU >80% indica que el sistema está bajo presión
- **Planificar escalado**: Patrones consistentes de alta CPU sugieren necesidad de más recursos
- **Detectar procesos problemáticos**: Picos inesperados pueden indicar malware o bugs
- **Optimización**: Identificar horas pico para balanceo de carga

#### Umbrales Recomendados
- **Normal**: 0-70%
- **Warning**: 70-85%
- **Critical**: >85%

#### Ejemplo de Alerta
```yaml
- alert: HighCPUUsage
  expr: 100 - (avg(irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
  for: 2m
  labels:
    severity: warning
  annotations:
    summary: "Alto uso de CPU detectado"
    description: "CPU al {{ $value }}%"
```

---

### 2. Memory Usage (Uso de Memoria)

#### Consulta Prometheus
```promql
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100
```

#### Descripción Detallada
Calcula el porcentaje de memoria en uso comparando la memoria disponible con la memoria total del sistema.

#### Componentes
- `node_memory_MemAvailable_bytes`: Memoria disponible (incluye memoria que puede liberarse)
- `node_memory_MemTotal_bytes`: Memoria total instalada en el sistema
- `1 - ...`: Invierte para obtener memoria usada en lugar de disponible
- `* 100`: Convierte a porcentaje

#### Diferencia: MemAvailable vs MemFree
- **MemFree**: Memoria completamente sin usar
- **MemAvailable**: MemFree + memoria recuperable (buffers, cache)
- **MemAvailable es mejor** porque considera memoria que puede liberarse automáticamente

#### Utilidad en Monitoreo
- **Prevenir OOM Killer**: Linux mata procesos cuando se queda sin memoria
- **Optimizar caché**: Memoria alta puede indicar necesidad de ajustar caché de aplicaciones
- **Detectar memory leaks**: Uso creciente constante sugiere fugas de memoria
- **Dimensionar instancias**: Decidir cuánta RAM necesita una aplicación

#### Umbrales Recomendados
- **Normal**: 0-75%
- **Warning**: 75-90%
- **Critical**: >90%

#### Consultas Adicionales Útiles
```promql
# Memoria usada en GB
(node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / 1024 / 1024 / 1024

# Memoria swap en uso
(node_memory_SwapTotal_bytes - node_memory_SwapFree_bytes) / node_memory_SwapTotal_bytes * 100

# Memoria caché
node_memory_Cached_bytes / 1024 / 1024 / 1024
```

#### Ejemplo de Alerta
```yaml
- alert: HighMemoryUsage
  expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 85
  for: 2m
  labels:
    severity: warning
  annotations:
    summary: "Alto uso de memoria"
    description: "Memoria al {{ $value }}%"
```

---

### 3. Disk Usage (Uso de Disco)

#### Consulta Prometheus
```promql
(1 - (node_filesystem_avail_bytes{mountpoint="/",fstype!="tmpfs"} / node_filesystem_size_bytes{mountpoint="/",fstype!="tmpfs"})) * 100
```

#### Descripción Detallada
Calcula el porcentaje de espacio en disco utilizado en el sistema de archivos raíz (`/`).

#### Componentes
- `node_filesystem_avail_bytes`: Espacio disponible en bytes
- `node_filesystem_size_bytes`: Tamaño total del sistema de archivos
- `mountpoint="/"`: Filtra solo el sistema de archivos raíz
- `fstype!="tmpfs"`: Excluye sistemas de archivos temporales en memoria
- `1 - ...`: Invierte para obtener espacio usado
- `* 100`: Convierte a porcentaje

#### Utilidad en Monitoreo
- **Prevenir disco lleno**: Un disco lleno puede causar fallos de aplicación y corrupción de datos
- **Planificar crecimiento**: Proyectar cuándo se necesitará más almacenamiento
- **Detectar logs excesivos**: Crecimiento rápido puede indicar logs sin rotación
- **Optimizar backups**: Identificar qué archivos ocupan más espacio

#### Umbrales Recomendados
- **Normal**: 0-80%
- **Warning**: 80-90%
- **Critical**: >90%

#### Por qué el disco lleno es crítico
1. **Aplicaciones fallan**: No pueden escribir logs, datos temporales, etc.
2. **Base de datos corrupta**: MySQL/PostgreSQL pueden corromperse
3. **Sistema inestable**: Linux necesita espacio para swap y operaciones
4. **Inodes agotados**: Muchos archivos pequeños pueden agotar inodes

#### Consultas Adicionales Útiles
```promql
# Espacio disponible en GB
node_filesystem_avail_bytes{mountpoint="/",fstype!="tmpfs"} / 1024 / 1024 / 1024

# Uso de inodes
(1 - (node_filesystem_files_free / node_filesystem_files)) * 100

# Monitorear todos los mount points
(1 - (node_filesystem_avail_bytes / node_filesystem_size_bytes)) * 100

# I/O de disco (lecturas por segundo)
rate(node_disk_reads_completed_total[5m])

# I/O de disco (escrituras por segundo)
rate(node_disk_writes_completed_total[5m])
```

#### Ejemplo de Alertas
```yaml
- alert: DiskSpaceWarning
  expr: (1 - (node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"})) * 100 > 80
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "Espacio en disco bajo"
    description: "Disco al {{ $value }}% en {{ $labels.instance }}"

- alert: DiskSpaceCritical
  expr: (1 - (node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"})) * 100 > 90
  for: 2m
  labels:
    severity: critical
  annotations:
    summary: "Espacio en disco crítico"
    description: "Disco al {{ $value }}% en {{ $labels.instance }} - ACCIÓN INMEDIATA REQUERIDA"
```

---

## 📈 Métricas Adicionales Importantes

### 4. Network Traffic (Tráfico de Red)

#### Tráfico recibido (bytes/s)
```promql
rate(node_network_receive_bytes_total[5m])
```

#### Tráfico transmitido (bytes/s)
```promql
rate(node_network_transmit_bytes_total[5m])
```

#### Utilidad
- Detectar ataques DDoS
- Identificar transferencias grandes de datos
- Optimizar ancho de banda
- Troubleshooting de conectividad

---

### 5. Load Average (Carga del Sistema)

#### Consultas
```promql
# Load average 1 minuto
node_load1

# Load average 5 minutos
node_load5

# Load average 15 minutos
node_load15
```

#### Interpretación
- **Load < número de CPUs**: Sistema saludable
- **Load = número de CPUs**: Sistema en capacidad
- **Load > número de CPUs**: Sistema sobrecargado

#### Utilidad
- Indicador general de salud del sistema
- Detectar procesos bloqueados en I/O
- Planificar capacidad

---

### 6. Context Switches (Cambios de Contexto)

#### Consulta
```promql
rate(node_context_switches_total[5m])
```

#### Utilidad
- Alto número indica muchos procesos compitiendo por CPU
- Puede causar overhead y degradar performance
- Ayuda a identificar necesidad de optimización

---

## 🐳 Métricas de Contenedores (cAdvisor)

### CPU por Contenedor
```promql
rate(container_cpu_usage_seconds_total{name!=""}[5m]) * 100
```

### Memoria por Contenedor
```promql
container_memory_usage_bytes{name!=""}
```

### Memoria como porcentaje del límite
```promql
(container_memory_usage_bytes{name!=""} / container_spec_memory_limit_bytes{name!=""}) * 100
```

### Network I/O por Contenedor
```promql
rate(container_network_receive_bytes_total{name!=""}[5m])
rate(container_network_transmit_bytes_total{name!=""}[5m])
```

---

## 🎯 Mejores Prácticas

### 1. Intervalos de Scraping
- **Prometheus**: 15 segundos (balance entre granularidad y almacenamiento)
- **Node Exporter**: Siempre activo, sin overhead significativo

### 2. Retención de Datos
- **Por defecto**: 15 días
- **Recomendado producción**: 30-90 días
- **Almacenamiento estimado**: ~1GB por día para 10 targets

### 3. Agregación de Métricas
```promql
# Usar avg, min, max según contexto
avg(rate(node_cpu_seconds_total[5m]))  # Promedio
max(rate(node_cpu_seconds_total[5m]))  # Peor caso
min(node_memory_MemAvailable_bytes)    # Mínimo disponible
```

### 4. Alertas Efectivas
- **No alertar por todo**: Solo situaciones que requieren acción
- **Usar `for` clause**: Evitar alertas por picos temporales
- **Severidades claras**: Warning vs Critical
- **Mensajes accionables**: Incluir contexto y próximos pasos

---

## 📚 Recursos Adicionales

### Documentación Oficial
- [Prometheus Query Functions](https://prometheus.io/docs/prometheus/latest/querying/functions/)
- [Node Exporter Metrics](https://github.com/prometheus/node_exporter#collectors)
- [PromQL for Humans](https://timber.io/blog/promql-for-humans/)

### Dashboards Recomendados
- Node Exporter Full (ID: 1860)
- Docker and System Monitoring (ID: 179)
- Prometheus 2.0 Overview (ID: 3662)

### Libros y Cursos
- "Prometheus: Up & Running" - O'Reilly
- "Observability Engineering" - O'Reilly
- Course: Prometheus & Grafana (Udemy)

---

## 🔍 Troubleshooting de Métricas

### Problema: Métricas no aparecen
```bash
# Verificar targets en Prometheus
curl http://localhost:9090/api/v1/targets

# Ver logs de Prometheus
docker-compose logs prometheus

# Verificar que Node Exporter esté exponiendo métricas
curl http://localhost:9100/metrics
```

### Problema: Valores incorrectos
- Verificar zona horaria del sistema
- Asegurar que los relojes estén sincronizados (NTP)
- Revisar filtros en consultas PromQL

### Problema: Performance
- Reducir retención de datos
- Usar recording rules para consultas frecuentes
- Optimizar queries PromQL (evitar joins complejos)

---

##  M�tricas HTTP con Apache Exporter

Apache Exporter expone m�tricas del servidor web Apache para monitoreo de peticiones HTTP.

### 4. HTTP Request Rate (Tasa de Peticiones HTTP)

#### Consulta Prometheus
```promql
rate(apache_accesses_total[1m])
```

#### Descripci�n Detallada
Calcula la tasa de peticiones HTTP por segundo que Apache est� procesando.

#### Componentes
- `apache_accesses_total`: Contador total de peticiones HTTP procesadas
- `rate(...[1m])`: Calcula la tasa por segundo en una ventana de 1 minuto

#### Utilidad en Monitoreo
- **Detectar picos de tr�fico**: Identificar incrementos s�bitos de peticiones
- **Capacity planning**: Determinar si el servidor puede manejar la carga
- **Monitorear campa�as**: Ver el impacto de marketing o lanzamientos
- **Detectar ataques**: Tr�fico anormalmente alto puede indicar DDoS

#### Umbrales Recomendados
- **Normal**: 0-50 req/s (depende de la aplicaci�n)
- **Warning**: >100 req/s
- **Critical**: >200 req/s

---

### 5. Apache Workers (Trabajadores de Apache)

#### Workers ocupados
```promql
apache_workers{state="busy"}
```

#### Workers disponibles
```promql
apache_workers{state="idle"}
```

#### Descripci�n
Los workers son procesos/threads que Apache utiliza para manejar peticiones HTTP. Monitorear su estado ayuda a identificar si el servidor est� llegando a su l�mite de capacidad.

#### Utilidad
- **Detectar saturaci�n**: Si todos los workers est�n busy, nuevas peticiones esperar�n
- **Optimizar configuraci�n**: Ajustar `MaxRequestWorkers` seg�n demanda
- **Prevenir timeouts**: Workers ocupados = respuestas lentas

---

### 6. Apache Data Transfer (Transferencia de Datos)

#### Consulta Prometheus
```promql
rate(apache_sent_kilobytes_total[1m])
```

#### Descripci�n
Mide la cantidad de datos (en KB/s) que Apache est� enviando a los clientes.

#### Utilidad
- **Monitorear ancho de banda**: Detectar transferencias grandes
- **Optimizar contenido**: Identificar archivos pesados
- **Detectar descargas masivas**: Posible scraping o descarga no autorizada
- **Planificar costos**: En cloud, el tr�fico de salida tiene costo
