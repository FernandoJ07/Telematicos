# Segundo Parcial - Configuración de Red con Firewall, DNS y FTP

## Autores
- **Fernando Cedeño**
- **Alejandro Bravo**

## Descripción General

Este segundo parcial implementa una arquitectura de red con tres máquinas virtuales:
- **Firewall (192.168.50.12)**: Actúa como gateway y punto de control de acceso
- **Maestro (192.168.50.10)**: Servidor DNS maestro y servidor FTP
- **Esclavo (192.168.50.11)**: Servidor DNS esclavo

## Arquitectura de Red

```
Cliente/Internet → Firewall (192.168.50.12) → Esclavo (192.168.50.11) → Maestro (192.168.50.10)
                                           
```

## Configuración del Firewall

### 1. Configuración NAT (/etc/ufw/before.rules)

El firewall está configurado para redirigir el tráfico entrante hacia los servidores correspondientes:

- **FTP**: Puerto 21 y rango 40000:40010 → Maestro (192.168.50.10)
- **DNS**: Puerto 53 (TCP/UDP) → Esclavo (192.168.50.11)
- **HTTP/HTTPS**: Puertos 80/443 → Maestro (192.168.50.10)

### 2. Políticas UFW

- **Entrada**: DENY (denegado por defecto)
- **Salida**: ACCEPT (permitido)
- **Reenvío**: ACCEPT (permitido)

### 3. Puertos Abiertos

- SSH (22/tcp)
- FTP (21/tcp y 40000:40010/tcp)
- DNS (53/tcp y 53/udp)
- HTTP (80/tcp)
- HTTPS (443/tcp)

## Configuración del Servidor Maestro

### Servicios Activos
- **DNS Maestro**: BIND9 configurado como servidor autoritativo
- **FTP**: Servidor FTP con SSL/TLS y modo pasivo

### Configuración DNS
- Escucha solo en 192.168.50.10
- Permite consultas desde esclavo (192.168.50.11) y firewall (192.168.50.12)
- Permite transferencias de zona hacia el esclavo
- Recursividad habilitada
- Validación DNSSEC automática

### Configuración FTP
- Modo pasivo habilitado (puertos 40000:40010)
- SSL/TLS habilitado para seguridad
- Acceso solo a usuarios locales autenticados
- Dirección pasiva configurada hacia el firewall (192.168.50.12)
- Logging completo de transferencias

## Configuración del Servidor Esclavo

### Servicios Activos
- **DNS Esclavo**: BIND9 configurado como servidor secundario

### Configuración DNS
- Escucha solo en 192.168.50.11
- Recibe transferencias automáticas del maestro
- Solo acepta consultas desde el firewall (192.168.50.12)
- Zonas configuradas como 'slave' (empresa.local y zona inversa)
- Archivos almacenados en cache para redundancia

### Configuración del Sistema
- Reenvío IP habilitado para funcionalidad de red
- Configuraciones de seguridad ICMP implementadas
- Parámetros del kernel optimizados

## Configuración del Servidor Esclavo

- **DNS Esclavo**: Recibe transferencias de zona del maestro
- Proporciona redundancia para el servicio DNS
- Responde a consultas DNS redirigidas desde el firewall
- Configurado con parámetros de seguridad del kernel

## Flujo de Tráfico

1. **Consultas DNS**: Cliente → Firewall → Esclavo → Maestro (si es necesario)
2. **Conexiones FTP**: Cliente → Firewall → Maestro (192.168.50.10)
3. **Tráfico HTTP/HTTPS**: Cliente → Firewall → Maestro (192.168.50.10)

### Explicación del Flujo DNS
- **Firewall** recibe la consulta del cliente y la redirige al **Esclavo (192.168.50.11)**
- **Esclavo** intenta resolver la consulta desde su cache/zona local
- Si el **Esclavo** no puede resolver, realiza consulta recursiva al **Maestro (192.168.50.10)**
- La respuesta regresa por el mismo camino: Maestro → Esclavo → Firewall → Cliente

## Configuraciones Implementadas

### **Firewall (192.168.50.12)**
- ✅ Reglas NAT para redirección de FTP, DNS y HTTP/HTTPS
- ✅ Configuración UFW con puertos específicos abiertos
- ✅ MASQUERADE para respuestas bidireccionales
- ✅ Políticas de seguridad configuradas

### **Maestro (192.168.50.10)**
- ✅ Configuración BIND9 con acceso restringido
- ✅ Solo escucha en IP específica (192.168.50.10)
- ✅ Permite consultas y transferencias solo a esclavo y firewall
- ✅ Configuración de seguridad DNS (DNSSEC, recursividad)
- ✅ Servidor FTP con modo pasivo configurado
- ✅ SSL/TLS habilitado para FTP
- ✅ Integración perfecta con redirección del firewall

### **Esclavo (192.168.50.11)**
- ✅ Configuración como DNS secundario (slave)
- ✅ Recibe transferencias automáticas del maestro
- ✅ Responde consultas DNS desde el firewall
- ✅ Configuración de seguridad del kernel
- ✅ Zonas directa e inversa configuradas

## Flujo de Tráfico

1. **Consultas DNS**: Cliente → Firewall → Esclavo (192.168.50.11)
2. **Conexiones FTP**: Cliente → Firewall → Maestro (192.168.50.10)
3. **Tráfico HTTP/HTTPS**: Cliente → Firewall → Maestro (192.168.50.10)

## Archivos de Configuración

### Firewall
- `firewall/before.rules`: Reglas NAT para redirección de tráfico
- `firewall/ufw-default`: Configuración por defecto de UFW
- `firewall/ufw-status.txt`: Estado actual de las reglas UFW

### Maestro
- `maestro/named.conf.options`: Configuración principal del DNS maestro
- `maestro/vsftpd.conf`: Configuración completa del servidor FTP
- `maestro/EXPLICACION.md`: Explicación detallada del servidor maestro

### Esclavo
- `esclavo/named.conf.options`: Configuración del DNS esclavo
- `esclavo/named.conf.local`: Configuración de zonas esclavas
- `esclavo/sysctl-config.txt`: Configuración del kernel para seguridad
- `esclavo/EXPLICACION.md`: Explicación detallada del servidor esclavo

## Notas de Seguridad

- El firewall actúa como única entrada a la red interna
- Todos los servicios están restringidos a IPs específicas
- MASQUERADE configurado para mantener la conectividad de respuesta
- Validación DNSSEC habilitada para mayor seguridad DNS

## Próximas Configuraciones (Completadas)

- ✅ Configuración completa del servidor esclavo
- ✅ Configuración detallada del servidor FTP
- ✅ Zonas DNS específicas para servidor esclavo
- ✅ Configuraciones adicionales de seguridad

## Documentación Técnica Completa

Cada componente incluye documentación detallada con:
- Explicaciones técnicas de cada configuración
- Justificaciones de seguridad
- Diagramas de flujo de tráfico
- Procedimientos de implementación
- Consideraciones de rendimiento y escalabilidad