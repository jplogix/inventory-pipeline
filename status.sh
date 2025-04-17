#!/bin/bash

echo "===== FTP Data Pipeline Status ====="
echo ""

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
  echo "❌ Docker is not running!"
  exit 1
fi

# Load environment variables
if [ -f .env ]; then
  source .env
else
  echo "❌ .env file not found!"
  exit 1
fi

# Check container status
echo "Container Status:"
docker-compose ps --format "table {{.Name}}\t{{.State}}\t{{.Status}}\t{{.Ports}}"
echo ""

# Check disk space
echo "Disk Space Usage:"
du -h -d 1 ./sftp/uploads/ | sort -h
echo ""

# Check PostgreSQL connection
echo "PostgreSQL Connection:"
if docker-compose exec -T postgres pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB} >/dev/null 2>&1; then
  echo "✅ PostgreSQL is accepting connections"
  
  # Get table row counts
  echo "Database Tables:"
  docker-compose exec -T postgres psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c "\dt+"
  echo ""
  
  echo "Inventory Items Count:"
  docker-compose exec -T postgres psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c "SELECT COUNT(*) FROM inventory_items;"
else
  echo "❌ PostgreSQL connection failed"
fi
echo ""

# Check processor status
echo "Processor Status:"
PROC_STATUS=$(curl -s http://localhost:${PROCESSOR_PORT}/status || echo '{"status":"error","message":"Connection failed"}')
echo $PROC_STATUS | sed 's/[{"}]//g; s/,/\n/g'
echo ""

echo "===== Status Check Complete ====="