#!/bin/bash

echo "🚀 ProCreditApp Backend Setup Script"
echo "===================================="
echo ""

# Check Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js >= 18"
    exit 1
fi

echo "✓ Node.js version: $(node -v)"

# Check npm
if ! command -v npm &> /dev/null; then
    echo "❌ npm is not installed."
    exit 1
fi

echo "✓ npm version: $(npm -v)"

# Check if .env file exists
if [ ! -f .env ]; then
    echo ""
    echo "📝 Creating .env file from .env.example..."
    cp .env.example .env
    echo "✓ .env file created. Please update it with your configuration."
else
    echo "✓ .env file already exists"
fi

# Install dependencies
echo ""
echo "📦 Installing dependencies..."
npm install

if [ $? -ne 0 ]; then
    echo "❌ Failed to install dependencies"
    exit 1
fi

echo "✓ Dependencies installed"

# Generate Prisma client
echo ""
echo "🔧 Generating Prisma client..."
npm run prisma:generate 2>/dev/null || npx prisma generate

if [ $? -ne 0 ]; then
    echo "❌ Failed to generate Prisma client"
    exit 1
fi

echo "✓ Prisma client generated"

# Run migrations
echo ""
echo "🗄️  Running database migrations..."
echo "Make sure MySQL is running and DATABASE_URL in .env is correct."
echo ""

read -p "Do you want to run migrations now? (y/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    npm run prisma:migrate
    
    if [ $? -ne 0 ]; then
        echo "⚠️  Failed to run migrations. You can run 'npm run prisma:migrate' later."
    else
        echo "✓ Migrations completed"
        
        # Seed database
        read -p "Do you want to seed the database with sample data? (y/n) " -n 1 -r
        echo ""
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            npm run prisma:seed
            if [ $? -ne 0 ]; then
                echo "⚠️  Failed to seed database"
            else
                echo "✓ Database seeded with sample data"
            fi
        fi
    fi
fi

echo ""
echo "✅ Setup completed!"
echo ""
echo "📋 Next steps:"
echo "1. Edit .env file with your configuration"
echo "2. Start the server: npm run dev"
echo "3. Visit http://localhost:3000/health to check if it's running"
echo ""
echo "📖 Documentation:"
echo "- API Documentation: see API_DOCUMENTATION.md"
echo "- Deployment Guide: see DEPLOYMENT_GUIDE.md"
echo "- Readme: see README.md"
echo ""
