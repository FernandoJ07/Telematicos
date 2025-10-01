# Proyecto de Servicios Telemáticos - Configuración Completa

## 📋 Descripción del Proyecto
Implementación de tres servicios telemáticos esenciales: autenticación PAM en Apache, DNS maestro-esclavo, y tunneling reverso con Ngrok.

---

## Configuración de Red
| Servidor | IP Address | Hostname | Función |
|----------|------------|----------|---------|
| **Maestro** | `192.168.50.3` | `maestro.empresa.local` | Servidor Principal |
| **Esclavo** | `192.168.50.2` | `esclavo.empresa.local` | Servidor Secundario |
| **Cliente** | `192.168.50.4` | `cliente.empresa.local` | Máquina de Pruebas |

---

## Parte 1: Autenticación PAM en Apache

### Estructura de Archivos
```
/etc/apache2/
├── sites-available/000-default.conf
├── usuarios_denegados.txt
└── pam.d/apache

/var/www/html/
├── archivos_privados/index.html
└── error_401.html
```

### Configuración Principal
**Archivo:** `/etc/apache2/sites-available/000-default.conf`
```apache
<Directory "/var/www/html/archivos_privados">
        AuthType Basic
        AuthName "Zona Restringida - Autenticación PAM"
        AuthBasicProvider PAM
        AuthPAMService apache2
        Require valid-user

        # Página de error personalizada
        ErrorDocument 401 "/error_401.html"
        ErrorDocument 403 "/error_403.html"
    </Directory>
```

### 👥 Usuarios de Prueba
**Permitidos:**
- `maria` - Contraseña: `maria`

**Denegados:**
- `carlos`

### 🧪 Comandos de Prueba
```bash
# Usuario permitido (debe funcionar)
curl -u maria:maria http://192.168.50.3/archivos_privados/

# Usuario denegado (debe fallar)
curl -u carlos:carlos http://192.168.50.3/archivos_privados/

# Verificar logs
tail -f /var/log/apache2/{access,error}.log
```

---

## 🌐 Parte 2: DNS Maestro-Esclavo Bind9

### 📁 Estructura de Archivos
**En Maestro (192.168.50.3):**
```
/etc/bind/
├── named.conf.local
├── named.conf.options
├── db.empresa.local
└── db.192
```

**En Esclavo (192.168.50.2):**
```
/var/cache/bind/
├── db.empresa.local
└── db.192
```

### 🔧 Configuración DNS
**Zona Directa:** `db.empresa.local`
```bind
@       IN      NS      maestro.empresa.local.
@       IN      NS      esclavo.empresa.local.

maestro         IN      A       192.168.50.3
esclavo         IN      A       192.168.50.2
www             IN      A       192.168.50.100
servidor        IN      A       192.168.50.101
cliente1        IN      A       192.168.50.50
cliente2        IN      A       192.168.50.51
```

**Zona Inversa:** `db.192`
```bind
3       IN      PTR     maestro.empresa.local.
2       IN      PTR     esclavo.empresa.local.
100     IN      PTR     www.empresa.local.
101     IN      PTR     servidor.empresa.local.
50      IN      PTR     cliente1.empresa.local.
51      IN      PTR     cliente2.empresa.local.
```

### 🧪 Comandos de Prueba
```bash
# Desde el Cliente (192.168.50.5)
nslookup www.empresa.local 192.168.50.3
nslookup 192.168.50.100 192.168.50.3

# Probar resiliencia (apagar maestro)
sudo systemctl stop bind9 #En el maestro
nslookup www.empresa.local 192.168.50.2  # Debe seguir funcionando desde cliente
```
---

## 🌐 Parte 3: Tunneling con Ngrok

### 📁 Estructura de Archivos
```
/var/www/html/
├── index.html
```

### 🔧 Configuración Ngrok
**Instalación:**
```bash
wget https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz
tar xvzf ngrok-v3-stable-linux-amd64.tgz
sudo mv ngrok /usr/local/bin/
```

**Ejecución:**
```bash
# Exponer servidor web
ngrok http 80
```
**¡Configuración completada exitosamente!** 🎉
