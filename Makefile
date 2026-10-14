# Utilisation : make <cible> [ENV=dev|prod]
ENV       ?= dev
INVENTORY := inventories/$(ENV)/aws_ec2.yml
PLAYBOOK  := ansible-playbook -i $(INVENTORY)

.DEFAULT_GOAL := help
.PHONY: help install lint syntax test provision harden monitoring deploy validate site drift teardown

help: ## Affiche les commandes disponibles
	@grep -E '^[a-z-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

install: ## Installe l'outillage Python, les collections et les hooks git
	pip install -r requirements.txt
	ansible-galaxy collection install -r requirements.yml -p collections
	pre-commit install

lint: ## yamllint + ansible-lint (profil production)
	yamllint --strict .
	ansible-lint --profile production

syntax: ## Vérifie la syntaxe de chaque playbook
	@for p in playbooks/*.yml; do ansible-playbook -i localhost, --syntax-check $$p || exit 1; done

test: ## Molecule : converge + idempotence + conformité (Docker requis)
	molecule test

provision: ## Crée l'infrastructure AWS
	$(PLAYBOOK) playbooks/provision.yml

harden: ## Configuration de base + durcissement
	$(PLAYBOOK) playbooks/harden.yml

monitoring: ## node_exporter, agent CloudWatch et alarmes
	$(PLAYBOOK) playbooks/monitoring.yml

deploy: ## Déploiement progressif (rolling) de l'application
	$(PLAYBOOK) playbooks/deploy.yml

validate: ## Contrôles de conformité + rapports dans reports/
	$(PLAYBOOK) playbooks/validate.yml

site: ## Pipeline complet : provision -> harden -> monitoring -> deploy -> validate
	$(PLAYBOOK) playbooks/site.yml

drift: ## Détecte la dérive de configuration (simulation, aucun changement)
	$(PLAYBOOK) playbooks/harden.yml playbooks/monitoring.yml --check --diff

teardown: ## Détruit tout l'environnement
	$(PLAYBOOK) playbooks/teardown.yml -e confirm_teardown=yes
