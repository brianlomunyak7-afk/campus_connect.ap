# Python 3.12 matches the version the backend is developed and tested on
FROM python:3.12-slim

WORKDIR /app

# psycopg2-binary ships its own libpq, so no system packages are needed
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
