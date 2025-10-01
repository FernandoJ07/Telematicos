# Servidor Esclavo - Configuración DNS Secundario

## Rol del Servidor Esclavo

El servidor esclavo (192.168.50.11) funciona como **servidor DNS primario de consultas** en la arquitectura. Sus principales características son:

1. **Punto de entrada DNS**: Recibe TODAS las consultas DNS redirigidas desde el firewall
2. **Servidor DNS Esclavo**: Mantiene copias de las zonas DNS del maestro
3. **Resolución recursiva**: Puede consultar al maestro y otros servidores para resolver nombres
4. **Redundancia**: Proporciona continuidad del servicio DNS

## Flujo de Resolución DNS

### Proceso Completo
1. **Cliente** envía consulta DNS
2. **Firewall** redirige la consulta al **Esclavo (192.168.50.11)**
3. **Esclavo** verifica si puede resolver desde su cache/zona local
4. Si no puede resolver, **Esclavo** realiza consulta recursiva al **Maestro (192.168.50.10)**
5. **Maestro** responde al **Esclavo**
6. **Esclavo** responde al **Firewall**
7. **Firewall** responde al **Cliente**

## Configuración DNS (BIND9)

### Características del Servidor Esclavo

#### Escucha Específica
```bash
listen-on { 192.168.50.11; };
```
- Solo acepta conexiones en su IP específica
- Optimiza recursos y mejora seguridad

#### Control de Consultas
```bash
allow-query { 192.168.50.12; 127.0.0.1; };
```
- **192.168.50.12 (Firewall)**: Recibe consultas redirigidas de clientes
- **127.0.0.1 (Localhost)**: Para consultas internas del sistema

#### Recursividad Habilitada
```bash
recursion yes;
```
- **CRÍTICO**: Permite al esclavo realizar consultas recursivas
- Cuando no puede resolver una consulta, consulta al maestro
- Implementa el flujo: Firewall → Esclavo → Maestro

#### Política de Transferencias
```bash
allow-transfer { none; };
```
- **NO permite transferencias** hacia otros servidores
- Solo **RECIBE** transferencias del maestro
- Implementa el principio de jerarquía DNS

### Configuración de Zonas

#### Zona Directa (empresa.local)
```bash
zone "empresa.local" {
    type slave;
    file "/var/cache/bind/db.empresa.local";
    masters { 192.168.50.10; };
    allow-query { 192.168.50.12; 127.0.0.1; };
};
```

#### Zona Inversa (192.168.50.x)
```bash
zone "50.168.192.in-addr.arpa" {
    type slave;
    file "/var/cache/bind/db.192";
    masters { 192.168.50.10; };
    allow-query { 192.168.50.12; 127.0.0.1; };
};
```

### Características de las Zonas Esclavas

1. **Tipo slave**: Servidor secundario que recibe datos
2. **Archivos en cache**: Los archivos se almacenan en `/var/cache/bind/`
3. **Maestro único**: Solo recibe transferencias de 192.168.50.10
4. **Consultas restringidas**: Solo firewall y localhost

## Configuración del Sistema

### Parámetros del Kernel (sysctl)

#### Reenvío IP
```bash
net.ipv4.ip_forward = 1
```
- Habilita el reenvío de paquetes IPv4
- Necesario para funcionar como parte de la infraestructura de red

#### Seguridad ICMP
```bash
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
```
- Mejora la seguridad contra ataques ICMP
- Previene redirecciones maliciosas

## Ventajas de la Configuración Esclava

### Para el Sistema
1. **Reducción de carga**: El maestro se libera de consultas constantes
2. **Mejor rendimiento**: El esclavo responde directamente las consultas
3. **Escalabilidad**: Fácil agregar más servidores esclavos

### Para la Redundancia
1. **Continuidad**: Si el maestro falla, el esclavo mantiene el servicio
2. **Sincronización automática**: Las zonas se actualizan automáticamente
3. **Consistencia**: Misma información en ambos servidores

### Para la Seguridad
1. **Separación de roles**: Maestro para administración, esclavo para consultas
2. **Acceso controlado**: Solo el firewall puede consultar
3. **Transferencias unidireccionales**: Solo recibe, no propaga

## Interacción con la Arquitectura

### Con el Firewall (192.168.50.12)
- Recibe **TODAS** las consultas DNS redirigidas
- Es el **único punto de consulta** para clientes externos
- Mantiene la arquitectura centralizada

### Con el Maestro (192.168.50.10)
- Recibe **transferencias de zona** automáticas del maestro
- **Realiza consultas recursivas** al maestro cuando no puede resolver localmente
- Mantiene copias actualizadas de todas las zonas
- **Flujo bidireccional**: Recibe zonas Y consulta para resolución

## Proceso de Sincronización

1. **Transferencia inicial**: Al configurar, descarga todas las zonas
2. **Notificaciones**: El maestro notifica cambios automáticamente
3. **Transferencias incrementales**: Solo descarga cambios nuevos
4. **Verificación periódica**: Comprueba consistencia regularmente

## Beneficios de esta Arquitectura

### Rendimiento
- Las consultas se responden localmente desde el esclavo
- El maestro se dedica a administración y FTP
- Distribución eficiente de la carga

### Confiabilidad
- Redundancia automática para DNS
- Continuidad del servicio ante fallos
- Recuperación transparente

### Mantenimiento
- Actualizaciones centralizadas en el maestro
- Propagación automática a esclavos
- Administración simplificada

## Monitoreo Recomendado

- Verificar transferencias de zona exitosas
- Monitorear consultas DNS respondidas
- Comprobar sincronización con el maestro
- Revisar logs de BIND regularmente