#!/bin/bash

# Ensure the script exits on any error
set -e

echo "Setting up FinaleInventory Data Pipeline..."

# Create required directories
mkdir -p sftp/uploads sftp/config filebrowser
touch filebrowser/database.db

# Check if .env file exists, create if it doesn't
if [ ! -f .env ]; then
  echo "Creating .env file..."
  cp .env.example .env
  echo "Please edit the .env file with your configuration values"
  exit 1
fi

# Load environment variables
source .env

# Start services
echo "Starting services..."
docker compose up -d

# Setup Filebrowser admin user if specified
if [ -n "$FILEBROWSER_ADMIN_USER" ] && [ -n "$FILEBROWSER_ADMIN_PASS" ]; then
  echo "Setting up Filebrowser admin user..."
  sleep 5  # Give filebrowser a chance to start
  docker compose exec -T filebrowser filebrowser users add $FILEBROWSER_ADMIN_USER $FILEBROWSER_ADMIN_PASS --perm.admin
fi

echo "Setup complete!"
echo "SFTP access: sftp://$SFTP_USER@$HOST_IP:2222/uploads"
echo "Filebrowser access: http://$HOST_IP:$FILEBROWSER_PORT"
echo "Remember to secure your server with a firewall and consider using HTTPS!"