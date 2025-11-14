#!/usr/bin/env python3
import sys
import os

# Agregar el directorio de la aplicación al path
sys.path.insert(0, '/var/www/webapp')

# Importar la aplicación Flask
from web.views import app as application

# Configurar variables de entorno si es necesario
os.environ['FLASK_ENV'] = 'production'
