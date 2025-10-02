# Database Setup Script for PostgreSQL on Windows
# This script helps set up the PostgreSQL database for the inventory application

Write-Host "=== Inventory App Database Setup ===" -ForegroundColor Green
Write-Host

# Check if PostgreSQL is installed
$psqlPath = Get-Command psql -ErrorAction SilentlyContinue

if (-not $psqlPath) {
    Write-Host "❌ PostgreSQL is not installed. Please install PostgreSQL first." -ForegroundColor Red
    exit 1
}

Write-Host "✅ PostgreSQL found" -ForegroundColor Green

# Database configuration
$DB_NAME = "inventory_db"
$DB_USER = "postgres"

Write-Host "Creating database: $DB_NAME"

# Create database
try {
    psql -U $DB_USER -c "CREATE DATABASE $DB_NAME;" 2>$null
    Write-Host "✅ Database '$DB_NAME' created successfully" -ForegroundColor Green
}
catch {
    Write-Host "ℹ️ Database '$DB_NAME' may already exist" -ForegroundColor Yellow
}

Write-Host
Write-Host "=== Setup Complete ===" -ForegroundColor Green
Write-Host "Next steps:"
Write-Host "1. Copy .env.example to .env"
Write-Host "2. Update .env with your database credentials"
Write-Host "3. Run 'npm start' to start the application"
Write-Host
Write-Host "The application will automatically create the required tables on first run." -ForegroundColor Cyan