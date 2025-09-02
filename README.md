# 🚀 Proyecto de Servicios Telemáticos - Configuración Completa

## 📋 Descripción del Proyecto
Implementación de tres servicios telemáticos esenciales: autenticación PAM en Apache, DNS maestro-esclavo, y tunneling reverso con Ngrok.

---

## 🌐 Configuración de Red
| Servidor | IP Address | Hostname | Función |
|----------|------------|----------|---------|
| **Maestro** | `192.168.50.3` | `maestro.empresa.local` | Servidor Principal |
| **Esclavo** | `192.168.50.4` | `esclavo.empresa.local` | Servidor Secundario |
| **Cliente** | `192.168.50.5` | `cliente.empresa.local` | Máquina de Pruebas |

---

## 🛠️ Parte 1: Autenticación PAM en Apache

### 📁 Estructura de Archivos
```
/etc/apache2/
├── sites-available/000-default.conf
├── usuarios_denegados.txt
└── pam.d/apache

/var/www/html/
├── archivos_privados/index.html
└── error_401.html
```

### 🔧 Configuración Principal
**Archivo:** `/etc/apache2/sites-available/000-default.conf`
```apache
<Directory "/var/www/html/archivos_privados">
    AuthType Basic
    AuthName "Acceso Restringido - Autenticación PAM"
    AuthBasicProvider external
    AuthExternal pwauth
    Require valid-user
    ErrorDocument 401 "/error_401.html"
    
    <RequireAll>
        Require all granted
        Require not user usuario1
        Require not user usuario2
        Require not user usuario_prohibido
        Require not user test_user
    </RequireAll>
</Directory>
```

### 👥 Usuarios de Prueba
**Permitidos:**
- `usuario_permitido` - Contraseña: `password123`

**Denegados:**
- `usuario1`, `usuario2`, `usuario_prohibido`, `test_user`

### 🧪 Comandos de Prueba
```bash
# Usuario permitido (debe funcionar)
curl -u usuario_permitido:password123 http://192.168.50.3/archivos_privados/

# Usuario denegado (debe fallar)
curl -u usuario1:password123 http://192.168.50.3/archivos_privados/

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

**En Esclavo (192.168.50.4):**
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
esclavo         IN      A       192.168.50.4
www             IN      A       192.168.50.100
servidor        IN      A       192.168.50.101
web             IN      CNAME   www
ftp             IN      CNAME   servidor
```

**Zona Inversa:** `db.192`
```bind
3       IN      PTR     maestro.empresa.local.
4       IN      PTR     esclavo.empresa.local.
100     IN      PTR     www.empresa.local.
101     IN      PTR     servidor.empresa.local.
```

### 🧪 Comandos de Prueba
```bash
# Desde el Cliente (192.168.50.5)
nslookup www.empresa.local 192.168.50.4
nslookup 192.168.50.100 192.168.50.4

# Probar resiliencia (apagar maestro)
ssh maestro@192.168.50.3 "sudo systemctl stop bind9"
nslookup www.empresa.local 192.168.50.4  # Debe seguir funcionando
```

---

## 🌐 Parte 3: Tunneling con Ngrok

### 📁 Estructura de Archivos
```
/var/www/html/
├── index.html
└── pagina_personalizada.html
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

# Obtener URL pública
curl -s http://localhost:4040/api/tunnels | jq -r '.tunnels[0].public_url'
```

### 🧪 Comandos de Prueba
```bash
# Verificar servidor local
curl http://192.168.50.3/pagina_personalizada.html

# Verificar through Ngrok (reemplazar con URL real)
curl https://abcd1234.ngrok.io/pagina_personalizada.html

# Monitoreo
curl http://localhost:4040/api/tunnels | jq
```

---

## 🚀 Scripts de Verificación

### 📜 Script para Parte 1 - Apache PAM
```bash
#!/bin/bash
echo "=== VERIFICACIÓN APACHE PAM ==="
curl -u usuario_permitido:password123 -s -o /dev/null -w "Código: %{http_code}" http://192.168.50.3/archivos_privados/
echo ""
curl -u usuario1:password123 -s -o /dev/null -w "Código: %{http_code}" http://192.168.50.3/archivos_privados/
echo ""
```

### 📜 Script para Parte 2 - DNS
```bash
#!/bin/bash
echo "=== VERIFICACIÓN DNS ==="
nslookup www.empresa.local 192.168.50.4
nslookup 192.168.50.100 192.168.50.4
```

### 📜 Script para Parte 3 - Ngrok
```bash
#!/bin/bash
echo "=== VERIFICACIÓN NGROK ==="
NGROK_URL=$(curl -s http://localhost:4040/api/tunnels | jq -r '.tunnels[0].public_url')
echo "URL Pública: $NGROK_URL"
curl -s $NGROK_URL/pagina_personalizada.html | grep -o "<title>.*</title>"
```

---

## 🔧 Troubleshooting Común

### ❌ Problema: Error PAM
**Solución:**
```bash
# Verificar archivo PAM
sudo nano /etc/pam.d/apache
# Debe contener solo:
# auth    required        pam_unix.so
# account required        pam_unix.so
```

### ❌ Problema: DNS no resuelve
**Solución:**
```bash
# Verificar transferencia de zona
sudo rndc retransfer empresa.local
sudo systemctl restart bind9
```

### ❌ Problema: Ngrok no funciona
**Solución:**
```bash
# Verificar procesos
ps aux | grep ngrok
pkill ngrok
ngrok http 80
```

---

## 📊 Evidencias de Configuración Exitosa

### ✅ Para Apache PAM
- [ ] Captura de diálogo de autenticación
- [ ] Logs de acceso exitoso/denegado
- [ ] Configuración de archivos PAM

### ✅ Para DNS
- [ ] Salida de `nslookup` exitosa
- [ ] Archivos de zona en maestro y esclavo
- [ ] Prueba de resiliencia (maestro apagado)

### ✅ Para Ngrok
- [ ] URL pública de Ngrok funcionando
- [ ] Acceso desde dispositivo externo
- [ ] Página personalizada visible

---

## 🎯 Comandos Finales de Verificación

```bash
# Verificar TODO el sistema
ssh cliente@192.168.50.5 "nslookup www.empresa.local 192.168.50.4"
ssh cliente@192.168.50.5 "curl -u usuario_permitido:password123 http://192.168.50.3/archivos_privados/"

# Verificar Ngrok desde externo
curl https://[NGROK_URL]/pagina_personalizada.html
```

---

## 📞 Soporte y Referencias

### 📚 Documentación Oficial
- [Apache Authentication](https://httpd.apache.org/docs/2.4/howto/auth.html)
- [BIND9 Documentation](https://bind9.readthedocs.io/)
- [Ngrok Documentation](https://ngrok.com/docs)

### 🔗 URLs de Monitoréo
- **Ngrok Interface:** http://localhost:4040
- **Apache Status:** http://192.168.50.3/server-status
- **DNS Queries:** Usar `dig` o `nslookup`

---

## ✅ Checklist de Finalización

- [ ] Apache con autenticación PAM funcionando
- [ ] DNS maestro-esclavo configurado y replicando
- [ ] Ngrok exponiendo servidor web local
- [ ] Todas las pruebas exitosas desde el cliente
- [ ] Documentación completa y evidencias capturadas

**¡Configuración completada exitosamente!** 🎉
