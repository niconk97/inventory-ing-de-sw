#!/bin/bash

# Database Setup Script for PostgreSQL
# This script helps set up the PostgreSQL database for the inventory application

echo "=== Inventory App Database Setup ==="
echo

# Check if PostgreSQL is installed
if ! command -v psql &> /dev/null; then
    echo "❌ PostgreSQL is not installed. Please install PostgreSQL first."
    exit 1
fi

echo "✅ PostgreSQL found"

# Database configuration
DB_NAME="inventory_db"
DB_USER="postgres"

echo "Creating database: $DB_NAME"

# Create database
psql -U $DB_USER -c "CREATE DATABASE $DB_NAME;" 2>/dev/null

if [ $? -eq 0 ]; then
    echo "✅ Database '$DB_NAME' created successfully"
else
    echo "ℹ️ Database '$DB_NAME' may already exist"
fi

echo
echo "=== Setup Complete ==="
echo "Next steps:"
echo "1. Copy .env.example to .env"
echo "2. Update .env with your database credentials"
echo "3. Run 'npm start' to start the application"
echo
echo "The application will automatically create the required tables on first run."