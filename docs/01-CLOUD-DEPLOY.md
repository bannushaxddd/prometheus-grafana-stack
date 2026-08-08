# 1) Deploy on a Cloud VM (DigitalOcean or AWS)

Goal: your monitoring stack runs on a real server with a public IP — not only on your laptop.  
This is what interviewers mean by “production-like.”

---

## What you will have at the end

```
Internet
   │
   ▼
Cloud VM (Ubuntu 22.04)
   │
   ├── :443  Grafana (HTTPS)     ← only this is public (recommended)
   ├── Docker Compose stack
   │     Prometheus, exporters, app, MySQL, Mongo, Loki, Alertmanager...
   └── Firewall blocks 9090/9100/etc from the public internet
```

---

## Option A — DigitalOcean (simplest for beginners)

### Step 1: Create a Droplet

1. Sign up / log in at [digitalocean.com](https://www.digitalocean.com)
2. **Create → Droplets**
3. Choose:
   - **Image:** Ubuntu 22.04 LTS
   - **Plan:** Basic, **2 GB RAM / 1 vCPU** minimum (4 GB better)
   - **Datacenter:** closest to you
   - **Auth:** SSH key (recommended) or password
4. Create droplet → copy the **public IP** (example: `164.92.x.x`)

### Step 2: SSH into the server

From your Windows PowerShell (or use the DO web console):

```powershell
ssh root@YOUR_DROPLET_IP
```

### Step 3: Install Docker on the server

Paste this on the VM:

```bash
apt update && apt upgrade -y
apt install -y ca-certificates curl git ufw
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" \
  > /etc/apt/sources.list.d/docker.list
apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
systemctl enable --now docker
docker --version
```

### Step 4: Copy your project to the VM

**From your Windows PC** (in project folder):

```powershell
cd D:\prometheus-3.13.1.windows-amd64

# Create an archive without huge local data
tar -czf monitoring-stack.tgz `
  --exclude=data `
  --exclude=app/node_modules `
  --exclude=alert-logger/node_modules `
  docker-compose.yml .env.example prometheus grafana alertmanager `
  app nginx mysql loki promtail alert-logger scripts docs
```

If `tar` fails on Windows, use scp of the folder after zipping in Explorer, or:

```powershell
scp -r D:\prometheus-3.13.1.windows-amd64 root@YOUR_DROPLET_IP:/opt/monitoring
```

Then on the server clean junk if needed:

```bash
cd /opt/monitoring
rm -rf data app/node_modules 2>/dev/null
```

### Step 5: Configure secrets on the server

```bash
cd /opt/monitoring
cp .env.example .env
nano .env
```

**Must change:**

```env
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=USE_A_LONG_RANDOM_PASSWORD
GRAFANA_ROOT_URL=https://YOUR_DOMAIN_OR_IP

# later after HTTPS domain:
# GRAFANA_ROOT_URL=https://monitor.yourdomain.com
```

Also change MySQL/Mongo passwords.

### Step 6: Firewall (critical)

Only open SSH + HTTP/HTTPS. **Do not** open Prometheus publicly.

```bash
ufw allow OpenSSH
ufw allow 80/tcp
ufw allow 443/tcp
ufw enable
ufw status
```

For a first test only, you *can* temporarily open Grafana port:

```bash
# TEMP only for testing before HTTPS reverse proxy
ufw allow 3001/tcp
```

Then remove it after HTTPS works:

```bash
ufw delete allow 3001/tcp
```

### Step 7: Start the stack

```bash
cd /opt/monitoring
docker compose up -d --build
docker compose ps
```

Test from your browser:

- `http://YOUR_DROPLET_IP:3001` → Grafana login  
- `http://YOUR_DROPLET_IP:8080` → demo app  

### Step 8: Screenshots for portfolio

Capture:

1. DigitalOcean droplet page with IP  
2. `docker compose ps` all healthy  
3. Grafana login over public IP  
4. Dashboards with live data  

---

## Option B — AWS EC2 (common in job descriptions)

### Step 1: Launch instance

1. AWS Console → **EC2 → Launch instance**
2. Name: `monitoring-lab`
3. AMI: **Ubuntu Server 22.04 LTS**
4. Instance type: **t3.small** (or t3.medium)
5. Key pair: create/download `.pem`
6. Network:
   - Allow **SSH (22)** from your IP
   - Allow **HTTP (80)** from anywhere
   - Allow **HTTPS (443)** from anywhere
   - **Do not** open 9090, 9100, 3306, etc.
7. Storage: 20–30 GB gp3
8. Launch

### Step 2: Connect

```powershell
ssh -i "C:\path\to\your-key.pem" ubuntu@YOUR_EC2_PUBLIC_DNS
```

### Step 3–7

Same as DigitalOcean:

- Install Docker  
- Copy project to `/opt/monitoring`  
- Edit `.env`  
- `docker compose up -d --build`  

On Ubuntu AMI, use `ubuntu` user and `sudo` for docker if needed:

```bash
sudo usermod -aG docker ubuntu
# log out/in, then docker works without sudo
```

### Optional: Elastic IP

Attach an **Elastic IP** so the public address does not change after stop/start.

---

## Cost reality (say this in interviews)

| Provider | Rough monthly cost (small VM) |
|----------|--------------------------------|
| DigitalOcean 2–4 GB droplet | ~$12–24 |
| AWS t3.small | ~$15–25 + small disk/bandwidth |

> “I deployed a cost-aware single-node observability stack suitable for lab/staging; production would use HA Prometheus, managed DBs, and private networking.”

---

## Production-hardening checklist (after it boots)

- [ ] Strong Grafana password  
- [ ] Firewall: only 22/80/443 public  
- [ ] Prometheus **not** public  
- [ ] HTTPS (see `02-HTTPS-GRAFANA.md`)  
- [ ] Slack alerts working (`03-SLACK-ALERTS.md`)  
- [ ] `docker compose` restarts after reboot (`restart: unless-stopped` already set)

Enable Docker on boot (default with docker-ce). Ensure compose project starts on reboot:

```bash
# optional systemd unit
cat >/etc/systemd/system/monitoring-stack.service <<'EOF'
[Unit]
Description=Monitoring Stack
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/monitoring
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF
systemctl enable monitoring-stack
```

---

## Interview line for this section

> “I deployed the full Prometheus/Grafana stack on an Ubuntu cloud VM with Docker Compose, locked the firewall so only SSH and the HTTPS entrypoint are public, and kept Prometheus/exporters on the private Docker network.”
