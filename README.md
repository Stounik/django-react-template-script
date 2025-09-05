# Django-React Template
This is a template project that sets up a Django backend with a React frontend. It includes configurations for CORS, JWT authentication, and environment variable management.
## Backend
- Django
- Django REST Framework
- django-cors-headers
- djangorestframework-simplejwt
- python-decouple
## Frontend
- React (Vite)
- Axios
- ESLint
## Setup Instructions
1. Clone the repository.
2. Run the `initialisation.sh` script to set up the environment.
3. Start the Django development server:
   ```bash
   cd backend
   .venv/bin/python manage.py runserver
   ```
4. Start the React development server:
   ```bash
   cd frontend
   npm run dev
   ```

## Note
The `initialisation.sh` script will create necessary directories and files, install dependencies, and configure settings for both backend and frontend. It is designed to be run in a Unix-like environment with `bash`.
It will also replace the current README.md with a template README file that describes the project.