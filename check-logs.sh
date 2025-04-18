#!/bin/bash
# Script to check logs of all services and diagnose issues

echo "==== Container Status ===="
ssh root@107.175.249.182 "docker ps -a | grep federal-watches-sftp"

echo -e "\n==== FileBrowser Logs ===="
ssh root@107.175.249.182 "docker logs federal-watches-sftp-to7ika-filebrowser-1 2>&1 || echo 'No logs available'"

echo -e "\n==== SFTP Logs ===="
ssh root@107.175.249.182 "docker logs federal-watches-sftp-to7ika-sftp-1 2>&1 || echo 'No logs available'"

echo -e "\n==== Postgres Logs ===="
ssh root@107.175.249.182 "docker logs federal-watches-sftp-to7ika-postgres-1 2>&1 || echo 'No logs available'"

echo -e "\n==== Processor Logs ===="
ssh root@107.175.249.182 "docker logs federal-watches-sftp-to7ika-processor-1 2>&1 || echo 'No logs available'"

echo -e "\n==== Checking Directory Structure ===="
ssh root@107.175.249.182 "cd /etc/dokploy/compose/federal-watches-sftp-to7ika && ls -la"

echo -e "\n==== Checking File Paths ===="
ssh root@107.175.249.182 "find /etc/dokploy/compose/federal-watches-sftp-to7ika -type d | sort"

echo -e "\n==== Checking Docker Volumes ===="
ssh root@107.175.249.182 "docker volume ls | grep federal"

echo -e "\n==== Checking Network Configuration ===="
ssh root@107.175.249.182 "docker network inspect \$(docker network ls --filter name=federal -q) 2>/dev/null || echo 'Network not found'"
