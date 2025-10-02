# Guía de Despliegue en AWS

Esta guía detalla las diferentes opciones para desplegar la aplicación Inventory Management System en AWS.

## 📋 Prerrequisitos

- Cuenta de AWS activa
- AWS CLI instalado y configurado
- Node.js y npm instalados localmente
- PostgreSQL (para desarrollo local)

## 🔧 Preparación de la Aplicación

Antes de cualquier despliegue, asegúrate de que la aplicación esté lista:

1. **Variables de entorno configuradas**
2. **Base de datos PostgreSQL lista**
3. **Puerto configurado en 80**
4. **Dependencias actualizadas**

## 1. 🖥️ Despliegue Manual en EC2

### Opción A: Configuración Manual Completa

#### Paso 1: Crear instancia EC2

1. **Acceder a la Consola AWS**
   - Ir a EC2 Dashboard
   - Click en "Launch Instance"

2. **Configurar la instancia**
   - **Name:** inventory-app-server
   - **AMI:** Amazon Linux 2023 (recomendado)
   - **Instance Type:** t2.micro (capa gratuita)
   - **Key Pair:** Crear o seleccionar un key pair existente
   - **Security Group:** Configurar los siguientes puertos:
     - SSH (22) - Tu IP
     - HTTP (80) - 0.0.0.0/0
     - PostgreSQL (5432) - Solo VPC (si usas RDS)

3. **Launch Instance**

#### Paso 2: Conectar a la instancia

```bash
# Conectar vía SSH
ssh -i "tu-key.pem" ec2-user@tu-ip-publica
```

#### Paso 3: Instalar dependencias

```bash
# Actualizar el sistema
sudo dnf update -y

# Instalar Node.js
curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
sudo dnf install -y nodejs

# Instalar PostgreSQL client
sudo dnf install -y postgresql15

# Instalar Git
sudo dnf install -y git

# Verificar instalaciones
node --version
npm --version
```

#### Paso 4: Configurar PostgreSQL

Opción 1 - PostgreSQL local:
```bash
# Instalar PostgreSQL server
sudo dnf install -y postgresql15-server

# Inicializar base de datos
sudo postgresql-setup --initdb

# Iniciar servicio
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Configurar usuario
sudo -u postgres createuser --interactive
sudo -u postgres createdb inventory_db
```

Opción 2 - Amazon RDS (recomendado para producción):
- Crear instancia RDS PostgreSQL desde la consola
- Configurar security groups para permitir conexión desde EC2

#### Paso 5: Desplegar la aplicación

```bash
# Clonar repositorio
git clone https://github.com/tu-usuario/inventory-ing-de-sw.git
cd inventory-ing-de-sw

# Instalar dependencias
npm install

# Configurar variables de entorno
cp .env.example .env
nano .env

# Contenido del .env:
PORT=80
DB_HOST=localhost  # o tu RDS endpoint
DB_PORT=5432
DB_NAME=inventory_db
DB_USER=tu_usuario
DB_PASSWORD=tu_password
```

#### Paso 6: Ejecutar la aplicación

```bash
# Instalar PM2 para gestión de procesos
sudo npm install -g pm2

# Iniciar aplicación
pm2 start server.js --name inventory-app

# Configurar PM2 para iniciar en boot
pm2 startup
pm2 save
```

### Opción B: Con User Data (Semi-automatizado)

Al crear la instancia EC2, agregar este script en "User Data":

```bash
#!/bin/bash
yum update -y

# Instalar Node.js
curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
yum install -y nodejs git

# Crear usuario para la aplicación
useradd -m appuser

# Cambiar a directorio de usuario
cd /home/appuser

# Clonar repositorio
git clone https://github.com/tu-usuario/inventory-ing-de-sw.git
cd inventory-ing-de-sw

# Instalar dependencias
npm install

# Configurar variables de entorno
cat > .env << EOF
PORT=80
DB_HOST=tu-rds-endpoint
DB_NAME=inventory_db
DB_USER=tu_usuario
DB_PASSWORD=tu_password
EOF

# Instalar PM2
npm install -g pm2

# Cambiar permisos
chown -R appuser:appuser /home/appuser/inventory-ing-de-sw

# Iniciar aplicación como appuser
sudo -u appuser pm2 start server.js --name inventory-app

# Configurar PM2 startup
sudo -u appuser pm2 startup systemd -u appuser --hp /home/appuser
sudo -u appuser pm2 save
```

## 2. 💻 Despliegue con AWS CLI

### Paso 1: Configurar AWS CLI

```bash
# Instalar AWS CLI (si no está instalado)
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Configurar credenciales
aws configure
```

### Paso 2: Script de despliegue automatizado

Crear archivo `deploy-ec2.sh`:

```bash
#!/bin/bash

# Variables de configuración
KEY_NAME="inventory-app-key"
SECURITY_GROUP="inventory-app-sg"
INSTANCE_TYPE="t2.micro"
AMI_ID="ami-0abcdef1234567890"  # Amazon Linux 2023 AMI ID para tu región

echo "=== Desplegando aplicación en EC2 con AWS CLI ==="

# Crear Key Pair si no existe
aws ec2 create-key-pair --key-name $KEY_NAME --query 'KeyMaterial' --output text > $KEY_NAME.pem
chmod 400 $KEY_NAME.pem

# Crear Security Group
SG_ID=$(aws ec2 create-security-group \
    --group-name $SECURITY_GROUP \
    --description "Security group for inventory app" \
    --query 'GroupId' --output text)

# Configurar reglas de Security Group
aws ec2 authorize-security-group-ingress \
    --group-id $SG_ID \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0

aws ec2 authorize-security-group-ingress \
    --group-id $SG_ID \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0

# User Data script
USER_DATA=$(base64 -w 0 << 'EOF'
#!/bin/bash
yum update -y
curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
yum install -y nodejs git
useradd -m appuser
cd /home/appuser
git clone https://github.com/tu-usuario/inventory-ing-de-sw.git
cd inventory-ing-de-sw
npm install
npm install -g pm2
chown -R appuser:appuser /home/appuser/inventory-ing-de-sw
sudo -u appuser pm2 start server.js --name inventory-app
EOF
)

# Lanzar instancia
INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --count 1 \
    --instance-type $INSTANCE_TYPE \
    --key-name $KEY_NAME \
    --security-group-ids $SG_ID \
    --user-data $USER_DATA \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=inventory-app}]' \
    --query 'Instances[0].InstanceId' \
    --output text)

echo "Instancia creada: $INSTANCE_ID"

# Esperar a que la instancia esté running
aws ec2 wait instance-running --instance-ids $INSTANCE_ID

# Obtener IP pública
PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text)

echo "=== Despliegue completado ==="
echo "IP Pública: $PUBLIC_IP"
echo "URL de la aplicación: http://$PUBLIC_IP"
echo "SSH: ssh -i $KEY_NAME.pem ec2-user@$PUBLIC_IP"
```

### Paso 3: Ejecutar el script

```bash
chmod +x deploy-ec2.sh
./deploy-ec2.sh
```

## 3. ☁️ Despliegue con Elastic Beanstalk

### Paso 1: Preparar la aplicación para Beanstalk

Crear archivo `.ebextensions/01-nodejs.config`:

```yaml
option_settings:
  aws:elasticbeanstalk:container:nodejs:
    NodeCommand: "npm start"
    NodeVersion: 18.17.0
  aws:elasticbeanstalk:application:environment:
    PORT: 80
    NODE_ENV: production
```

Crear archivo `.ebextensions/02-database.config`:

```yaml
option_settings:
  aws:elasticbeanstalk:application:environment:
    DB_HOST: !GetAtt MyRDSInstance.Endpoint.Address
    DB_NAME: inventory_db
    DB_USER: postgres
    DB_PASSWORD: !Ref MyDBPassword

Resources:
  MyRDSInstance:
    Type: AWS::RDS::DBInstance
    Properties:
      DBInstanceClass: db.t3.micro
      Engine: postgres
      EngineVersion: 15.4
      AllocatedStorage: 20
      DBName: inventory_db
      MasterUsername: postgres
      MasterUserPassword: !Ref MyDBPassword
      
  MyDBPassword:
    Type: AWS::SSM::Parameter::Value<String>
    Default: /inventory-app/db-password
    NoEcho: true
```

### Paso 2: Crear archivo .ebignore

```
.git/
.env
node_modules/
*.log
.DS_Store
```

### Paso 3: Instalar EB CLI

```bash
pip install awsebcli
```

### Paso 4: Inicializar y desplegar

```bash
# Inicializar aplicación Elastic Beanstalk
eb init

# Seleccionar:
# - Región: us-east-1 (o tu región preferida)
# - Aplicación: inventory-app
# - Plataforma: Node.js
# - Version: Node.js 18

# Crear entorno
eb create inventory-app-prod

# Configurar variables de entorno
eb setenv DB_HOST=tu-rds-endpoint DB_NAME=inventory_db DB_USER=postgres DB_PASSWORD=tu-password

# Desplegar
eb deploy

# Abrir aplicación en el navegador
eb open
```

### Ventajas de Elastic Beanstalk vs EC2

| Característica | EC2 Manual | Elastic Beanstalk |
|---------------|------------|-------------------|
| **Configuración** | Manual completa | Automatizada |
| **Escalado** | Manual | Automático |
| **Monitoreo** | Configuración manual | Integrado |
| **Updates** | Manuales | Rolling updates |
| **Load Balancing** | Configuración manual | Automático |
| **SSL/TLS** | Configuración manual | Un click |
| **Logs** | Acceso manual | Centralizados |
| **Costo** | Solo EC2 + RDS | Sin costo adicional |
| **Control** | Total | Limitado |
| **Complejidad** | Alta | Baja |

## 🔍 Verificación del Despliegue

Para cualquier método de despliegue, verificar:

### 1. Health Check
```bash
curl http://tu-url/api/health
```

### 2. Endpoints de la API
```bash
# Obtener productos
curl http://tu-url/api/products

# Estadísticas
curl http://tu-url/api/stats
```

### 3. Logs
```bash
# EC2
ssh -i tu-key.pem ec2-user@ip-publica
pm2 logs inventory-app

# Elastic Beanstalk
eb logs
```

## 🚨 Troubleshooting

### Problemas Comunes

1. **Puerto 80 requiere permisos root**
   ```bash
   # Usar puerto 3000 y redirigir con nginx
   sudo yum install nginx
   # Configurar reverse proxy
   ```

2. **Conexión a base de datos falla**
   - Verificar security groups
   - Verificar variables de entorno
   - Verificar credenciales

3. **Aplicación no inicia**
   - Verificar logs: `pm2 logs`
   - Verificar dependencias: `npm install`

4. **Performance issues**
   - Configurar instance type más grande
   - Implementar Redis para cache
   - Optimizar queries de base de datos

## 📊 Monitoreo y Mantenimiento

### CloudWatch
- Configurar alarmas para CPU, memoria, disk
- Monitorear logs de aplicación
- Configurar SNS para notificaciones

### Backup
- RDS automated backups
- Snapshots regulares de la instancia EC2

### Updates
- Usar Blue/Green deployment para Beanstalk
- Para EC2, usar AMI custom con aplicación pre-instalada

## 💰 Optimización de Costos

1. **Reserved Instances** para cargas de trabajo predecibles
2. **Spot Instances** para development/testing
3. **Auto Scaling** para optimizar uso de recursos
4. **CloudWatch** para monitorear uso y costos