# Initialisation script for Django and React template

# Install necessary packages
sudo apt-get update
sudo apt-get install -y python3 python3-pip python3-venv
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

nvm install --lts
nvm use --lts

cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
django-admin startproject config .

cd ..
cd frontend
npm create vite@latest . -- --template react
npm install