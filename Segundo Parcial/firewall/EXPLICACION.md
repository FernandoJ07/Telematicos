# Configuración del Firewall - Explicación Detallada

## Función del Firewall

El firewall actúa como **gateway** y **punto de control de acceso** para toda la red interna. Su función principal es:

1. **Filtrar tráfico entrante y saliente**
2. **Redirigir servicios** hacia los servidores correspondientes
3. **Proporcionar NAT/MASQUERADE** para la comunicación bidireccional

## Configuración NAT (before.rules)

### Tablas NAT
```bash
*nat
:PREROUTING ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
```
- **PREROUTING**: Procesa paquetes antes del enrutamiento
- **POSTROUTING**: Procesa paquetes después del enrutamiento

### Redirección FTP
```bash
-A PREROUTING -p tcp --dport 21 -j DNAT --to-destination 192.168.50.10:21
-A PREROUTING -p tcp --dport 40000:40010 -j DNAT --to-destination 192.168.50.10
```
- **Puerto 21**: Control FTP hacia el maestro
- **Puertos 40000:40010**: Rango de datos FTP pasivo hacia el maestro

### Redirección DNS
```bash
-A PREROUTING -p udp --dport 53 -j DNAT --to-destination 192.168.50.11:53
-A PREROUTING -p tcp --dport 53 -j DNAT --to-destination 192.168.50.11:53
```
- Todas las consultas DNS se redirigen al **servidor esclavo**
- Soporta tanto UDP como TCP (requerido por RFC)

### Redirección HTTP/HTTPS
```bash
-A PREROUTING -p tcp --dport 80 -j DNAT --to-destination 192.168.50.10:80
-A PREROUTING -p tcp --dport 443 -j DNAT --to-destination 192.168.50.10:443
```
- Tráfico web se redirige al **servidor maestro**

### MASQUERADE
```bash
-A POSTROUTING -s 192.168.50.0/24 -d 192.168.50.11 -j MASQUERADE
-A POSTROUTING -j MASQUERADE
```
- **Primera regla**: MASQUERADE específico para tráfico hacia el esclavo DNS
- **Segunda regla**: MASQUERADE general para todo el tráfico saliente

## Configuración UFW

### Políticas por Defecto
- **INPUT**: DROP (todo denegado por defecto)
- **OUTPUT**: ACCEPT (salida permitida)
- **FORWARD**: ACCEPT (reenvío permitido para NAT)

### Puertos Permitidos
| Puerto | Protocolo | Servicio | Justificación |
|--------|-----------|----------|---------------|
| 22 | TCP | SSH | Administración remota |
| 21 | TCP | FTP Control | Acceso al servidor FTP |
| 40000:40010 | TCP | FTP Datos | Rango pasivo FTP |
| 53 | TCP/UDP | DNS | Resolución de nombres |
| 80 | TCP | HTTP | Acceso web |
| 443 | TCP | HTTPS | Acceso web seguro |

## Flujo de Paquetes

### Entrada de Tráfico
1. Paquete llega al firewall
2. Se aplican reglas PREROUTING (NAT)
3. Se consultan reglas UFW (filtrado)
4. Si es permitido, se reenvía al servidor destino

### Salida de Tráfico
1. Respuesta del servidor interno
2. Se aplican reglas POSTROUTING (MASQUERADE)
3. Paquete sale con IP del firewall como origen

## Seguridad Implementada

### Defensa en Profundidad
- **Filtrado por puerto**: Solo puertos necesarios abiertos
- **NAT**: Oculta la estructura interna de la red
- **MASQUERADE**: Mantiene estado de conexiones

### Separación de Servicios
- **DNS**: Delegado al servidor esclavo especializado
- **FTP/HTTP**: Concentrado en el servidor maestro
- **Firewall**: Solo funciones de red y seguridad

## Ventajas de esta Configuración

1. **Punto único de entrada**: Facilita auditoría y control
2. **Redundancia DNS**: El esclavo puede seguir funcionando independientemente
3. **Escalabilidad**: Fácil agregar más servidores internos
4. **Monitoreo centralizado**: Todo el tráfico pasa por el firewall