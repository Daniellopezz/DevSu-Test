## Descripción del Proyecto

Este repositorio contiene la implementación completa de un pipeline CI/CD para una aplicación Python (Django) con despliegue automatizado en Azure Kubernetes Service (AKS). Toda la infraestructura necesaria se ha creado utilizando Terraform como herramienta de IaC.

### Endpoint publico para acceder a la aplicacion desplegada: 

http://132.196.136.64 

### Url del repo: 



### Diagrama de la Infraestructura
Link con el diagrama de la infraestructura desplegada en Azure : 

https://www.mermaidchart.com/app/projects/b583d151-50cf-4812-baab-c68900de0273/diagrams/925e6a7d-5626-44a8-a9b8-cdd0c115b8b5/version/v0.1/edit


### Componentes principales

Azure Resource Group: Contiene todos los recursos
Virtual Network: Red virtual con subredes separadas para AKS y Application Gateway
Azure Kubernetes Service: Cluster AKS con autoscaling configurado
Application Gateway: Gestiona el tráfico de entrada y sirve como punto de acceso público
Container Registry: Almacena las imágenes Docker de la aplicación

### Estructura de la carpeta Terraform que es donde estan los archivos utilizados para el despliegue de la infraestructura descrita anteriormente 

terraform/
├── main.tf                # Archivo principal
├── variables.tf           # Definición de variables
├── outputs.tf             # Valores de salida
├── backend.tf             # Configuración del backend
├── version.tf             # Versiones de proveedores

Main.tf: Este es el archivo principal que define los recursos principales
Variables.tf: Contiene todas las variables configurables para tu infraestructura
Outputs.tf: Define los valores de salida que se mostrarán después de aplicar la configuración
Backend.tf: Este archivo configura dónde se almacena el estado de Terraform
Version.tf: Define las versiones de Terraform y los proveedores necesarios

### Despliegue de la Infraestructura
Para desplegar la infraestructura:

Clonar este repositorio
Navegar al directorio terraform: cd terraform
Inicializar Terraform: terraform init
Validar la configuración: terraform validate
Crear un plan: terraform plan -out=tfplan
Aplicar el plan: terraform apply tfplan

### Resultados del Despliegue con terraform

Los resultados del despliegue de la infraestructura estan en el zip adjunto llamado evidencias. Dentro hay una carpeta llamada logs terraform. Ahi se puede ver el output en txt del plan y del apply 

### Kubernetes

En esta carpeta se encuentran los archivos yml necesarios para construir la logica en AKS para desplegar la aplicacion. Su estructura es la siguiente: 

kubernetes/
├── Api_Health.py        # Script Python: health-checker que puedes usar en readiness/liveness o cron de monitoreo
├── configmap.yaml       # ConfigMap con parámetros no sensibles 
├── deployment.yaml      # Deployment de la app (imagen, réplicas, probes, recursos)
├── hpa.yaml             # HorizontalPodAutoscaler: escala el Deployment según CPU/Mem u otras métricas
├── ingress.yaml         # Ingress: reglas HTTP/S y TLS que exponen el Service al exterior
├── secret.yaml          # Secret con datos sensibles (passwords, tokens) 
└── services.yaml        # Service(s) que dan IP estable y load-balancing a los Pods


### CI/CD

El pipeline de CI/CD está implementado en GitHub Actions y consta de las siguientes etapas:

Test: Ejecución de pruebas unitarias
Build: Construcción de la imagen Docker
Deploy: Despliegue en AKS

### Configuración Inicial Del Pipeline
El pipeline se activa en dos eventos principales:

Push a las ramas main, master o develop
Pull Requests dirigidas a estas mismas ramas

Se definen permisos específicos:

Lectura del contenido del repositorio
Escritura para tokens de identidad (necesario para autenticación en Azure)
Acceso de escritura a paquetes (para el registro de contenedores)

Variables de entorno globales:

Registro Docker: GitHub Container Registry (ghcr.io)
Nombre de la imagen: daniellopezz/devsu-test
Configuración del clúster AKS: nombre, grupo de recursos y namespace

### Job 1: Test (Pruebas y Análisis de Código)
Este job configura un entorno para ejecutar pruebas y análisis de calidad de código:

1. Configuración del entorno Python:

Checkout del código fuente
Configuración de Python 3.9
Instalación de dependencias desde requirements.txt
Instalación de herramientas de prueba y análisis (pytest, flake8, bandit)

2. Análisis estático de código con Flake8:

Verificación de errores críticos de sintaxis
Análisis completo de calidad de código (complejidad y longitud de líneas)

3. Análisis de seguridad con Bandit:

Escaneo del código en busca de vulnerabilidades de seguridad
Generación de informe en formato JSON

4. Ejecución de pruebas unitarias:

Configura variables de entorno para las pruebas
Ejecuta las pruebas con cobertura de código
Genera informe XML de cobertura

5. Publicación del informe de cobertura:

Sube los resultados a Codecov para análisis detallado


### Job 2: Build and Push (Construcción y Publicación de la Imagen)

Este job se ejecuta solo si las pruebas fueron exitosas

1. Verificación de estructura del proyecto:

Comprueba la existencia del Dockerfile

2. Configuración de Docker Buildx:

Prepara el entorno para construir la imagen Docker

3. Autenticación en Container Registry:

Usa las credenciales del contexto para acceder al registro

4. Generación de etiquetas para la imagen:

Crea una etiqueta basada en el SHA corto del commit
Define también la etiqueta "latest"

5. Construcción y publicación de la imagen:

Construye la imagen con Buildx
Implementa caché para optimizar builds futuros
Añade metadatos y etiquetas
Publica la imagen en Container Registry

6. Verificación de la imagen publicada:

Descarga la imagen para confirmar que existe en el registro

7. Análisis de vulnerabilidades con Trivy:

Escanea la imagen Docker en busca de vulnerabilidades
Genera informe en formato SARIF
Filtra por severidades CRITICAL y HIGH

8. Publicación de resultados de seguridad:

Sube los resultados al panel de seguridad de GitHub

### Job 3: Deploy (Despliegue en Kubernetes)

Este job se ejecuta después de la construcción de la imagen 

1. Preparación para el despliegue:

Obtiene el código fuente actualizado
Configura la etiqueta de imagen consistente con el job anterior

2. Configuración de herramientas de Kubernetes:

Instala y configura kubectl

3. Autenticación en Azure:

Inicia sesión en Azure usando credenciales almacenadas en secrets

4. Configuración del contexto de AKS:

Obtiene las credenciales para acceder al clúster AKS

5. Creación del namespace:

Crea el namespace si no existe 

6. Verificación de manifiestos Kubernetes:

Comprueba la existencia del directorio kubernetes/
Lista los manifiestos disponibles

7. Aplicación de manifiestos Kubernetes:

Sustituye variables en los manifiestos (imagen, registro, etc.)
Aplica todos los manifiestos al namespace
Muestra los recursos creados o actualizados

8. Verificación del despliegue:

Monitorea el estado del rollout del deployment
En caso de problemas, recopila logs y eventos para diagnóstico
Muestra el estado final del despliegue

9. Obtención de detalles del servicio:

Muestra información de los servicios desplegados
Verifica la existencia y configuración de Ingress
Intenta obtener la URL de acceso
Proporciona un resumen general del despliegue


### Este pipeline implementa prácticas modernas de DevOps:

Integración continua con pruebas automatizadas
Análisis de calidad y seguridad del código
Construcción y publicación de imágenes Docker
Despliegue continuo en Kubernetes
Verificación post-despliegue para asegurar disponibilidad
Gestión de secretos y credenciales de forma segura

### Adjunto un zip llamado evidencias. Dentro de este se encuentra las evidencias de los jobs corridos dentro del pipeline. Imagenes de los jobs success y los artefactos generados por el pipeline donde se ve el output de cada proceso. Tambien estan archivos txt con el output del terraform plan y el terraform apply

### Recomendaciones si fueramos a llevar esta aplicacion a un ambiente productivo: 

1. Versionado de terraform en un repo aparte 

2. Terraform en modulos para la gestion mas eficiente del Iac con terraform. Esto nos permitira gestionar mejor nuestra infra. A medida que pasa el tiempo, nuestros archivos de terraform iran creciendo conforme va creciendo la empresa. La administracion en modulos nos permite gestionar estos archivos de manera organizada y sencilla 

3. Versionado de los archivos de kubernetes en un repo aparte

3. Despliegue de un Iac para kubernetes. Dentro de mi experiencia, uno que no falla es ArgoCD. Lo que nos permite esta herramienta es desplegar nuestra infraestructura en nuestro cluster de manera automatica a traves de los manifestos. Cuando un yml es modificado, ArgoCD lo detecta y hace Sync (puede ser de manera automatica) actualizando el ambiente correspondiente

4. Despliegue de un stack de monitoreo para darle seguimiento a la aplicacion 

5. Implementar un manejo seguro de secretos: Azure Key Vault es una buena opcion 

6. Configuracion RBAC para establecer los roles y permisos en Azure para limitar el acceso solo a lo necesario 

7. Implementacion de WAF y DDos. Una herramienta que en mi experiencia a funcionado de maravilla es Azure Application Gateway con WAF

8. Utiliza múltiples zonas de disponibilidad 

