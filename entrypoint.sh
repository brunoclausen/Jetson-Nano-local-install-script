#!/bin/bash

# Start the LocalAI server
source /app/localai/venv/bin/activate
cd /app/localai

# Check if superuser creation is needed
if [ "\$CREATE_SUPERUSER" = "true" ]; then
    python manage.py createsuperuser --noinput --username \$DJANGO_SUPERUSER_USERNAME --email \$DJANGO_SUPERUSER_EMAIL
fi

# Start the Django server
python manage.py runserver 0.0.0.0:8000
