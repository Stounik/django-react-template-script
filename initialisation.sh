#!/bin/bash

# Script to initialize the development environment for a web application with a Django backend and a React frontend.

# Exit immediately if a command exits with a non-zero status, if an undefined variable is used, or if any command in a pipeline fails
set -euo pipefail

mkdir -p backend
mkdir -p frontend

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

set +u
# Detect NVM installation directory
if [ -z "${NVM_DIR:-}" ]; then
    if [ -d "$HOME/.nvm" ]; then
        export NVM_DIR="$HOME/.nvm"
    elif [ -d "/usr/local/nvm" ]; then
        export NVM_DIR="/usr/local/nvm"
    elif [ -d "/opt/nvm" ]; then
        export NVM_DIR="/opt/nvm"
    else
        # Try to find nvm directory
        NVM_FOUND=$(find /home /usr/local /opt -name "nvm" -type d 2>/dev/null | head -n 1)
        if [ -n "$NVM_FOUND" ] && [ -f "$NVM_FOUND/nvm.sh" ]; then
            export NVM_DIR="$NVM_FOUND"
        else
            echo "Error: Could not locate NVM installation directory"
            exit 1
        fi
    fi
fi

echo "NVM_DIR set to: $NVM_DIR"

set +u
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Install Node.js
echo "Installing Node.js..."
echo $NVM_DIR
nvm install --lts
nvm use --lts
set -u

# Setup backend
echo "==============================="
echo "Setting up backend..."
echo "==============================="
check_directory "$BACKEND_DIR"
cd "$BACKEND_DIR" || exit 1
echo "PWD: $(pwd)"
python3 -m venv .venv
"$BACKEND_DIR"/.venv/bin/pip install --upgrade pip && "$BACKEND_DIR"/.venv/bin/pip install Django django-cors-headers djangorestframework djangorestframework-simplejwt python-decouple && "$BACKEND_DIR"/.venv/bin/django-admin startproject config .
"$BACKEND_DIR"/.venv/bin/pip freeze > requirements.txt # Create requirements.txt

# Create Django api and users apps
echo ""
echo "Creating Django apps..."
mkdir -p apps
check_directory "apps"
cd apps || exit 1
touch __init__.py
"$BACKEND_DIR"/.venv/bin/django-admin startapp api
sed -i 's/name = "api"/name = "apps.api"/' api/apps.py

"$BACKEND_DIR"/.venv/bin/django-admin startapp users
sed -i 's/name = "users"/name = "apps.users"/' users/apps.py
cd "$BACKEND_DIR" || exit 1

# Create .env file with environment variables
echo ""
echo "Creating .env file for backend..."
touch .env
"$BACKEND_DIR"/.venv/bin/python -c "from django.core.management.utils import get_random_secret_key; print(f'SECRET_KEY={get_random_secret_key()}')" > .env
echo "DEBUG=True" >> .env
echo "ALLOWED_HOSTS=localhost 127.0.0.1 [::1]" >> .env
echo "CORS_ALLOWED_ORIGINS=http://localhost:5173" >> .env
echo "DB_ENGINE_DEV=django.db.backends.sqlite3" >> .env
echo "DB_NAME_DEV=db.sqlite3" >> .env
echo "DB_ENGINE=django.db.backends.postgresql" >> .env
echo "DB_NAME=your_db_name" >> .env
echo "DB_USER=your_db_user" >> .env
echo "DB_PASSWORD=your_db_password" >> .env
echo "DB_HOST=localhost" >> .env
echo "DB_PORT=5432" >> .env
echo "SECURE_SSL_REDIRECT=True" >> .env
echo "SECURE_HSTS_SECONDS=31536000" >> .env
echo "SECURE_HSTS_INCLUDE_SUBDOMAINS=True" >> .env
echo "SECURE_HSTS_PRELOAD=True" >> .env
echo "SESSION_COOKIE_SECURE=True" >> .env
echo "CSRF_COOKIE_SECURE=True" >> .env
echo "STATIC_ROOT=staticfiles" >> .env
echo "STATIC_URL=/static/" >> .env
echo "STATICFILES_STORAGE=django.contrib.staticfiles.storage.StaticFilesStorage" >> .env
echo "MEDIA_ROOT=media" >> .env

# Create a README file for the backend
cat > README_BACKEND.md << 'EOF'
# Django Backend
This is the backend of the web application built with Django. It includes configurations for CORS, JWT authentication, and environment variable management.
EOF

# Split settings.py into base, development, and production settings
echo "Splitting settings.py into base, development, and production settings..."
SETTINGS_DIR="config/settings"
mkdir -p "$SETTINGS_DIR"
check_directory "$SETTINGS_DIR"
touch "$SETTINGS_DIR/__init__.py"
mv config/settings.py "$SETTINGS_DIR/base.py"

# Modify settings.py using sed and other command-line tools
echo "Configuring Django settings..."
BASE_SETTINGS_FILE="$SETTINGS_DIR/base.py"
DEV_SETTINGS_FILE="$SETTINGS_DIR/development.py"
PROD_SETTINGS_FILE="$SETTINGS_DIR/production.py"

# Add imports after the pathlib import
sed -i '/from pathlib import Path/a\\nfrom decouple import config\nimport os' "$BASE_SETTINGS_FILE"

# Replace SECRET_KEY with decouple version
sed -i "s/SECRET_KEY = .*/SECRET_KEY = config('SECRET_KEY')/" "$BASE_SETTINGS_FILE"

# Remove DEBUG and ALLOWED_HOSTS from base (will be in environment-specific files)
sed -i '/^DEBUG = /d' "$BASE_SETTINGS_FILE"
sed -i '/^ALLOWED_HOSTS = /d' "$BASE_SETTINGS_FILE"

# Add corsheaders and rest_framework to INSTALLED_APPS (before the closing bracket)
sed -i "/INSTALLED_APPS = \[/,/\]/ {
    /\]/i\\    'corsheaders',
    /\]/i\\    'rest_framework',
}" "$BASE_SETTINGS_FILE"

# Add api and users apps to INSTALLED_APPS (before the closing bracket)
sed -i "/INSTALLED_APPS = \[/,/\]/ {
    /\]/i\\    'apps.api',
    /\]/i\\    'apps.users',
}" "$BASE_SETTINGS_FILE"

# Add corsheaders middleware at the beginning of MIDDLEWARE list
sed -i "/MIDDLEWARE = \[/a\\    'corsheaders.middleware.CorsMiddleware'," "$BASE_SETTINGS_FILE"

# Append base configuration at the end of the base settings file
cat >> "$BASE_SETTINGS_FILE" << 'EOF'

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

# Create development settings file
cat > "$DEV_SETTINGS_FILE" << 'EOF'
from .base import *

# Development-specific settings
DEBUG = config('DEBUG', default=True, cast=bool)

ALLOWED_HOSTS = config('ALLOWED_HOSTS', default='localhost 127.0.0.1 [::1]').split()

# CORS settings for development
CORS_ALLOWED_ORIGINS = config('CORS_ALLOWED_ORIGINS', default='http://localhost:5173').split()

# Development database (SQLite)
DATABASES = {
    'default': {
        'ENGINE': config('DB_ENGINE_DEV', default='django.db.backends.sqlite3'),
        'NAME': BASE_DIR / config('DB_NAME_DEV', default='db.sqlite3'),
    }
}

# Development logging
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'handlers': {
        'console': {
            'class': 'logging.StreamHandler',
        },
    },
    'root': {
        'handlers': ['console'],
        'level': 'INFO',
    },
}
EOF

# Create production settings file
cat > "$PROD_SETTINGS_FILE" << 'EOF'
from .base import *

# Production-specific settings
DEBUG = config('DEBUG', default=False, cast=bool)

ALLOWED_HOSTS = config('ALLOWED_HOSTS', default='').split()

# CORS settings for production
CORS_ALLOWED_ORIGINS = config('CORS_ALLOWED_ORIGINS', default='').split()

# Production database (PostgreSQL recommended)
DATABASES = {
    'default': {
        'ENGINE': config('DB_ENGINE', default='django.db.backends.postgresql'),
        'NAME': config('DB_NAME'),
        'USER': config('DB_USER'),
        'PASSWORD': config('DB_PASSWORD'),
        'HOST': config('DB_HOST', default='localhost'),
        'PORT': config('DB_PORT', default='5432'),
    }
}

# Security settings
SECURE_SSL_REDIRECT = config('SECURE_SSL_REDIRECT', default=True, cast=bool)
SECURE_HSTS_SECONDS = config('SECURE_HSTS_SECONDS', default=31536000, cast=int)
SECURE_HSTS_INCLUDE_SUBDOMAINS = config('SECURE_HSTS_INCLUDE_SUBDOMAINS', default=True, cast=bool)
SECURE_HSTS_PRELOAD = config('SECURE_HSTS_PRELOAD', default=True, cast=bool)
SESSION_COOKIE_SECURE = config('SESSION_COOKIE_SECURE', default=True, cast=bool)
CSRF_COOKIE_SECURE = config('CSRF_COOKIE_SECURE', default=True, cast=bool)

# Static files for production
STATIC_ROOT = BASE_DIR / config('STATIC_ROOT', default='staticfiles')
STATIC_URL = config('STATIC_URL', default='/static/')
STATICFILES_STORAGE = config('STATICFILES_STORAGE_WHITENOISE', default='django.contrib.staticfiles.storage.StaticFilesStorage')

# Media files for production
MEDIA_ROOT = BASE_DIR / config('MEDIA_ROOT', default='media')

# Production logging
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'formatters': {
        'verbose': {
            'format': '{levelname} {asctime} {module} {process:d} {thread:d} {message}',
            'style': '{',
        },
    },
    'handlers': {
        'file': {
            'level': 'INFO',
            'class': 'logging.FileHandler',
            'filename': 'django.log',
            'formatter': 'verbose',
        },
    },
    'root': {
        'handlers': ['file'],
        'level': 'INFO',
    },
}
EOF

# Update manage.py to use development settings by default
sed -i 's/"DJANGO_SETTINGS_MODULE", "config.settings"/"DJANGO_SETTINGS_MODULE", "config.settings.development"/' "${BACKEND_DIR}"/manage.py
# Update wsgi.py to use production settings
sed -i 's/"DJANGO_SETTINGS_MODULE", "config.settings"/"DJANGO_SETTINGS_MODULE", "config.settings.production"/' "${BACKEND_DIR}"/config/wsgi.py
# Update asgi.py to use production settings
sed -i 's/"DJANGO_SETTINGS_MODULE", "config.settings"/"DJANGO_SETTINGS_MODULE", "config.settings.production"/' "${BACKEND_DIR}"/config/asgi.py

# Setup frontend
echo "==============================="
echo "Setting up frontend..."
echo "==============================="
check_directory "$FRONTEND_DIR"
cd "$FRONTEND_DIR" || exit 1
echo "PWD: $(pwd)"

npm create vite@latest ./ -- --template react -y
npm install axios react-dom react-toastify
npm install eslint eslint-plugin-react eslint-plugin-react-hooks prettier --save-dev
npx eslint --init # Follow prompts to set up ESLint

# Create .env file for frontend
echo "Creating .env file for frontend..."
touch .env
echo "VITE_API_DEVELOPMENT_URL=http://localhost:8000/api" >> .env
echo "VITE_API_URL=http://your-production-api-url/api" >> .env

# Create a basic axios instance file
echo "Creating axios instance file for API calls..."
mkdir -p src/api
check_directory "src/api"
cat > src/api/axiosInstance.js << 'EOF'
import axios from 'axios';
const api = axios.create({
    baseURL: import.meta.env.VITE_API_DEVELOPMENT_URL, // Use VITE_API_URL for production
    headers: { 'Content-Type': 'application/json' },
});
export default api;
EOF

# Rename existing FRONTEND README.md if any to avoid conflicts and remove existing FRONTEND .gitignore if any
echo "Renaming existing README.md and removing .gitignore in frontend if they exist..."
mv README.md README_FRONTEND.md || true # Rename existing README.md if any to avoid conflicts
rm .gitignore || true # Remove existing .gitignore if any to avoid conflicts

# Return to project root
echo "Returning to project root..."
cd "$PROJECT_DIR" || exit 1

# Replace the README file with a template README file
echo "Creating project README.md..."
rm README.md || true # Remove existing README.md if any to avoid conflicts
cat > README.md << 'EOF'
# Django-React Template
This is a template project that sets up a web application with a Django backend and a React frontend. The backend is configured with Django REST Framework, CORS headers, JWT authentication, and environment variable management using python-decouple. The frontend is set up with React (using Vite), Axios for API calls, and ESLint for code quality.
## Project Structure
- `backend/`: Contains the Django backend code.
- `frontend/`: Contains the React frontend code.
## Getting Started
### Setup Backend
1. Navigate to the backend directory:
    ```bash
    cd backend
    ```
2. Create and activate a virtual environment:
    ```bash
    python3 -m venv .venv
    source .venv/bin/activate
    ```
3. Install the required Python packages:
    ```bash
    pip install -r requirements.txt
    ```
4. Apply migrations:
    ```bash
    python manage.py migrate
    ```
5. Create a superuser:
    ```bash
    python manage.py createsuperuser
    ```
6. Run the development server:
    ```bash
    python manage.py runserver
    ```
### Setup Frontend
1. Navigate to the frontend directory:
    ```bash
    cd ../frontend
    ```
2. Install the required npm packages:
    ```bash
    npm install
    ```
3. Run the development server:
    ```bash
    npm run dev
    ``` 
### Accessing the Application
- Backend: Open your browser and go to `http://localhost:8000/admin` to access the Django admin panel.
- Frontend: Open your browser and go to `http://localhost:5173` to access the React application.
EOF

# Create .gitignore file for Django and React
echo "Creating .gitignore file..."
cat > .gitignore << 'EOF'
# General
*.env

# Python
__pycache__/
*.pyc
*.pyo
*.pyd
.venv/

# Django
*.sqlite3
/media
/staticfiles

# React
node_modules/
EOF

# Final message
echo ""
echo "Setup complete!"
echo "Backend configured with:"
echo "- Django REST Framework"
echo "- CORS headers"
echo "- JWT authentication"
echo "- python-decouple for environment variables"
echo ""
echo "Frontend configured with:"
echo "- React (Vite)"
echo "- Axios for API calls"
echo "- ESLint for code quality"