# Usage: make <target> [ENV=dev|prod]
ENV       ?= dev
INVENTORY := inventories/$(ENV)/aws_ec2.yml
PLAYBOOK  := ansible-playbook -i $(INVENTORY)

.DEFAULT_GOAL := help
.PHONY: help install lint syntax test provision harden monitoring deploy validate site drift teardown

help: ## Show available targets
	@grep -E '^[a-z-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

install: ## Install Python tooling, collections and git hooks
	pip install -r requirements.txt
	ansible-galaxy collection install -r requirements.yml -p collections
	pre-commit install

lint: ## yamllint + ansible-lint (production profile)
	yamllint --strict .
	ansible-lint --profile production

syntax: ## Syntax check of every playbook
	@for p in playbooks/*.yml; do ansible-playbook -i localhost, --syntax-check $$p || exit 1; done

test: ## Molecule: converge + idempotence + compliance (Docker required)
	molecule test

provision: ## Create the AWS infrastructure
	$(PLAYBOOK) playbooks/provision.yml

harden: ## Base configuration + hardening
	$(PLAYBOOK) playbooks/harden.yml

monitoring: ## node_exporter, CloudWatch agent and alarms
	$(PLAYBOOK) playbooks/monitoring.yml

deploy: ## Rolling deployment of the application
	$(PLAYBOOK) playbooks/deploy.yml

validate: ## Compliance checks + reports in reports/
	$(PLAYBOOK) playbooks/validate.yml

site: ## Full pipeline: provision -> harden -> monitoring -> deploy -> validate
	$(PLAYBOOK) playbooks/site.yml

drift: ## Detect configuration drift (dry run, no change applied)
	$(PLAYBOOK) playbooks/harden.yml playbooks/monitoring.yml --check --diff

teardown: ## Destroy the whole environment
	$(PLAYBOOK) playbooks/teardown.yml -e confirm_teardown=yes
