#!/bin/bash

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
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Install Node.js
echo "Installing Node.js..."
nvm install --lts
nvm use --lts

# Setup backend
echo "Setting up backend..."
check_directory "$BACKEND_DIR"
cd "$BACKEND_DIR" || exit 1
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
django-admin startproject config .

# Setup frontend
echo "Setting up frontend..."
check_directory "$FRONTEND_DIR"
cd "$FRONTEND_DIR" || exit 1
npm create vite@latest . -- --template react
npm install

echo "Setup complete!"
