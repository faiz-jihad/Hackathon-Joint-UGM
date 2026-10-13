FROM python:3.11-slim

WORKDIR /app

# Install system runtime dependencies for OpenCV and healthcheck
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libgl1 \
    libglib2.0-0 \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application source code
COPY . .

EXPOSE 8003

ENV PORT=8003
ENV HOST=0.0.0.0
ENV PYTHONUNBUFFERED=1

HEALTHCHECK --interval=10s --timeout=5s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8003/health || exit 1

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8003"]
