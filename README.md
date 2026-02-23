# cloudsquare-coss-external-iac

Terraform + Ansible + Apps monorepo for external infrastructure and deployment.

## Structure
- `external/`: Terraform infrastructure (VPC, subnet, server, LB, external bastion)
- `ansible/`: configuration, security, logging, container deployment
- `apps/`: web and api source code

## External bastion architecture
- External VPC public subnet hosts `external-bastion-svr` with public IP.
- Web/WAS remain private subnet only.
- Operational access path is internet -> external bastion -> private web/was.

## Required user changes
- `env/terraform.tfvars`: set `bootstrap_public_key`, `allowed_ssh_cidr`
- `ansible/group_vars/all.yml`: set `api_image_name`, `api_image_tag`

## API deployment mode selection
- Default (`local`): copy `apps/api` to WAS and build/run on server.
- `ghcr`: pull immutable image from GHCR and run container.

Set mode in `ansible/group_vars/all.yml`.

Local mode example:
```yaml
api_deploy_mode: local
api_local_image: external-api:local
```

GHCR mode example:
```yaml
api_deploy_mode: ghcr
api_image_name: ghcr.io/<org>/<repo>
api_image_tag: "v1.0.0"
api_container_recreate: false
```
## Ansible collection version lock
- Collection versions are pinned in `ansible/requirements.yml`.
- Install with:

```bash
ansible-galaxy collection install -r ansible/requirements.yml
```

`ansible/bootstrap_bastion.sh` already runs this command.

## Security design
- External bastion is the single operational entry point for SSH/Ansible.
- Private web/was do not allow direct internet SSH.
- Access model is `dev1` user + `sudo` for privileged operations.
- SSH hardening enforces `PermitRootLogin no` and `PasswordAuthentication no`.
- Docker socket (`/var/run/docker.sock`) grants root-equivalent control; restrict membership and automation scope.

## Execution order (standard)
1. Terraform apply
```bash
terraform -chdir=external init
terraform -chdir=external apply -var-file=../env/terraform.tfvars
```
2. Generate inventory from Terraform outputs
```bash
./ansible/generate_inventory.sh
```
3. SSH into external bastion
```bash
ssh -i <private_key> dev1@$(terraform -chdir=external output -raw external_bastion_public_ip)
```
4. On bastion, bootstrap and deploy
```bash
./ansible/bootstrap_bastion.sh
export ANSIBLE_PRIVATE_KEY_FILE=<private_key_path_on_bastion>
./ansible/generate_inventory.sh
ansible-playbook -i ansible/inventories/dev.ini ansible/playbooks/preflight.yml
ansible-playbook -i ansible/inventories/dev.ini ansible/playbooks/external.yml
```

## Bastion repository setup options
### Method A (recommended): git clone on bastion
```bash
git clone <repo_url>
cd cloudsquare-coss-external-iac
```

### Method B: upload from local machine
```bash
scp -i <private_key> -r ./cloudsquare-coss-external-iac dev1@<external_bastion_public_ip>:~/
ssh -i <private_key> dev1@<external_bastion_public_ip>
cd ~/cloudsquare-coss-external-iac
```

## ProxyJump usage (optional)
- If running Ansible outside bastion, set jump host in inventory `[all:vars]`:

```ini
ansible_ssh_common_args='-o ProxyJump=dev1@<external_bastion_public_ip>'
```

## Idempotency verification
1. Dry-run validation:
```bash
ansible-playbook -i ansible/inventories/dev.ini ansible/playbooks/external.yml --check
```
2. Run normal apply twice; second run should report `changed=0` as steady state.
3. If `api_container_recreate=true`, container tasks will report changes by design.

## Integrated commands
- One-shot script:
```bash
./run.sh
```
- Make targets:
```bash
make apply
ANSIBLE_PRIVATE_KEY_FILE=/path/to/dev1.pem make ansible
ANSIBLE_PRIVATE_KEY_FILE=/path/to/dev1.pem make deploy
```

## Validation checklist
- SSH from internet directly to web/was is blocked.
- SSH from external bastion to web/was private IPs works with `dev1`.
- `preflight.yml` passes.
- `external.yml` completes and containers run (`web:80`, `api:8080`).

## Operating model summary
Terraform provisions immutable network and compute resources as Infrastructure as Code.
Ansible applies hardened host and runtime configuration as Configuration as Code from the bastion.
GHCR delivers immutable API images, separating build and deployment responsibilities.
External bastion centralizes administrative ingress and reduces direct attack surface on private workloads.
Preflight enforces connectivity and execution prerequisites before configuration rollout.
Nginx config changes are applied through in-container reload to avoid unnecessary downtime.