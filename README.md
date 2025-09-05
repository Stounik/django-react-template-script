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
