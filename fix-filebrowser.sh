#!/bin/bash
# Fix filebrowser database issue

echo "==== Creating fix for filebrowser database issue ===="

echo "1. Creating proper database file structure on server..."
ssh root@107.175.249.182 "mkdir -p /root/files/filebrowser"
# First, remove the directory if it exists
ssh root@107.175.249.182 "rm -rf /root/files/filebrowser/database.db"
# Then create an empty database file
ssh root@107.175.249.182 "touch /root/files/filebrowser/database.db"
# Also create empty config file if it doesn't exist
ssh root@107.175.249.182 "test -f /root/files/filebrowser/config.json || echo '{}' > /root/files/filebrowser/config.json"

echo "2. Updating docker-compose.yml with absolute paths..."
cat > docker-compose.updated.yml << 'EOL'
services:
  sftp:
    image: atmoz/sftp
    volumes:
      - /root/files/sftp/uploads:/home/finale/uploads
    ports:
      - "2222:22"
    command: finale:Inventory2025:1001:100:uploads
    restart: unless-stopped

  filebrowser:
    image: filebrowser/filebrowser
    volumes:
      - /root/files/sftp/uploads:/srv
      - /root/files/filebrowser/database.db:/database.db
      - /root/files/filebrowser/config.json:/config.json
    ports:
      - "8080:80"
    restart: unless-stopped
    depends_on:
      - sftp

  postgres:
    image: postgres:15
    environment:
      POSTGRES_USER: dbuser
      POSTGRES_PASSWORD: dbpassword
      POSTGRES_DB: inventory
    volumes:
      - /root/files/pgdata:/var/lib/postgresql/data
    ports:
      - "5438:5432"
    restart: unless-stopped

  processor:
    build: ./processor
    volumes:
      - /root/files/sftp/uploads:/app/uploads
    environment:
      - DB_HOST=postgres
      - DB_PORT=5432
      - DB_USER=dbuser
      - DB_PASSWORD=dbpassword
      - DB_NAME=inventory
      - WATCH_DIRECTORY=/app/uploads
    restart: unless-stopped
    depends_on:
      - postgres
      - sftp

volumes:
  pgdata:
EOL

echo "3. Copying updated docker-compose.yml to server..."
scp docker-compose.updated.yml root@107.175.249.182:/root/docker-compose.yml

echo "4. Creating directory structure on server..."
ssh root@107.175.249.182 "mkdir -p /root/files/sftp/uploads /root/files/sftp/config /root/files/filebrowser /root/files/pgdata"

echo "5. Setting proper permissions..."
ssh root@107.175.249.182 "chmod -R 775 /root/files"

echo "6. Restarting services with fixed configuration..."
ssh root@107.175.249.182 "cd /root && docker compose down && docker compose up -d"

echo "7. Checking if services started correctly..."
ssh root@107.175.249.182 "cd /root && docker compose ps"

echo "==== Done! ===="
echo "You should now be able to access filebrowser at http://107.175.249.182:8080"
echo "SFTP server is available at sftp -P 2222 finale@107.175.249.182"
