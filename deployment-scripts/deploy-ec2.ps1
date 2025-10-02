# Script de despliegue automatizado en EC2 usando AWS CLI - PowerShell
# Autor: Consultora de Software

param(
    [string]$Region = "us-east-1",
    [string]$InstanceType = "t2.micro",
    [string]$KeyName = "inventory-app-key",
    [string]$SecurityGroup = "inventory-app-sg",
    [string]$AmiId = "ami-0abcdef1234567890"  # Actualizar con AMI de tu región
)

$ErrorActionPreference = "Stop"

Write-Host "=== Desplegando aplicación Inventory Management en EC2 ===" -ForegroundColor Green
Write-Host

# Verificar que AWS CLI está configurado
try {
    $null = aws sts get-caller-identity 2>$null
    Write-Host "✅ AWS CLI configurado" -ForegroundColor Green
}
catch {
    Write-Host "❌ AWS CLI no está configurado correctamente" -ForegroundColor Red
    Write-Host "Ejecuta: aws configure"
    exit 1
}

# Obtener VPC por defecto
try {
    $DefaultVpc = aws ec2 describe-vpcs --filters "Name=is-default,Values=true" --query 'Vpcs[0].VpcId' --output text --region $Region
    if ($DefaultVpc -eq "None") {
        throw "No VPC found"
    }
    Write-Host "✅ VPC por defecto encontrada: $DefaultVpc" -ForegroundColor Green
}
catch {
    Write-Host "❌ No se encontró VPC por defecto" -ForegroundColor Red
    exit 1
}

# Crear Key Pair si no existe
Write-Host "🔑 Creando Key Pair..."
try {
    $null = aws ec2 describe-key-pairs --key-names $KeyName --region $Region 2>$null
    Write-Host "⚠️ Key pair '$KeyName' ya existe" -ForegroundColor Yellow
}
catch {
    aws ec2 create-key-pair --key-name $KeyName --query 'KeyMaterial' --output text --region $Region | Out-File -FilePath "$KeyName.pem" -Encoding ascii
    Write-Host "✅ Key pair creado: $KeyName.pem" -ForegroundColor Green
}

# Crear Security Group si no existe
Write-Host "🛡️ Configurando Security Group..."
try {
    $SgId = aws ec2 describe-security-groups --filters "Name=group-name,Values=$SecurityGroup" --query 'SecurityGroups[0].GroupId' --output text --region $Region 2>$null
    if ($SgId -eq "None" -or [string]::IsNullOrEmpty($SgId)) {
        throw "Security group not found"
    }
    Write-Host "⚠️ Security group '$SecurityGroup' ya existe: $SgId" -ForegroundColor Yellow
}
catch {
    $SgId = aws ec2 create-security-group --group-name $SecurityGroup --description "Security group for inventory app" --vpc-id $DefaultVpc --query 'GroupId' --output text --region $Region
    
    # Configurar reglas de Security Group
    aws ec2 authorize-security-group-ingress --group-id $SgId --protocol tcp --port 22 --cidr 0.0.0.0/0 --region $Region
    aws ec2 authorize-security-group-ingress --group-id $SgId --protocol tcp --port 80 --cidr 0.0.0.0/0 --region $Region
    
    Write-Host "✅ Security group creado: $SgId" -ForegroundColor Green
}

# Crear User Data script
Write-Host "📝 Preparando User Data script..."
$UserDataScript = @'
#!/bin/bash
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

# Actualizar sistema
dnf update -y

# Instalar Node.js 18
curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
dnf install -y nodejs git postgresql15

# Crear usuario para la aplicación
useradd -m appuser

# Cambiar a directorio de usuario
cd /home/appuser

# Clonar repositorio
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

# Instalar PM2
npm install -g pm2

# Cambiar permisos
chown -R appuser:appuser /home/appuser/inventory-ing-de-sw

# Configurar PostgreSQL local
dnf install -y postgresql15-server
postgresql-setup --initdb
systemctl start postgresql
systemctl enable postgresql
sudo -u postgres createdb inventory_db

# Iniciar aplicación
sudo -u appuser bash -c 'cd /home/appuser/inventory-ing-de-sw && pm2 start server.js --name inventory-app'
sudo -u appuser pm2 startup systemd -u appuser --hp /home/appuser
sudo -u appuser pm2 save

echo "=== Instalación completada ===" >> /var/log/user-data.log
'@

$UserDataScript | Out-File -FilePath "user-data.sh" -Encoding utf8

# Lanzar instancia
Write-Host "🚀 Lanzando instancia EC2..."
$InstanceId = aws ec2 run-instances `
    --image-id $AmiId `
    --count 1 `
    --instance-type $InstanceType `
    --key-name $KeyName `
    --security-group-ids $SgId `
    --user-data file://user-data.sh `
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=inventory-management-app},{Key=Project,Value=inventory-app}]" `
    --query 'Instances[0].InstanceId' `
    --output text `
    --region $Region

Write-Host "✅ Instancia creada: $InstanceId" -ForegroundColor Green

# Esperar a que la instancia esté running
Write-Host "⏳ Esperando a que la instancia esté running..."
aws ec2 wait instance-running --instance-ids $InstanceId --region $Region

# Obtener IP pública
$PublicIp = aws ec2 describe-instances --instance-ids $InstanceId --query 'Reservations[0].Instances[0].PublicIpAddress' --output text --region $Region

# Limpiar archivos temporales
Remove-Item "user-data.sh" -Force

Write-Host
Write-Host "=== 🎉 Despliegue completado exitosamente ===" -ForegroundColor Green
Write-Host
Write-Host "📋 Información de la instancia:" -ForegroundColor Yellow
Write-Host "  • Instance ID: $InstanceId"
Write-Host "  • IP Pública: $PublicIp"
Write-Host "  • URL de la aplicación: http://$PublicIp"
Write-Host "  • SSH: ssh -i $KeyName.pem ec2-user@$PublicIp"
Write-Host
Write-Host "⏳ Nota: La aplicación puede tardar algunos minutos en estar disponible" -ForegroundColor Yellow
Write-Host "   mientras se completa la instalación automática."
Write-Host