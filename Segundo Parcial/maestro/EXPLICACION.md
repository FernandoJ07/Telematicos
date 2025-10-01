# Servidor Maestro - Configuración DNS y FTP

## Rol del Servidor Maestro

El servidor maestro (192.168.50.10) cumple una función dual en la arquitectura:

1. **Servidor DNS Maestro**: Servidor autoritativo para las zonas DNS
2. **Servidor FTP**: Proporciona servicios de transferencia de archivos

## Configuración DNS (BIND9)

### Características Principales

#### Escucha en IP Específica
```bash
listen-on { 192.168.50.10; };
```
- Solo acepta conexiones en la interfaz de red interna
- Mejora la seguridad al no exponer el servicio en todas las interfaces

#### Control de Acceso a Consultas
```bash
allow-query { 192.168.50.11; 192.168.50.12; };
```
- **192.168.50.11**: Servidor esclavo (puede consultar para sincronización)
- **192.168.50.12**: Firewall (puede consultar para redirección)

#### Transferencias de Zona
```bash
allow-transfer { 192.168.50.11; 192.168.50.12; };
```
- Permite al servidor esclavo obtener copias de las zonas DNS
- Permite al firewall acceder a información de zona si es necesario

#### Configuraciones de Seguridad
```bash
recursion yes;                    # Permite resolver nombres externos
dnssec-validation auto;           # Validación automática DNSSEC
auth-nxdomain no;                # Cumplimiento RFC para respuestas
```

### Ventajas de la Configuración

1. **Seguridad**: Acceso restringido solo a máquinas autorizadas
2. **Eficiencia**: Solo escucha en la interfaz necesaria
3. **Redundancia**: Permite transferencias al servidor esclavo
4. **Compatibilidad**: IPv6 deshabilitado para simplificar la configuración

## Configuración FTP (vsftpd)

### Características Principales

#### Configuración Básica
```bash
listen=YES                    # Ejecutar como daemon independiente
listen_ipv6=NO               # Deshabilitar IPv6
anonymous_enable=NO          # Deshabilitar acceso anónimo
local_enable=YES             # Permitir usuarios locales
write_enable=YES             # Permitir escritura
```

#### Configuración de Modo Pasivo
```bash
pasv_enable=YES              # Habilitar modo pasivo
pasv_min_port=40000         # Puerto mínimo para datos pasivos
pasv_max_port=40010         # Puerto máximo para datos pasivos
pasv_address=192.168.50.12  # CRUCIAL: IP del firewall para redirección
```

#### Configuración de Seguridad
```bash
ssl_enable=YES              # Habilitar SSL/TLS
use_localtime=YES           # Usar zona horaria local
xferlog_enable=YES          # Habilitar logging de transferencias
connect_from_port_20=YES    # Conexiones desde puerto 20 estándar
```

### Integración con Firewall

#### Redirección de Puertos
- El firewall redirige automáticamente el tráfico FTP al maestro
- **Puerto 21**: Canal de control FTP
- **Puertos 40000:40010**: Rango para conexiones de datos en modo pasivo

#### Dirección Pasiva Crítica
```bash
pasv_address=192.168.50.12
```
- **MUY IMPORTANTE**: La dirección pasiva debe ser la IP del firewall
- Permite que los clientes se conecten correctamente a través de NAT
- El firewall redirige las conexiones de datos al maestro automáticamente

### Características de Seguridad

#### Autenticación
- **No acceso anónimo**: Solo usuarios autenticados
- **Usuarios locales**: Autenticación contra sistema local
- **SSL/TLS habilitado**: Conexiones cifradas disponibles

#### Logging y Monitoreo
- **Transferencias registradas**: Todas las subidas/descargas se loguean
- **Zona horaria local**: Timestamps en hora local para facilitar auditoría

## Beneficios de la Arquitectura

### Para DNS
1. **Autoridad centralizada**: El maestro mantiene las zonas originales
2. **Distribución eficiente**: El esclavo distribuye la carga de consultas
3. **Actualización coordinada**: Los cambios se propagan automáticamente

### Para FTP
1. **Acceso controlado**: Solo desde la red interna
2. **Integración con firewall**: Redirección transparente
3. **Configuración simplificada**: Un solo servidor FTP para gestionar

## Interacción con Otros Servidores

### Con el Firewall (192.168.50.12)
- Recibe tráfico FTP y HTTP/HTTPS redirigido
- Puede realizar consultas DNS al maestro si es necesario

### Con el Esclavo (192.168.50.11)
- Proporciona transferencias de zona DNS
- El esclavo actúa como servidor DNS secundario

## Consideraciones de Rendimiento

1. **Separación de carga**: DNS principalmente por el esclavo, FTP por el maestro
2. **Recursos optimizados**: Cada servidor se especializa en sus servicios
3. **Escalabilidad**: Fácil agregar más servidores esclavos si es necesario

## Próximas Configuraciones Pendientes

- Configuración de zonas DNS específicas (db.empresa.local, etc.)
- Configuración detallada del servidor FTP (vsftpd)
- Políticas de acceso más granulares
- Monitoreo y logging de servicios