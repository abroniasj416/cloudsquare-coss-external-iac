#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REQUIREMENTS_FILE="${SCRIPT_DIR}/requirements.yml"

if [[ ! -f "${REQUIREMENTS_FILE}" ]]; then
  echo "[ERROR] requirements file not found: ${REQUIREMENTS_FILE}" >&2
  exit 1
fi

if [[ "${EUID}" -eq 0 ]]; then
  SUDO=""
else
  SUDO="sudo"
fi

echo "[INFO] Installing base packages (python3, git, jq, python3-pip)"
${SUDO} dnf -y install python3 git jq python3-pip

echo "[INFO] Installing Ansible"
if ${SUDO} dnf -y install ansible; then
  echo "[INFO] Ansible installed via dnf"
else
  echo "[WARN] dnf ansible install failed, falling back to pip"
  python3 -m pip install --user --upgrade pip ansible
  export PATH="$HOME/.local/bin:$PATH"
fi

echo "[INFO] Installing Ansible collections from requirements.yml"
ansible-galaxy collection install -r "${REQUIREMENTS_FILE}"

echo
echo "[INFO] Bootstrap complete. Example commands:"
echo "  export ANSIBLE_PRIVATE_KEY_FILE=/path/to/dev1.pem"
echo "  ./ansible/generate_inventory.sh"
echo "  ansible-playbook -i ansible/inventories/dev.ini ansible/playbooks/preflight.yml"
echo "  ansible-playbook -i ansible/inventories/dev.ini ansible/playbooks/external.yml"