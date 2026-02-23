TF_VARS_FILE ?= ../env/terraform.tfvars

.PHONY: apply ansible deploy

apply:
	terraform -chdir=external init
	terraform -chdir=external apply -var-file=$(TF_VARS_FILE)
	./ansible/generate_inventory.sh

ansible:
	@test -n "$(ANSIBLE_PRIVATE_KEY_FILE)" || (echo "Set ANSIBLE_PRIVATE_KEY_FILE first" && exit 1)
	ansible-playbook -i ansible/inventories/dev.ini ansible/playbooks/preflight.yml
	ansible-playbook -i ansible/inventories/dev.ini ansible/playbooks/external.yml

deploy: apply ansible