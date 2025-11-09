# Dockerfile for ASPR Agent Service (Cloud Run Deployment)
FROM python:3.11-slim

# Install system dependencies & gcloud CLI
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    bash \
    git \
    gnupg \
    && curl https://sdk.cloud.google.com | bash \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ENV PATH="/root/google-cloud-sdk/bin:${PATH}"

WORKDIR /app

# Install Python requirements
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application source code and scripts
COPY . .

# Set default environment variables
ENV PORT=8080
ENV PYTHONUNBUFFERED=1

EXPOSE 8080

CMD ["uvicorn", "deploy.app:app", "--host", "0.0.0.0", "--port", "8080"]
