.DEFAULT_GOAL := help
TF  := terraform -chdir=terraform
ANS := cd ansible && ansible-playbook

help: ## Show targets
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN{FS=":.*?## "}{printf "  %-14s %s\n",$$1,$$2}'

deps: ## Install Ansible collections and fetch Temper
	git submodule update --init
	cd ansible && ansible-galaxy collection install -r requirements.yml

lint: ## yamllint, ansible-lint, terraform fmt
	yamllint -c .yamllint ansible .github
	cd ansible && ansible-lint
	$(TF) fmt -check -recursive

test: ## Render all templates, validate them with real tools, run the backup e2e test
	$(ANS) tests/render.yml
	tests/validate.sh
	$(ANS) tests/backup_e2e.yml

router: ## Configure the router (network changes roll back automatically on lockout)
	$(ANS) playbooks/router.yml

hypervisor: ## Post-install the Proxmox host (repos, API user, cloud-init template)
	$(ANS) playbooks/hypervisor.yml

vms: ## Create/update the VMs on Proxmox from lab.yml
	$(TF) init -input=false
	$(TF) apply

services: ## Configure VMs: hardening, Docker, stacks, backups
	$(ANS) playbooks/vms.yml

audit: ## Read-only checks on every host
	$(ANS) playbooks/audit.yml

deploy: router hypervisor vms services audit ## Everything, in order

backup-now: ## Run a backup on svc-01 now
	cd ansible && ansible services -b -m ansible.builtin.systemd_service -a "name=homelab-backup.service state=started"

restore-test-now: ## Run the restore test on svc-01 now
	cd ansible && ansible services -b -m ansible.builtin.systemd_service -a "name=homelab-restore-test.service state=started"

clean: ## Remove rendered test output
	rm -rf build

.PHONY: help deps lint test router hypervisor vms services audit deploy backup-now restore-test-now clean
