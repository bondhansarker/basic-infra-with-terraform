#!/bin/bash

# Define the applications/access directory relative to the current user's home directory
APP_DIR="$HOME/applications/access"

# Create the applications/access directory if it doesn't exist
mkdir -p "$APP_DIR"

# Log output to a file for debugging inside the applications/access directory
exec > "$APP_DIR/startup-script.log" 2>&1

# Function to retrieve a secret value from GCP Secret Manager
get_secret_value() {
    local secret_name=$1
    gcloud secrets versions access latest --secret="$secret_name" --quiet
}

# Function to write secrets to a .env file
write_secrets_to_env() {
    local env_file="$APP_DIR/$1"
    shift
    local secrets=("$@")

    for secret in "${secrets[@]}"; do
        echo "$secret" >> "$env_file"
        export "$secret"
    done
}

# Define frontend secrets
frontend_secrets=(
    "FRONTEND_IMAGE=$(get_secret_value "MDI_ACCESS_FRONTEND_IMAGE")"
    "REDIRECT_URL_AFTER_CHANGE_PASSWORD=$(get_secret_value "MDI_DASHBOARD_FRONTEND_URL")"
    "API_BASE_URL=$(get_secret_value "MDI_ACCESS_API_BASE_URL")"
    "PI_ACCESS_URL=$(get_secret_value "MDI_ACCESS_API_BASE_URL")"
    "NEXTAUTH_URL=$(get_secret_value "MDI_ACCESS_FRONTEND_URL")"
    "NEXTAUTH_SECRET=$(get_secret_value "MDI_ACCESS_NEXTAUTH_SECRET")"
    "NEXTAUTH_SESSION_DURATION=$(get_secret_value "MDI_ACCESS_NEXTAUTH_SESSION_DURATION")"
    "ORGANIZATION_ID=$(get_secret_value "MDI_BASE_ORGANIZATION_ID")"
    "APPLICATION_ID=$(get_secret_value "MDI_BASE_APPLICATION_ID")"
    "CLIENT_ID=$(get_secret_value "MDI_BASE_CLIENT_ID")"
    "CLIENT_SECRET=$(get_secret_value "MDI_BASE_CLIENT_SECRET")"
    "GOOGLE_MAP_API_KEY=$(get_secret_value "MDI_GOOGLE_MAP_API_KEY")"
)

# Define backend secrets
backend_secrets=(
    "BACKEND_IMAGE=$(get_secret_value "MDI_ACCESS_BACKEND_IMAGE")"
    "APP_NAME=MyApp"
    "PORT=8081"
    "DB_TYPE=postgres"
    "DB_USER=$(get_secret_value "MDI_DB_USER")"
    "DB_PASS=$(get_secret_value "MDI_DB_PASSWORD")"
    "DB_HOST=$(get_secret_value "MDI_DB_HOST")"
    "DB_PORT=$(get_secret_value "MDI_DB_PORT")"
    "DB_NAME=$(get_secret_value "MDI_ACCESS_DB_NAME")"
    "RUN_DB_MIGRATION=$(get_secret_value "MDI_ACCESS_RUN_DB_MIGRATION")"
    "TABLE_NAME_PREFIX="
    "REDIS_PORT=$(get_secret_value "MDI_REDIS_PORT")"
    "REDISIP=$(get_secret_value "MDI_REDIS_HOST"):$(get_secret_value "MDI_REDIS_PORT")"
    "REDISPASS=$(get_secret_value "MDI_REDIS_PASSWORD")"
    "GIN_MODE=$(get_secret_value "MDI_ACCESS_GIN_MODE")"
    "MEGASALT=$(get_secret_value "MDI_ACCESS_MEGASALT")"
    "SMTP_HOST=$(get_secret_value "MDI_SMTP_HOST")"
    "SMTP_PORT=$(get_secret_value "MDI_SMTP_PORT")"
    "SMTP_USER_NAME=$(get_secret_value "MDI_SMTP_USER_NAME")"
    "SMTP_PASSWORD=$(get_secret_value "MDI_SMTP_PASSWORD")"
    "SMTP_SENDER=$(get_secret_value "MDI_SMTP_SENDER")"
    "PASSWORD_SET_URL=$(get_secret_value "MDI_DASHBOARD_FRONTEND_URL")/sign-up"
    "WEBHOOK_URLS=$(get_secret_value "MDI_ACCESS_WEBHOOK_URLS")"
    "BUCKET_NAME=$(get_secret_value "MDI_APP_BUCKET_NAME")"
    "GOOGLE_ACCESS_ID=$(get_secret_value "MDI_GOOGLE_ACCESS_ID")"
)

# Function to create the Nginx configuration file
create_nginx_conf() {
cat <<'EOF' > "$APP_DIR/nginx.conf"
events {}

http {
  upstream service1 {
      server frontend:3000;
  }
  upstream service2 {
      server backend:8081;
  }

  server {
        listen 80;
        ignore_invalid_headers off;
        client_max_body_size 100M;

        location / {
            proxy_pass http://service1/;
            proxy_http_version 1.1;
            proxy_set_header Host $host;

            proxy_buffers 8 16k;
            proxy_buffer_size 32k;
        }

        location _next/ {
            proxy_pass http://service1/;
            proxy_http_version 1.1;
            proxy_set_header Host $host;
          }

        location static/ {
            proxy_pass http://service1/;
            proxy_http_version 1.1;
            proxy_set_header Host $host;
        }

        location /backend/ {
            proxy_pass http://service2/;
            proxy_http_version 1.1;
            proxy_set_header Host $host;
        }
    }
}
EOF
}

# Function to create the Docker Compose file
create_docker_compose() {
cat <<EOF > "$APP_DIR/docker-compose.yml"
name: mdi-access
services:
  nginx:
    container_name: nginx
    image: nginx
    ports:
      - '80:80'
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
    depends_on:
      backend:
         condition: service_healthy

  redis:
    container_name: redis
    image: redis
    environment:
      - ALLOW_EMPTY_PASSWORD=NO
      - REDIS_PORT_NUMBER=${REDIS_PORT}
    command: redis-server --requirepass ${REDISPASS}
    ports:
      - '6379:6379'
    volumes:
      - redis:/data
    restart: always

  backend:
    container_name: backend
    image: ${BACKEND_IMAGE}
    command: server --init=${RUN_DB_MIGRATION}
    env_file:
      - .env.backend
    ports:
      - '8081:8081'
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8081/ping"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s
    depends_on:
      - redis

  frontend:
    container_name: frontend
    image: ${FRONTEND_IMAGE}
    command: yarn start
    env_file:
      - .env.frontend
    ports:
      - 3000:3000
    restart: unless-stopped
volumes:
  redis:
EOF
}


# Write secrets to respective .env files
write_secrets_to_env .env.frontend "${frontend_secrets[@]}"
write_secrets_to_env .env.backend "${backend_secrets[@]}"

# Create Nginx configuration
create_nginx_conf

# Create Docker Compose file
create_docker_compose

# Function to check if Docker is installed
check_docker() {
    command -v docker &> /dev/null
}

# Function to install Docker if it's not installed
install_docker() {
    echo "Installing Docker..."
    # Add Docker's official GPG key:
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to Apt sources:
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

# Function to pull and start Docker containers
start_docker_compose() {
    cd "$APP_DIR"
    sudo docker compose pull && sudo docker compose up -d
}

# Install Docker only if it's not already installed
if check_docker; then
  echo "Docker is already installed. Skipping installation."
else
  install_docker
fi

# Authenticate with Google Cloud
sudo gcloud auth configure-docker asia-southeast1-docker.pkg.dev --quiet

# Start Docker Compose services
start_docker_compose

# Log script completion
echo "Startup script completed" >> "$APP_DIR/startup-script.log"