FROM python:3.9-slim

LABEL org.opencontainers.image.source="https://github.com/daniellopezz/devsu-test"
LABEL maintainer="Daniel Lopez <daniellopezz@example.com>"
LABEL description="DevSu Test Django Application"

# Variables de entorno
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=8000 \
    ALLOWED_HOSTS=*,10.0.1.36,localhost,0.0.0.0

# Crear y establecer el directorio de trabajo
WORKDIR /app

# Instalar dependencias del sistema
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    libpq-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copiar requirements e instalar dependencias de Python
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copiar manage.py y verificar su existencia
COPY manage.py .
RUN python -c "import sys; sys.exit(0 if __import__('os').path.exists('manage.py') else 1)" || \
    (echo 'El archivo manage.py no existe' && exit 1)

# Copiar código fuente del proyecto
COPY api/ api/
COPY demo/ demo/
COPY .env .

# Crear middleware para health check
RUN mkdir -p api/middleware && \
    echo 'from django.http import HttpResponse\n\nclass HealthCheckMiddleware:\n    def __init__(self, get_response):\n        self.get_response = get_response\n\n    def __call__(self, request):\n        if request.path == "/health/":\n            return HttpResponse("OK")\n        return self.get_response(request)' > api/middleware/__init__.py

# Añadir middleware a settings.py
RUN echo '\n# Health check middleware\nMIDDLEWARE.append("api.middleware.HealthCheckMiddleware")' >> demo/settings.py

# Configurar ALLOWED_HOSTS en settings.py si no está usando la variable de entorno
RUN echo "\n# Allow all hosts by default\nimport os\nALLOWED_HOSTS = os.environ.get('ALLOWED_HOSTS', 'localhost').split(',')" >> demo/settings.py

# Crear usuario no privilegiado y otorgar permisos al directorio antes de cambiar de usuario
RUN adduser --disabled-password --gecos "" appuser && \
    mkdir -p /app && chown -R appuser:appuser /app
USER appuser

# Exponer el puerto de la aplicación
EXPOSE $PORT

# Healthcheck
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:$PORT/health/ || exit 1

# Comando por defecto: aplicar migraciones y correr el servidor
CMD ["sh", "-c", "python manage.py migrate --noinput && python manage.py runserver 0.0.0.0:$PORT"]