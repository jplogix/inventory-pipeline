#!/bin/bash
# Script to check and fix deployment issues

echo "Finding deployment location..."
ssh root@107.175.249.182 "find / -name docker-compose.yml -type f 2>/dev/null || echo 'No docker-compose.yml found'"

echo "Checking running Docker containers..."
ssh root@107.175.249.182 "docker ps"

echo "Checking if port 8080 is open..."
ssh root@107.175.249.182 "netstat -tulpn | grep 8080 || echo 'Port 8080 not in use'"

echo "Opening port 8080 if needed (trying multiple firewall systems)..."
ssh root@107.175.249.182 "which ufw && ufw allow 8080/tcp || which firewall-cmd && firewall-cmd --permanent --add-port=8080/tcp || which iptables && iptables -A INPUT -p tcp --dport 8080 -j ACCEPT || echo 'No supported firewall found'"

echo "Deploying directly using Docker..."
ssh root@107.175.249.182 "mkdir -p /root/sftp-deployment"
scp docker-compose.yml .env root@107.175.249.182:/root/sftp-deployment/
ssh root@107.175.249.182 "cd /root/sftp-deployment && docker compose down && docker compose up -d"

echo "Verifying services are running..."
ssh root@107.175.249.182 "cd /root/sftp-deployment && docker compose ps"

echo "Checking logs for filebrowser..."
ssh root@107.175.249.182 "cd /root/sftp-deployment && docker compose logs filebrowser"
