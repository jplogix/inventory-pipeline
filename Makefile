.PHONY: setup deploy dokploy-init dokploy-deploy logs status backup restore clean help

help:
	@echo "FinaleInventory Data Pipeline Makefile"
	@echo ""
	@echo "Available commands:"
	@echo "  setup           - Set up directories and initialize locally"
	@echo "  deploy          - Deploy manually to the current server"
	@echo "  dokploy-init    - Initialize Dokploy configuration"
	@echo "  dokploy-deploy  - Deploy using Dokploy"
	@echo "  logs            - Show logs from all services"
	@echo "  status          - Check status of all services"
	@echo "  backup          - Create a backup of the PostgreSQL database"
	@echo "  restore FILE=x  - Restore from a backup file (specify FILE=path/to/backup.sql)"
	@echo "  clean           - Remove containers and volumes but keep config files"
	@echo ""

setup:
	@echo "Setting up FinaleInventory Data Pipeline..."
	@chmod +x setup.sh
	@./setup.sh

deploy:
	@echo "Deploying services..."
	@docker-compose up -d
	@echo "Deployment complete!"

dokploy-init:
	@echo "Initializing Dokploy..."
	@chmod +x init-dokploy.sh
	@./init-dokploy.sh

dokploy-deploy:
	@echo "Deploying with Dokploy..."
	@dokploy deploy production

logs:
	@docker-compose logs --tail=100

status:
	@chmod +x status.sh
	@./status.sh

backup:
	@echo "Creating database backup..."
	@mkdir -p backups
	@docker-compose exec -T postgres pg_dump -U $$(grep POSTGRES_USER .env | cut -d '=' -f2) $$(grep POSTGRES_DB .env | cut -d '=' -f2) > backups/backup-$$(date +%Y%m%d-%H%M%S).sql
	@echo "Backup created in the backups directory"

restore:
	@if [ -z "$(FILE)" ]; then echo "Please specify a backup file with FILE=path/to/backup.sql"; exit 1; fi
	@echo "Restoring from $(FILE)..."
	@cat $(FILE) | docker-compose exec -T postgres psql -U $$(grep POSTGRES_USER .env | cut -d '=' -f2) $$(grep POSTGRES_DB .env | cut -d '=' -f2)
	@echo "Restore completed"

clean:
	@echo "Removing containers and volumes..."
	@docker-compose down -v
	@echo "Cleanup complete. Configuration files are preserved."