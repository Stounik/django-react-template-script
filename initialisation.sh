#!/bin/bash

# Script to initialize the development environment for a web application with a Django backend and a React frontend.

# Exit immediately if a command exits with a non-zero status, if an undefined variable is used, or if any command in a pipeline fails
set -euo pipefail

# Define project paths
PROJECT_DIR=$(pwd)
BACKEND_DIR="$PROJECT_DIR/backend"
FRONTEND_DIR="$PROJECT_DIR/frontend"

# Function to check if a directory exists
check_directory() {
    if [ ! -d "$1" ]; then
        echo "Error: Directory $1 does not exist."
        exit 1
    fi
}

# Install necessary packages
echo "Installing necessary packages..."
sudo apt-get update
sudo apt-get install -y python3 python3-pip python3-venv

# Install NVM
echo "Installing NVM..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
export NVM_DIR="/usr/local/share/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Install Node.js
echo "Installing Node.js..."
echo $NVM_DIR
nvm install --lts
nvm use --lts

# Setup backend
echo "Setting up backend..."
check_directory "$BACKEND_DIR"
cd "$BACKEND_DIR" || exit 1
python3 -m venv .venv
.venv/bin/pip install --upgrade pip && .venv/bin/pip install Django django-cors-headers djangorestframework djangorestframework-simplejwt python-decouple && .venv/bin/django-admin startproject config .
touch .env
.venv/bin/python -c "from django.core.management.utils import get_random_secret_key; print(f'SECRET_KEY={get_random_secret_key()}')" > .env
echo "DEBUG=True" >> .env
echo "ALLOWED_HOSTS=localhost 127.0.0.1 [::1]" >> .env
echo "CORS_ALLOWED_ORIGINS=http://localhost:5173" >> .env

# Modify settings.py using sed and other command-line tools
echo "Configuring Django settings.py..."
SETTINGS_FILE="config/settings.py"

# Add imports after the pathlib import
sed -i '/from pathlib import Path/a\\nfrom decouple import config\nimport os' "$SETTINGS_FILE"

# Replace SECRET_KEY with decouple version
sed -i "s/SECRET_KEY = .*/SECRET_KEY = config('SECRET_KEY')/" "$SETTINGS_FILE"

# Replace DEBUG with decouple version
sed -i "s/DEBUG = .*/DEBUG = config('DEBUG', default=False, cast=bool)/" "$SETTINGS_FILE"

# Replace ALLOWED_HOSTS with decouple version
sed -i "s/ALLOWED_HOSTS = .*/ALLOWED_HOSTS = config('ALLOWED_HOSTS', default='').split()/" "$SETTINGS_FILE"

# Add corsheaders and rest_framework to INSTALLED_APPS (before the closing bracket)
sed -i "/INSTALLED_APPS = \[/,/\]/ {
    /\]/i\\    'corsheaders',
    /\]/i\\    'rest_framework',
}" "$SETTINGS_FILE"

# Add corsheaders middleware at the beginning of MIDDLEWARE list
sed -i "/MIDDLEWARE = \[/a\\    'corsheaders.middleware.CorsMiddleware'," "$SETTINGS_FILE"

# Append CORS and REST framework configuration at the end of the file
cat >> "$SETTINGS_FILE" << 'EOF'

# CORS settings
CORS_ALLOWED_ORIGINS = config('CORS_ALLOWED_ORIGINS', default='').split()

# REST Framework configuration
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework_simplejwt.authentication.JWTAuthentication',
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.IsAuthenticated',
    ],
}

# Simple JWT configuration
from datetime import timedelta
SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(minutes=60),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=7),
    'ROTATE_REFRESH_TOKENS': True,
}
EOF

# Setup frontend
echo "Setting up frontend..."
check_directory "$FRONTEND_DIR"
cd "$FRONTEND_DIR" || exit 1
npm create vite@latest ./ -- --template react -y
npm install axios react-dom
npm install eslint eslint-plugin-react eslint-plugin-react-hooks --save-dev
npx eslint --init
touch .env
echo "VITE_API_URL=http://localhost:8000/api" >> .env

echo "Setup complete!"
