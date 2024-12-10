#!/bin/bash

# Define the applications/dashboard directory relative to the current user's home directory
APP_DIR="$HOME/applications/dashboard"

# Create the applications/dashboard directory if it doesn't exist
mkdir -p "$APP_DIR"

# Log output to a file for debugging inside the applications/dashboard directory
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


# Define secrets for frontend and backend
frontend_secrets=(
    "FRONTEND_IMAGE=$(get_secret_value "MDI_DASHBOARD_FRONTEND_IMAGE")"
    "VITE_APP_NAME=maxis"
    "VITE_API_BASE_URL=$(get_secret_value "MDI_DASHBOARD_API_URL")"
    "VITE_API_ROOT_URL=$(get_secret_value "MDI_DASHBOARD_API_BASE_URL")"
    "VITE_APP_PI_ACCESS_URL=$(get_secret_value "MDI_ACCESS_API_BASE_URL")"
    "VITE_APP_GOOGLE_MAP_API_KEY=$(get_secret_value "MDI_GOOGLE_MAP_API_KEY")"
)

backend_secrets=(
    "BACKEND_IMAGE=$(get_secret_value "MDI_DASHBOARD_BACKEND_IMAGE")"
    "APP_NAME=Maxis"
    "APP_PORT=3001"
    "DB_HOST=$(get_secret_value "MDI_DB_HOST")"
    "DB_PORT=$(get_secret_value "MDI_DB_PORT")"
    "DB_USERNAME=$(get_secret_value "MDI_DB_USER")"
    "DB_PASSWORD=$(get_secret_value "MDI_DB_PASSWORD")"
    "DB_NAME=$(get_secret_value "MDI_DASHBOARD_DB_NAME")"
    "DB_QUERY_LOGGER=$(get_secret_value "MDI_DASHBOARD_DB_QUERY_LOGGER")"
    "ACCESS_SERVICE_URL=$(get_secret_value "MDI_ACCESS_API_BASE_URL")"
    "GEOHASH_RESOLUTION=$(get_secret_value "MDI_DASHBOARD_GEOHASH_RESOLUTION")"
    "MAP_API_KEY=$(get_secret_value "MDI_GOOGLE_MAP_API_KEY")"
    "RUN_DB_MIGRATION=$(get_secret_value "MDI_DASHBOARD_RUN_DB_MIGRATION")"
    "SMTP_HOST=$(get_secret_value "MDI_SMTP_HOST")"
    "SMTP_PORT=$(get_secret_value "MDI_SMTP_PORT")"
    "SMTP_USER_NAME=$(get_secret_value "MDI_SMTP_USER_NAME")"
    "SMTP_PASSWORD=$(get_secret_value "MDI_SMTP_PASSWORD")"
    "SMTP_SENDER=$(get_secret_value "MDI_SMTP_SENDER")"
)

# Function to create the Nginx configuration file
create_nginx_conf() {
cat <<'EOF' > "$APP_DIR/nginx.conf"
events {}

http {
    upstream service1 {
        server frontend:5173;  # Use the service name defined in docker-compose.yml
    }
    upstream service2 {
        server backend:3001;  # Use the service name defined in docker-compose.yml
    }
    server {
        listen 80;
        ignore_invalid_headers off;

        location / {
            proxy_pass http://service1/;
            proxy_http_version 1.1;
            proxy_set_header Host $host;

            proxy_buffers 8 16k;
            proxy_buffer_size 32k;
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
name: mdi-dashboard
services:
  nginx:
    image: nginx
    container_name: nginx
    ports:
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
    depends_on:
      - frontend
      - backend

  frontend:
    container_name: frontend
    image: ${FRONTEND_IMAGE}
    command: yarn start
    env_file:
      - .env.frontend
    ports:
      - 5173:5173
    restart: unless-stopped

  backend:
    container_name: backend
    image: ${BACKEND_IMAGE}
    command: serve
    env_file:
      - .env.backend
    ports:
      - 3001:3001
    restart: unless-stopped
EOF
}

# Write secrets to respective .env files
write_secrets_to_env .env.frontend "${frontend_secrets[@]}"
write_secrets_to_env .env.backend "${backend_secrets[@]}"

# Create Docker Compose file
create_docker_compose

# Create Nginx configuration
create_nginx_conf

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
