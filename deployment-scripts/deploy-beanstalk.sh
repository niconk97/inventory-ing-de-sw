#!/bin/bash

# Script de despliegue en AWS Elastic Beanstalk
# Autor: Consultora de Software

set -e

# Variables de configuración
APP_NAME="inventory-management-app"
ENV_NAME="inventory-app-prod"
PLATFORM="Node.js 18"
REGION="us-east-1"

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}=== Desplegando aplicación en AWS Elastic Beanstalk ===${NC}"
echo

# Verificar que EB CLI está instalado
if ! command -v eb &> /dev/null; then
    echo -e "${RED}❌ EB CLI no está instalado${NC}"
    echo "Instalar con: pip install awsebcli"
    exit 1
fi

echo -e "${GREEN}✅ EB CLI encontrado${NC}"

# Verificar que estamos en el directorio correcto
if [ ! -f "package.json" ]; then
    echo -e "${RED}❌ No se encontró package.json. Ejecutar desde el directorio raíz del proyecto.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Directorio del proyecto verificado${NC}"

# Verificar archivos necesarios para Beanstalk
if [ ! -d ".ebextensions" ]; then
    echo -e "${YELLOW}⚠️ Directorio .ebextensions no encontrado. Creando...${NC}"
    mkdir -p .ebextensions
fi

# Inicializar aplicación Elastic Beanstalk si no existe
if [ ! -d ".elasticbeanstalk" ]; then
    echo "🚀 Inicializando aplicación Elastic Beanstalk..."
    
    # Crear configuración EB
    mkdir -p .elasticbeanstalk
    cat > .elasticbeanstalk/config.yml << EOF
branch-defaults:
  main:
    environment: $ENV_NAME
    group_suffix: null
global:
  application_name: $APP_NAME
  branch: null
  default_ec2_keyname: null
  default_platform: Node.js 18 running on 64bit Amazon Linux 2
  default_region: $REGION
  include_git_submodules: true
  instance_profile: null
  platform_name: null
  platform_version: null
  profile: default
  repository: null
  sc: git
  workspace_type: Application
EOF

    echo -e "${GREEN}✅ Aplicación Beanstalk inicializada${NC}"
else
    echo -e "${YELLOW}⚠️ Aplicación Beanstalk ya existe${NC}"
fi

# Crear archivo de versión
VERSION=$(date +%Y%m%d_%H%M%S)
echo $VERSION > .ebextensions/version.txt

# Verificar variables de entorno necesarias
echo "🔧 Configurando variables de entorno..."

# Lista de variables de entorno a configurar
ENV_VARS="PORT=80 NODE_ENV=production"

# Si tienes variables específicas de base de datos, agregarlas aquí
read -p "¿Tienes un endpoint de RDS configurado? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    read -p "Ingresa el endpoint de RDS: " RDS_ENDPOINT
    read -p "Ingresa el nombre de la base de datos: " DB_NAME
    read -p "Ingresa el usuario de la base de datos: " DB_USER
    read -s -p "Ingresa la contraseña de la base de datos: " DB_PASSWORD
    echo
    
    ENV_VARS="$ENV_VARS DB_HOST=$RDS_ENDPOINT DB_NAME=$DB_NAME DB_USER=$DB_USER DB_PASSWORD=$DB_PASSWORD"
fi

# Crear aplicación si no existe
echo "📦 Verificando aplicación Beanstalk..."
if ! aws elasticbeanstalk describe-applications --application-names $APP_NAME --region $REGION > /dev/null 2>&1; then
    echo "Creando aplicación $APP_NAME..."
    aws elasticbeanstalk create-application \
        --application-name $APP_NAME \
        --description "Inventory Management System - Node.js Application" \
        --region $REGION
fi

# Crear entorno si no existe
echo "🌍 Verificando entorno..."
if ! aws elasticbeanstalk describe-environments --environment-names $ENV_NAME --region $REGION > /dev/null 2>&1; then
    echo "Creando entorno $ENV_NAME..."
    eb create $ENV_NAME \
        --platform "Node.js 18 running on 64bit Amazon Linux 2" \
        --instance-type t3.micro \
        --keyname inventory-app-key
else
    echo -e "${YELLOW}⚠️ Entorno $ENV_NAME ya existe${NC}"
fi

# Configurar variables de entorno
if [ ! -z "$ENV_VARS" ]; then
    echo "⚙️ Configurando variables de entorno..."
    eb setenv $ENV_VARS
fi

# Crear archivo de deployment package
echo "📦 Preparando paquete de despliegue..."

# Verificar que .ebignore existe
if [ ! -f ".ebignore" ]; then
    cat > .ebignore << EOF
.git/
.env
node_modules/
*.log
.DS_Store
.vscode/
*.pem
*.tmp
*.temp
coverage/
.nyc_output
deployment-scripts/
EOF
fi

# Desplegar aplicación
echo "🚀 Desplegando aplicación..."
eb deploy $ENV_NAME

# Obtener URL de la aplicación
APP_URL=$(eb status $ENV_NAME | grep "CNAME" | awk '{print $2}')

echo
echo -e "${GREEN}=== 🎉 Despliegue completado exitosamente ===${NC}"
echo
echo -e "${YELLOW}📋 Información de la aplicación:${NC}"
echo "  • Aplicación: $APP_NAME"
echo "  • Entorno: $ENV_NAME"
echo "  • URL: http://$APP_URL"
echo "  • Región: $REGION"
echo
echo -e "${YELLOW}🔧 Comandos útiles:${NC}"
echo "  • Ver logs: eb logs $ENV_NAME"
echo "  • Ver estado: eb status $ENV_NAME"
echo "  • Abrir en navegador: eb open $ENV_NAME"
echo "  • Configurar variables: eb setenv KEY=VALUE"
echo "  • Terminar entorno: eb terminate $ENV_NAME"
echo
echo -e "${YELLOW}📝 Próximos pasos:${NC}"
echo "  1. Verificar que la aplicación funcione: http://$APP_URL/api/health"
echo "  2. Configurar base de datos RDS si no lo has hecho"
echo "  3. Configurar dominio personalizado si es necesario"
echo "  4. Configurar SSL/TLS certificate"
echo "  5. Configurar monitoreo y alarmas"

# Verificar health check
echo
echo "🔍 Verificando health check..."
sleep 30  # Esperar a que la aplicación esté lista

if curl -f "http://$APP_URL/api/health" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Health check exitoso${NC}"
else
    echo -e "${YELLOW}⚠️ Health check falló. Revisa los logs con: eb logs $ENV_NAME${NC}"
fi