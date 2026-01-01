FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

RUN apt-get update && apt-get install -y \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --upgrade pip setuptools wheel pip-tools

COPY requirements/ requirements/

RUN pip-sync requirements/production.txt

COPY backend/ backend/
COPY manage.py .

ENV DJANGO_SETTINGS_MODULE=config.settings.production

CMD ["gunicorn", "config.wsgi:application", "--bind", "0.0.0.0:8000"]
