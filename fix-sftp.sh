#!/bin/bash
# Fix SFTP Connection Issues

echo "==== Checking server connection ===="
ssh root@107.175.249.182 "echo 'Connected to server successfully'"

echo "==== Checking Docker status ===="
ssh root@107.175.249.182 "systemctl status docker | grep Active || echo 'Docker service status check failed'"

echo "==== Starting Docker if needed ===="
ssh root@107.175.249.182 "systemctl start docker || echo 'Failed to start Docker'"

echo "==== Creating required directories ===="
ssh root@107.175.249.182 "mkdir -p /root/files/sftp/uploads /root/files/sftp/config /root/files/filebrowser /root/files/pgdata"
ssh root@107.175.249.182 "chmod -R 775 /root/files"

echo "==== Deploying services ===="
# Copy files to server
scp docker-compose.yml .env root@107.175.249.182:/root/
# Copy processor directory
ssh root@107.175.249.182 "mkdir -p /root/processor"
scp processor/* root@107.175.249.182:/root/processor/

echo "==== Starting services ===="
ssh root@107.175.249.182 "cd /root && docker compose down && docker compose up -d"

echo "==== Opening firewall ===="
ssh root@107.175.249.182 "iptables -A INPUT -p tcp --dport 2222 -j ACCEPT || echo 'Failed to open port 2222'"
ssh root@107.175.249.182 "iptables -A INPUT -p tcp --dport 8080 -j ACCEPT || echo 'Failed to open port 8080'"

echo "==== Checking service status ===="
ssh root@107.175.249.182 "cd /root && docker compose ps"

echo "==== Checking service logs ===="
ssh root@107.175.249.182 "cd /root && docker compose logs sftp"

echo "==== Checking port 2222 ===="
ssh root@107.175.249.182 "netstat -tulpn | grep 2222 || echo 'Port 2222 not in use'"

echo "==== Done ===="
echo "Try connecting again with: sftp -P 2222 ftpuser@107.175.249.182"
