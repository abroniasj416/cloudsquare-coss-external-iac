#!/usr/bin/env bash
set -euo pipefail

TF_VARS_FILE="${TF_VARS_FILE:-../env/terraform.tfvars}"

echo "[1/4] Terraform init"
terraform -chdir=external init

echo "[2/4] Terraform apply"
terraform -chdir=external apply -var-file="${TF_VARS_FILE}"

echo "[3/4] Generate Ansible inventory"
./ansible/generate_inventory.sh

BASTION_IP="$(terraform -chdir=external output -raw external_bastion_public_ip)"

echo "[4/4] Next steps"
echo "External bastion public IP: ${BASTION_IP}"
echo ""
echo "Connect to external bastion:"
echo "  ssh -i <private_key> dev1@${BASTION_IP}"
echo ""
echo "Then run on bastion inside this repo:"
echo "  ./ansible/bootstrap_bastion.sh"
echo "  export ANSIBLE_PRIVATE_KEY_FILE=<private_key_path_on_bastion>"
echo "  ./ansible/generate_inventory.sh"
echo "  ansible-playbook -i ansible/inventories/dev.ini ansible/playbooks/preflight.yml"
echo "  ansible-playbook -i ansible/inventories/dev.ini ansible/playbooks/external.yml"