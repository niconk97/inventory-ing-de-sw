#!/bin/bash

# Script de despliegue automatizado en EC2 usando AWS CLI
# Autor: Consultora de Software
# Fecha: $(date)

set -e  # Exit on any error

# Variables de configuración
KEY_NAME="inventory-app-key"
SECURITY_GROUP="inventory-app-sg"
INSTANCE_TYPE="t2.micro"
# Actualizar con el AMI ID de tu región
AMI_ID="ami-0abcdef1234567890"  # Amazon Linux 2023 para us-east-1
REGION="us-east-1"
APP_NAME="inventory-management-app"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Desplegando aplicación Inventory Management en EC2 ===${NC}"
echo

# Verificar que AWS CLI está configurado
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo -e "${RED}❌ AWS CLI no está configurado correctamente${NC}"
    echo "Ejecuta: aws configure"
    exit 1
fi

echo -e "${GREEN}✅ AWS CLI configurado${NC}"

# Obtener VPC por defecto
DEFAULT_VPC=$(aws ec2 describe-vpcs --filters "Name=is-default,Values=true" --query 'Vpcs[0].VpcId' --output text --region $REGION)

if [ "$DEFAULT_VPC" = "None" ]; then
    echo -e "${RED}❌ No se encontró VPC por defecto${NC}"
    exit 1
fi

echo -e "${GREEN}✅ VPC por defecto encontrada: $DEFAULT_VPC${NC}"

# Crear Key Pair si no existe
echo "🔑 Creando Key Pair..."
if aws ec2 describe-key-pairs --key-names $KEY_NAME --region $REGION > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠️ Key pair '$KEY_NAME' ya existe${NC}"
else
    aws ec2 create-key-pair --key-name $KEY_NAME --query 'KeyMaterial' --output text --region $REGION > $KEY_NAME.pem
    chmod 400 $KEY_NAME.pem
    echo -e "${GREEN}✅ Key pair creado: $KEY_NAME.pem${NC}"
fi

# Crear Security Group si no existe
echo "🛡️ Configurando Security Group..."
SG_ID=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=$SECURITY_GROUP" --query 'SecurityGroups[0].GroupId' --output text --region $REGION 2>/dev/null)

if [ "$SG_ID" = "None" ] || [ -z "$SG_ID" ]; then
    SG_ID=$(aws ec2 create-security-group \
        --group-name $SECURITY_GROUP \
        --description "Security group for inventory app" \
        --vpc-id $DEFAULT_VPC \
        --query 'GroupId' --output text --region $REGION)
    
    # Configurar reglas de Security Group
    aws ec2 authorize-security-group-ingress \
        --group-id $SG_ID \
        --protocol tcp \
        --port 22 \
        --cidr 0.0.0.0/0 \
        --region $REGION
    
    aws ec2 authorize-security-group-ingress \
        --group-id $SG_ID \
        --protocol tcp \
        --port 80 \
        --cidr 0.0.0.0/0 \
        --region $REGION
    
    echo -e "${GREEN}✅ Security group creado: $SG_ID${NC}"
else
    echo -e "${YELLOW}⚠️ Security group '$SECURITY_GROUP' ya existe: $SG_ID${NC}"
fi

# Crear User Data script
echo "📝 Preparando User Data script..."
cat > user-data.sh << 'EOF'
#!/bin/bash
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

# Actualizar sistema
dnf update -y

# Instalar Node.js 18
curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
dnf install -y nodejs git

# Instalar PostgreSQL client
dnf install -y postgresql15

# Crear usuario para la aplicación
useradd -m appuser

# Cambiar a directorio de usuario
cd /home/appuser

# Clonar repositorio (actualizar con tu URL)
git clone https://github.com/tu-usuario/inventory-ing-de-sw.git
cd inventory-ing-de-sw

# Instalar dependencias
npm install

# Crear archivo de configuración
cat > .env << EOL
PORT=80
NODE_ENV=production
DB_HOST=localhost
DB_NAME=inventory_db
DB_USER=postgres
DB_PASSWORD=changeme123
EOL

# Instalar PM2 globalmente
npm install -g pm2

# Cambiar permisos
chown -R appuser:appuser /home/appuser/inventory-ing-de-sw

# Configurar PostgreSQL local (opcional, mejor usar RDS en producción)
dnf install -y postgresql15-server
postgresql-setup --initdb
systemctl start postgresql
systemctl enable postgresql

# Crear base de datos
sudo -u postgres createdb inventory_db

# Iniciar aplicación como appuser
sudo -u appuser bash -c 'cd /home/appuser/inventory-ing-de-sw && pm2 start server.js --name inventory-app'

# Configurar PM2 para iniciar en boot
sudo -u appuser pm2 startup systemd -u appuser --hp /home/appuser
sudo -u appuser pm2 save

echo "=== Instalación completada ===" >> /var/log/user-data.log
EOF

# Lanzar instancia
echo "🚀 Lanzando instancia EC2..."
INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --count 1 \
    --instance-type $INSTANCE_TYPE \
    --key-name $KEY_NAME \
    --security-group-ids $SG_ID \
    --user-data file://user-data.sh \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$APP_NAME},{Key=Project,Value=inventory-app}]" \
    --query 'Instances[0].InstanceId' \
    --output text \
    --region $REGION)

echo -e "${GREEN}✅ Instancia creada: $INSTANCE_ID${NC}"

# Esperar a que la instancia esté running
echo "⏳ Esperando a que la instancia esté running..."
aws ec2 wait instance-running --instance-ids $INSTANCE_ID --region $REGION

# Obtener IP pública
PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text \
    --region $REGION)

# Limpiar archivos temporales
rm -f user-data.sh

echo
echo -e "${GREEN}=== 🎉 Despliegue completado exitosamente ===${NC}"
echo
echo -e "${YELLOW}📋 Información de la instancia:${NC}"
echo "  • Instance ID: $INSTANCE_ID"
echo "  • IP Pública: $PUBLIC_IP"
echo "  • URL de la aplicación: http://$PUBLIC_IP"
echo "  • SSH: ssh -i $KEY_NAME.pem ec2-user@$PUBLIC_IP"
echo
echo -e "${YELLOW}⏳ Nota: La aplicación puede tardar algunos minutos en estar disponible${NC}"
echo "   mientras se completa la instalación automática."
echo
echo -e "${YELLOW}🔧 Para verificar el estado de la instalación:${NC}"
echo "   ssh -i $KEY_NAME.pem ec2-user@$PUBLIC_IP"
echo "   sudo tail -f /var/log/user-data.log"
echo
echo -e "${YELLOW}📝 Para conectar a la base de datos desde la aplicación:${NC}"
echo "   Actualiza las variables de entorno en la instancia EC2"
echo "   o usa Amazon RDS para una base de datos gestionada."