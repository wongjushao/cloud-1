# Cloud-1 — Automated Inception deployment (Alibaba Cloud)

Ansible playbook that deploys the Inception WordPress stack (MariaDB, WordPress, phpMyAdmin, nginx) on fresh Ubuntu 22.04 ECS instances on Alibaba Cloud.

## Architecture

```
Internet ──► ECS (UFW: 22/80/443) ──► nginx :80/:443
                                         ├── WordPress (PHP-FPM :9000, internal)
                                         ├── phpMyAdmin (internal, /phpmyadmin/)
                                         └── MariaDB (:3306, internal only)
```

- **1 process = 1 container** (mysqld, php-fpm, nginx, phpMyAdmin Apache)
- **Persistence**: bind mounts under `~/data/mysql` and `~/data/wordpress`
- **Auto-restart**: `restart: unless-stopped` + Docker enabled on boot
- **TLS**: self-signed certificate generated on first run; HTTP redirects to HTTPS
- **Secrets**: root `.env` (not committed to git; shared by Docker and Ansible)

## Alibaba Cloud setup

### 1. Create an ECS instance

| Setting | Value |
|---------|-------|
| Region | Any (e.g. `cn-hongkong`, `ap-southeast-1`) |
| Image | Ubuntu 22.04 LTS 64-bit |
| Instance type | `ecs.t6-c1m1.large` or similar (2 vCPU / 1–2 GiB RAM minimum) |
| System disk | 40 GiB+ |
| Login | Key pair → user `ubuntu` |
| Public access | Assign an **Elastic IP** |

### 2. Security Group (network ACL)

Create inbound rules — **only these three ports**:

| Protocol | Port | Source | Purpose |
|----------|------|--------|---------|
| TCP | 22 | Your IP or `0.0.0.0/0` | SSH |
| TCP | 80 | `0.0.0.0/0` | HTTP → HTTPS redirect |
| TCP | 443 | `0.0.0.0/0` | HTTPS |

Do **not** open 3306 (MariaDB), 9000 (PHP-FPM), or any other port. The playbook also configures **UFW** on the instance with the same rules.

## Deploy

### Control machine requirements

- Ansible 2.14+ (`ansible-core`)
- Python 3, `rsync`, SSH access to ECS

```bash
sudo apt install ansible-core rsync   # Debian/Ubuntu control host
```

### 1. Configuration

Copy the example env file and fill in your ECS details and passwords:

```bash
cp .env.example .env
# Edit .env — set SSH key path, DATA_PATH, and all passwords
```

Edit `ansible/inventory/hosts.yml` to list each ECS instance (IP and domain per host). Credentials stay in `.env`:

| Variable | Purpose |
|----------|---------|
| `ANSIBLE_USER` | SSH user (`root` or `ubuntu`) |
| `ANSIBLE_SSH_PRIVATE_KEY_FILE` | Path to your `.pem` key |
| `DATA_PATH` / `SSL_PATH` | Persistent data on the remote host |
| `MYSQL_*` / `WP_*` | Database and WordPress credentials |

| Inventory (`hosts.yml`) | Purpose |
|-------------------------|---------|
| `ansible_host` | ECS Elastic IP (per server) |
| `domain_name` | Public hostname for that server (e.g. DuckDNS) |

Each host is served at `https://<domain_name>/`.

Add more hosts to `ansible/inventory/hosts.yml` as you provision ECS instances. If a host is not reachable yet, leave it commented out or deploy to one host only:

```bash
make deploy LIMIT=server1
```

Before enabling a new host, confirm SSH works: `ssh -i secrets/your_key.pem root@<ansible_host>`.

### 2. Run playbook

```bash
make deploy
# or (from project root):
set -a && . ./.env && set +a && \
  export ANSIBLE_SSH_PRIVATE_KEY_FILE="$(realpath "${ANSIBLE_SSH_PRIVATE_KEY_FILE}")" && \
  export ANSIBLE_CONFIG="$(pwd)/ansible/ansible.cfg" && \
  ansible-playbook "$(pwd)/ansible/playbooks/site.yml"
```

Re-running the playbook is **idempotent**: packages, firewall rules, and containers converge to the same state.

### Multi-server deployment

Uncomment additional hosts in `hosts.yml`. Each server still uses the same `.env` connection settings unless you extend the setup for multiple IPs.

## Ansible roles

| Role | Purpose |
|------|---------|
| `common` | Base packages (`rsync`, `curl`, …) |
| `docker` | Docker Engine + Compose plugin, enabled on boot |
| `firewall` | UFW — deny all incoming except 22, 80, 443 |
| `inception` | Sync `srcs/`, deploy `.env`, build & start stack |

## Local development (without Ansible)

Uses the same root `.env` as deployment:

```bash
cp .env.example .env
# Set DATA_PATH / SSL_PATH for your machine (see comments in .env.example)
make start
```

## Verification

After deployment:

- `https://<elastic-ip>/` — WordPress site
- `https://<elastic-ip>/phpmyadmin/` — phpMyAdmin (MariaDB)
- Reboot ECS → site and data remain available
- `nmap -p 1-65535 <elastic-ip>` → only 22, 80, 443 open

## Project layout

```
cloud-1/
├── .env.example                  # template — copy to .env
├── ansible/
│   ├── ansible.cfg
│   ├── inventory/hosts.yml       # reads ANSIBLE_* from .env
│   ├── playbooks/site.yml
│   └── roles/{common,docker,firewall,inception}/
├── srcs/
│   ├── docker-compose.yml        # reads ../.env
│   └── requirements/{mariadb,wordpress,nginx}/
└── Makefile
```
