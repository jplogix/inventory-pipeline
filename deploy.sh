#!/bin/bash
# Complete deployment script that fixes the missing processor directory issue

echo "===== Creating deployment package ====="
# Create a temporary directory for deployment
mkdir -p deploy-tmp

# Copy the necessary files
cp -r processor deploy-tmp/
cp docker-compose.yml deploy-tmp/
cp .env deploy-tmp/

echo "===== Uploading to server ====="
# Create the destination directory on the server
ssh root@107.175.249.182 "mkdir -p /root/sftp-app"

# Upload the package
scp -r deploy-tmp/* root@107.175.249.182:/root/sftp-app/

echo "===== Stopping existing services ====="
# Stop any existing services that might be running
ssh root@107.175.249.182 "cd /etc/dokploy/compose/federal-watches-sftp-to7ika && docker compose down" || true

echo "===== Deploying services ====="
# Deploy using the uploaded files
ssh root@107.175.249.182 "cd /root/sftp-app && docker compose up -d"

echo "===== Checking service status ====="
# Check if services are running
ssh root@107.175.249.182 "cd /root/sftp-app && docker compose ps"

echo "===== Creating directories for file persistence ====="
# Create necessary directories for persistence
ssh root@107.175.249.182 "mkdir -p /root/files/sftp/uploads /root/files/sftp/config /root/files/filebrowser /root/files/pgdata"
ssh root@107.175.249.182 "chmod -R 775 /root/files"

echo "===== Viewing logs ====="
# Display logs for troubleshooting
ssh root@107.175.249.182 "cd /root/sftp-app && docker compose logs filebrowser"

echo "===== Cleanup ====="
# Clean up temporary files
rm -rf deploy-tmp

echo "===== Done ====="
echo "If successful, access File Browser at: http://107.175.249.182:8080"
echo "Access SFTP at: sftp -P 2222 ftpuser@107.175.249.182"
