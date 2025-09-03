# Initialisation script for Django and React template

# Install necessary packages
echo "Installing necessary packages..."
sudo apt-get update
sudo apt-get install -y python3 python3-pip python3-venv

echo "Installing NVM..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

echo "Installing Node.js..."
nvm install --lts
nvm use --lts

echo "Setting up backend..."
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
django-admin startproject config .

cd ..

echo "Setting up frontend..."
cd frontend
npm create vite@latest . -- --template react
npm install