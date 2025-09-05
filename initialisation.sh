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
# sudo apt-get update
# sudo apt-get install -y python3 python3-pip python3-venv

# Install NVM
echo "Installing NVM..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

set +u
export NVM_DIR="/usr/local/share/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Install Node.js
echo "Installing Node.js..."
echo $NVM_DIR
nvm install --lts
nvm use --lts
set -u

# Setup backend
echo "Setting up backend..."
check_directory "$BACKEND_DIR"
cd "$BACKEND_DIR" || exit 1
python3 -m venv .venv
.venv/bin/pip install --upgrade pip && .venv/bin/pip install Django django-cors-headers djangorestframework djangorestframework-simplejwt python-decouple && .venv/bin/django-admin startproject config .
.venv/bin/pip freeze > requirements.txt # Create requirements.txt

# Create Django api and users apps
echo "Creating Django apps..."
mkdir -p apps
touch apps/__init__.py
.venv/bin/python manage.py startapp api apps/api
.venv/bin/python manage.py startapp users apps/users

# Create .env file with environment variables
echo "Creating .env file..."
touch .env
.venv/bin/python -c "from django.core.management.utils import get_random_secret_key; print(f'SECRET_KEY={get_random_secret_key()}')" > .env
echo "DEBUG=True" >> .env
echo "ALLOWED_HOSTS=localhost 127.0.0.1 [::1]" >> .env
echo "CORS_ALLOWED_ORIGINS=http://localhost:5173" >> .env

# Create a README file for the backend
cat > README_BACKEND.md << 'EOF'
# Django Backend
This is the backend of the web application built with Django. It includes configurations for CORS, JWT authentication, and environment variable management.
EOF

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

# Add api and users apps to INSTALLED_APPS (before the closing bracket)
sed -i "/INSTALLED_APPS = \[/,/\]/ {
    /\]/i\\    'apps.api',
    /\]/i\\    'apps.users',
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
rm .gitignore || true # Remove existing .gitignore if any to avoid conflicts

npm create vite@latest ./ -- --template react -y
npm install axios react-dom react-toastify
npm install eslint eslint-plugin-react eslint-plugin-react-hooks prettier --save-dev
npx eslint --init # Follow prompts to set up ESLint
touch .env
echo "VITE_API_URL=http://localhost:8000/api" >> .env
# Create a basic axios instance file
mkdir -p src/api
cat > src/api/axiosInstance.js << 'EOF'
import axios from 'axios';
const api = axios.create({
    baseURL: import.meta.env.VITE_API_URL,
});
export default api;
EOF

# Return to project root
cd "$PROJECT_DIR" || exit 1

# Replace the README file with a template README file
echo "Creating README.md..."
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