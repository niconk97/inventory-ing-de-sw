# Script de verificación del proyecto
# Verifica que todos los archivos necesarios estén presentes y configurados correctamente

Write-Host "=== Verificación del Proyecto Inventory Management System ===" -ForegroundColor Green
Write-Host

$ProjectPath = "d:\UADE\Ing. de Sw\inventory-ing-de-sw"
$ErrorCount = 0

# Función para verificar archivos
function Test-FileExists {
    param([string]$FilePath, [string]$Description)
    
    if (Test-Path $FilePath) {
        Write-Host "✅ $Description" -ForegroundColor Green
        return $true
    } else {
        Write-Host "❌ $Description - FALTANTE" -ForegroundColor Red
        return $false
    }
}

# Verificar archivos principales
Write-Host "📁 Verificando archivos principales..." -ForegroundColor Yellow
$files = @(
    @{Path = "$ProjectPath\package.json"; Desc = "package.json"},
    @{Path = "$ProjectPath\server.js"; Desc = "server.js"},
    @{Path = "$ProjectPath\README.md"; Desc = "README.md"},
    @{Path = "$ProjectPath\.gitignore"; Desc = ".gitignore"},
    @{Path = "$ProjectPath\.env.example"; Desc = ".env.example"}
)

foreach ($file in $files) {
    if (-not (Test-FileExists $file.Path $file.Desc)) {
        $ErrorCount++
    }
}

# Verificar directorio public
Write-Host "`n📁 Verificando archivos del frontend..." -ForegroundColor Yellow
$publicFiles = @(
    @{Path = "$ProjectPath\public\index.html"; Desc = "index.html"},
    @{Path = "$ProjectPath\public\app.js"; Desc = "app.js"},
    @{Path = "$ProjectPath\public\manifest.json"; Desc = "manifest.json"},
    @{Path = "$ProjectPath\public\sw.js"; Desc = "sw.js"}
)

foreach ($file in $publicFiles) {
    if (-not (Test-FileExists $file.Path $file.Desc)) {
        $ErrorCount++
    }
}

# Verificar archivos de despliegue
Write-Host "`n📁 Verificando archivos de despliegue..." -ForegroundColor Yellow
$deployFiles = @(
    @{Path = "$ProjectPath\AWS-DEPLOYMENT-GUIDE.md"; Desc = "AWS-DEPLOYMENT-GUIDE.md"},
    @{Path = "$ProjectPath\.ebextensions\01-nodejs.config"; Desc = "Elastic Beanstalk config"},
    @{Path = "$ProjectPath\.ebignore"; Desc = ".ebignore"},
    @{Path = "$ProjectPath\deployment-scripts\deploy-ec2.sh"; Desc = "Script EC2 (bash)"},
    @{Path = "$ProjectPath\deployment-scripts\deploy-ec2.ps1"; Desc = "Script EC2 (PowerShell)"},
    @{Path = "$ProjectPath\deployment-scripts\deploy-beanstalk.sh"; Desc = "Script Beanstalk"}
)

foreach ($file in $deployFiles) {
    if (-not (Test-FileExists $file.Path $file.Desc)) {
        $ErrorCount++
    }
}

# Verificar contenido del package.json
Write-Host "`n🔍 Verificando configuración del package.json..." -ForegroundColor Yellow
if (Test-Path "$ProjectPath\package.json") {
    $packageJson = Get-Content "$ProjectPath\package.json" | ConvertFrom-Json
    
    # Verificar dependencias
    if ($packageJson.dependencies.pg) {
        Write-Host "✅ PostgreSQL dependency configurada" -ForegroundColor Green
    } else {
        Write-Host "❌ PostgreSQL dependency FALTANTE" -ForegroundColor Red
        $ErrorCount++
    }
    
    if ($packageJson.dependencies.dotenv) {
        Write-Host "✅ dotenv dependency configurada" -ForegroundColor Green
    } else {
        Write-Host "❌ dotenv dependency FALTANTE" -ForegroundColor Red
        $ErrorCount++
    }
    
    if (-not $packageJson.dependencies.sqlite3) {
        Write-Host "✅ SQLite removido correctamente" -ForegroundColor Green
    } else {
        Write-Host "⚠️ SQLite aún presente en dependencies" -ForegroundColor Yellow
    }
}

# Verificar contenido del server.js
Write-Host "`n🔍 Verificando configuración del server.js..." -ForegroundColor Yellow
if (Test-Path "$ProjectPath\server.js") {
    $serverContent = Get-Content "$ProjectPath\server.js" -Raw
    
    if ($serverContent -match "Pool.*=.*require.*pg") {
        Write-Host "✅ PostgreSQL Pool configurado" -ForegroundColor Green
    } else {
        Write-Host "❌ PostgreSQL Pool NO configurado" -ForegroundColor Red
        $ErrorCount++
    }
    
    if ($serverContent -match "PORT.*=.*process\.env\.PORT.*80") {
        Write-Host "✅ Puerto 80 configurado" -ForegroundColor Green
    } else {
        Write-Host "❌ Puerto 80 NO configurado" -ForegroundColor Red
        $ErrorCount++
    }
    
    if ($serverContent -match "require.*dotenv.*config") {
        Write-Host "✅ dotenv configurado" -ForegroundColor Green
    } else {
        Write-Host "❌ dotenv NO configurado" -ForegroundColor Red
        $ErrorCount++
    }
}

# Verificar si node_modules existe
Write-Host "`n📦 Verificando instalación de dependencias..." -ForegroundColor Yellow
if (Test-Path "$ProjectPath\node_modules") {
    Write-Host "✅ node_modules existe" -ForegroundColor Green
    
    # Verificar dependencias específicas
    if (Test-Path "$ProjectPath\node_modules\pg") {
        Write-Host "✅ PostgreSQL instalado" -ForegroundColor Green
    } else {
        Write-Host "❌ PostgreSQL NO instalado" -ForegroundColor Red
        $ErrorCount++
    }
    
    if (Test-Path "$ProjectPath\node_modules\dotenv") {
        Write-Host "✅ dotenv instalado" -ForegroundColor Green
    } else {
        Write-Host "❌ dotenv NO instalado" -ForegroundColor Red
        $ErrorCount++
    }
} else {
    Write-Host "❌ node_modules NO existe - Ejecutar 'npm install'" -ForegroundColor Red
    $ErrorCount++
}

# Resumen final
Write-Host "`n" + "="*60 -ForegroundColor Cyan
if ($ErrorCount -eq 0) {
    Write-Host "🎉 VERIFICACIÓN EXITOSA" -ForegroundColor Green
    Write-Host "El proyecto está correctamente configurado y listo para despliegue." -ForegroundColor Green
    Write-Host
    Write-Host "📋 Próximos pasos:" -ForegroundColor Yellow
    Write-Host "1. Configurar variables de entorno (.env)"
    Write-Host "2. Configurar base de datos PostgreSQL"
    Write-Host "3. Elegir método de despliegue (EC2, Beanstalk, etc.)"
    Write-Host "4. Ejecutar script de despliegue correspondiente"
} else {
    Write-Host "⚠️ VERIFICACIÓN CON ERRORES" -ForegroundColor Red
    Write-Host "Se encontraron $ErrorCount errores que deben corregirse." -ForegroundColor Red
    Write-Host
    Write-Host "📋 Acciones recomendadas:" -ForegroundColor Yellow
    Write-Host "1. Revisar los archivos marcados como faltantes"
    Write-Host "2. Ejecutar 'npm install' si es necesario"
    Write-Host "3. Verificar configuración de base de datos"
    Write-Host "4. Re-ejecutar este script para verificar"
}
Write-Host "="*60 -ForegroundColor Cyan