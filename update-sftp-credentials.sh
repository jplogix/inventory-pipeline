#!/bin/bash
# Script to update SFTP credentials

# Default values (current)
CURRENT_USER="finale"
CURRENT_PASSWORD="Inventory2025"

# Get new credentials from user input
read -p "Enter new SFTP username [$CURRENT_USER]: " NEW_USER
NEW_USER=${NEW_USER:-$CURRENT_USER}

read -s -p "Enter new SFTP password [$CURRENT_PASSWORD]: " NEW_PASSWORD
NEW_PASSWORD=${NEW_PASSWORD:-$CURRENT_PASSWORD}
echo

# Backup original docker-compose.yml
cp docker-compose.yml docker-compose.yml.bak

echo "Updating docker-compose.yml with new credentials..."
# Update the docker-compose.yml file
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS version of sed requires an empty string after -i
  sed -i '' "s|/home/$CURRENT_USER/uploads|/home/$NEW_USER/uploads|g" docker-compose.yml
  sed -i '' "s|command: $CURRENT_USER:$CURRENT_PASSWORD:|command: $NEW_USER:$NEW_PASSWORD:|g" docker-compose.yml
else
  # Linux version of sed
  sed -i "s|/home/$CURRENT_USER/uploads|/home/$NEW_USER/uploads|g" docker-compose.yml
  sed -i "s|command: $CURRENT_USER:$CURRENT_PASSWORD:|command: $NEW_USER:$NEW_PASSWORD:|g" docker-compose.yml
fi

# Update README.md if it exists
if [ -f "README.md" ]; then
  echo "Updating README.md with new credentials..."
  sed -i '' "s|User: $CURRENT_USER|User: $NEW_USER|g" README.md
  sed -i '' "s|Password: $CURRENT_PASSWORD|Password: $NEW_PASSWORD|g" README.md
fi

echo "Copying updated docker-compose.yml to server..."
scp docker-compose.yml root@107.175.249.182:/root/

echo "Restarting services with new credentials..."
ssh root@107.175.249.182 "cd /root && docker compose down && docker compose up -d"

echo "Checking if services started correctly..."
ssh root@107.175.249.182 "cd /root && docker compose ps"

echo "Done! Your new SFTP credentials are:"
echo "Username: $NEW_USER"
echo "Password: $NEW_PASSWORD"
echo "Port: 2222"
echo "Connect with: sftp -P 2222 $NEW_USER@107.175.249.182"
