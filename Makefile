# Inception Makefile

-include .env

ENV_FILE = .env
COMPOSE_FILE = srcs/docker-compose.yml
COMPOSE = docker compose -f $(COMPOSE_FILE) --env-file $(ENV_FILE)

check-docker:
	@command -v docker >/dev/null 2>&1 || { \
		echo "Docker is not installed on this machine."; \
		echo ""; \
		echo "Install locally (Ubuntu/WSL):"; \
		echo "  sudo apt update && sudo apt install -y docker.io docker-compose-v2"; \
		echo "  sudo usermod -aG docker $$USER && newgrp docker"; \
		echo ""; \
		echo "Or deploy to your ECS (Docker runs on the remote server):"; \
		echo "  make deploy"; \
		exit 1; \
	}

all: up

build: check-docker
	@$(COMPOSE) build

build-nocache: check-docker
	@$(COMPOSE) build --no-cache

up: check-docker
	@test -f $(ENV_FILE) || (echo "Copy .env.example to .env and set your values first." && exit 1)
	@sudo mkdir -p $(DATA_PATH)/mysql $(DATA_PATH)/wordpress $(SSL_PATH)
	@sudo chown -R $(USER):$(USER) $(DATA_PATH) $(SSL_PATH)
	@$(COMPOSE) up -d
	@echo "Access your site at: https://$(DOMAIN_NAME)/"

start: build up

down: check-docker
	@$(COMPOSE) down

clean: check-docker
	@$(COMPOSE) down -v

fclean: check-docker
	@$(COMPOSE) down -v --rmi all --remove-orphans
	@sudo rm -rf $(DATA_PATH)/mysql $(DATA_PATH)/wordpress $(SSL_PATH)
	@docker system prune -af --volumes 2>/dev/null || true

re: fclean build-nocache up

status: check-docker
	@$(COMPOSE) ps

logs: check-docker
	@$(COMPOSE) logs -f

restart: down up

init-dirs:
	@sudo mkdir -p $(DATA_PATH)/mysql $(DATA_PATH)/wordpress $(SSL_PATH)
	@sudo chown -R $(USER):$(USER) $(DATA_PATH) $(SSL_PATH)

.PHONY: all build up start down clean fclean re status logs restart init-dirs deploy check-docker

deploy:
	@test -f $(ENV_FILE) || \
		(echo "Copy .env.example to .env and set your values first." && exit 1)
	@set -a && . ./$(ENV_FILE) && set +a && \
		export ANSIBLE_SSH_PRIVATE_KEY_FILE="$$(cd "$(CURDIR)" && realpath "$${ANSIBLE_SSH_PRIVATE_KEY_FILE}")" && \
		test -f "$$ANSIBLE_SSH_PRIVATE_KEY_FILE" || \
		(echo "SSH key not found: $$ANSIBLE_SSH_PRIVATE_KEY_FILE" && exit 1) && \
		export ANSIBLE_CONFIG="$(CURDIR)/ansible/ansible.cfg" && \
		ansible-playbook "$(CURDIR)/ansible/playbooks/site.yml" $(if $(LIMIT),--limit $(LIMIT),)
