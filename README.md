# FinaleInventory to PostgreSQL Data Pipeline

This setup provides a secure way to receive JSON exports from FinaleInventory and automatically process them into a PostgreSQL database.

## Components

- **SFTP Server**: Secure file transfer protocol server for receiving files
- **Filebrowser**: Web-based file manager for easy file management
- **PostgreSQL**: Database for storing inventory data
- **Processor Service**: NodeJS service that watches for new files and processes them into the database

## Setup Instructions

### Prerequisites

- Docker and Docker Compose installed on your VPS
- SSH access to your VPS

### Installation

1. Clone this repository to your VPS:

```bash
git clone https://github.com/yourusername/inventory-pipeline.git
cd inventory-pipeline
```

2. Create the required directories:

```bash
mkdir -p sftp/uploads sftp/config filebrowser
```

3. Set up secure passwords in the docker-compose.yml file:
   - Update the SFTP password (`ftpuser:ftppassword`)
   - Update the PostgreSQL password

4. Initialize the Filebrowser database:

```bash
touch filebrowser/database.db
```

5. Start the services:

```bash
docker-compose up -d
```

6. Initialize the Filebrowser admin user:

```bash
docker-compose exec filebrowser filebrowser users add admin admin --perm.admin
```

### Ports and Access

- **SFTP**: Port 2222 (remap to a different port if needed)
- **Filebrowser**: Port 8080 (remap to a different port if needed)
- **PostgreSQL**: Port 5432 (consider not exposing this port publicly)

### Configuring FinaleInventory

1. Set up scheduled exports in FinaleInventory to export JSON format
2. Configure SFTP connection:
   - Host: Your VPS IP or domain
   - Port: 2222 (or your remapped port)
   - User: ftpuser
   - Password: ftppassword (or your custom password)
   - Path: /uploads
   - Mode: Passive

### Security Recommendations

1. Use a firewall to restrict access to these ports
2. Consider using a reverse proxy with HTTPS for the Filebrowser
3. Change default passwords in all services
4. Consider using SSH keys for SFTP instead of passwords

## File Processing

The processor service automatically:
1. Watches for new .json files in the uploads directory
2. Validates the JSON structure
3. Imports the data to PostgreSQL
4. Moves processed files to a "processed" subdirectory

## Troubleshooting

### Checking Logs

```bash
# Check processor logs
docker-compose logs -f processor

# Check SFTP logs
docker-compose logs -f sftp
```

### Testing File Processing

Upload a test JSON file via SFTP or Filebrowser and check the logs.

### Common Issues

- **File permission issues**: Make sure the volumes have correct permissions
- **Connectivity issues**: Check that your firewall allows connections on the specified ports
- **Processing errors**: Check processor logs for validation errors

## Data Management

### Accessing PostgreSQL

```bash
docker-compose exec postgres psql -U dbuser -d inventory
```

### Backup and Restore

```bash
# Backup
docker-compose exec postgres pg_dump -U dbuser inventory > backup.sql

# Restore
cat backup.sql | docker-compose exec -T postgres psql -U dbuser inventory
```