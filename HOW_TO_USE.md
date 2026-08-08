# How to Use This Monitoring Stack (Step by Step)

This guide walks you from zero → Grafana dashboards with your username and password.

---

## Your Grafana login (default)

| Field | Value |
|--------|--------|
| **URL** | http://localhost:3001 |
| **Username** | `admin` |
| **Password** | `AdminMonitor2024` |

Read-only user (created by `start.ps1`):

| Field | Value |
|--------|--------|
| **Username** | `viewer` |
| **Password** | `ViewerMonitor2024` |

These come from the `.env` file. Change them anytime (see Step 7).

---

## Step 1 — Install prerequisites

1. Install **[Docker Desktop for Windows](https://www.docker.com/products/docker-desktop/)**  
2. Install **[Node.js](https://nodejs.org/)** (only needed for native mode; optional if you use Docker)  
3. Restart your PC if Docker asks you to  
4. Open **Docker Desktop** and wait until it says the engine is **running** (whale icon steady in the tray)

---

## Step 2 — Open the project folder

In PowerShell:

```powershell
cd D:\prometheus-3.13.1.windows-amd64
```

Confirm files exist:

```powershell
dir docker-compose.yml, .env, HOW_TO_USE.md
```

---

## Step 3 — (Optional) Change your passwords first

Open `.env` in Notepad:

```powershell
notepad .env
```

Edit at least:

```env
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=AdminMonitor2024
GRAFANA_VIEWER_USER=viewer
GRAFANA_VIEWER_PASSWORD=ViewerMonitor2024
```

Save the file. **Use these exact values when you log into Grafana.**

---

## Step 4 — Start the full stack

```powershell
.\scripts\start.ps1
```

Or manually:

```powershell
docker compose up -d --build
```

First run downloads images (several minutes). When finished you should see containers for:

- grafana, prometheus, alertmanager  
- app, nginx, mysql, mongo  
- node-exporter, mysqld-exporter, mongodb-exporter  
- loki, promtail, alert-logger, cadvisor  

Check status:

```powershell
.\scripts\status.ps1
```

---

## Step 5 — Log in to Grafana

1. Open your browser  
2. Go to: **http://localhost:3001**  
3. You will see the Grafana login page  
4. Enter:

   - **Email or username:** `admin`  
   - **Password:** `AdminMonitor2024`  

   (or whatever you set in `.env`)

5. Click **Log in**  
6. If Grafana asks you to change the password on first login:
   - Either set a new one you will remember  
   - Or click **Skip** / use the same password for local demos  

You are now inside Grafana.

---

## Step 6 — Open the dashboards

1. In the left sidebar, click the **four-square Dashboards** icon  
2. Open folder **Monitoring** (or **Browse**)  
3. Open these dashboards:

| Dashboard | What it shows |
|-----------|----------------|
| **System Overview** | CPU, memory, disk, network, containers |
| **Application Metrics** | Request rate, errors, latency, orders, cache |
| **Database Metrics (MySQL + MongoDB)** | DB uptime, connections, queries |
| **Logs & Metrics Correlation** | Metrics + Loki logs together |

4. Top-right: set time range to **Last 15 minutes** or **Last 1 hour**  
5. Refresh: **10s** or **15s** (already set on most dashboards)

### If graphs are empty

Generate traffic:

```powershell
.\scripts\generate-load.ps1 -Requests 80
```

Or open **http://localhost:8080** and click **Burst 20 requests**.

Wait 30–60 seconds, then refresh Grafana.

---

## Step 7 — Change username / password later

### Option A — Edit `.env` (best for full reset)

1. Stop stack:

```powershell
docker compose down
```

2. Edit `.env` passwords  

3. Remove Grafana volume so admin password is re-applied:

```powershell
docker volume rm prometheus-3131windows-amd64_grafana_data
```

(Volume name may differ — list with `docker volume ls | findstr grafana`)

4. Start again:

```powershell
.\scripts\start.ps1
```

### Option B — Change password inside Grafana UI

1. Click your avatar (bottom-left) → **Profile**  
2. **Change password**  
3. Or: **Administration → Users** to create more users and roles  
   - **Admin** — full control  
   - **Editor** — edit dashboards  
   - **Viewer** — read-only  

### Create a user in the UI

1. Log in as admin  
2. **Administration** (gear / shield) → **Users** → **New user**  
3. Set name, username, email, password  
4. Assign role **Viewer** or **Editor**

---

## Step 8 — Explore metrics in Prometheus

1. Open **http://localhost:9090**  
2. **Status → Targets** — all jobs should be **UP** (green)  
3. **Graph** tab — try queries:

```promql
up
```

```promql
rate(http_requests_total[5m])
```

```promql
100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```

```promql
mysql_up
```

```promql
mongodb_up
```

---

## Step 9 — Alerts

### See alerts in the browser (no Slack needed)

1. Open **http://localhost:9999** — Alert Logger UI  
2. Open **http://localhost:9093** — Alertmanager  
3. In Prometheus: **http://localhost:9090/alerts**

### Optional: Slack notifications

1. Create a Slack Incoming Webhook: https://api.slack.com/messaging/webhooks  
2. Put it in `.env`:

```env
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/your-workspace-id/your-channel-id/your-webhook-token
SLACK_CHANNEL=#alerts
```

3. Render config and restart:

```powershell
.\scripts\configure-alerts.ps1
docker compose restart alertmanager
```

### Optional: Email notifications

In `.env` (Gmail example — use an [App Password](https://support.google.com/accounts/answer/185833)):

```env
SMTP_SMARTHOST=smtp.gmail.com:587
SMTP_FROM=you@gmail.com
SMTP_USERNAME=you@gmail.com
SMTP_PASSWORD=your-16-char-app-password
ALERT_EMAIL_TO=oncall@example.com
```

Then:

```powershell
.\scripts\configure-alerts.ps1
docker compose restart alertmanager
```

---

## Step 10 — Logs (Loki) in Grafana

1. In Grafana: left menu → **Explore** (compass icon)  
2. Top data source dropdown: choose **Loki**  
3. Query example:

```logql
{compose_service="app"}
```

```logql
{compose_service=~"app|nginx|mysql"}
```

4. Or open dashboard **Logs & Metrics Correlation**

---

## Step 11 — Daily usage cheat sheet

| I want to… | Do this |
|------------|---------|
| Start everything | `.\scripts\start.ps1` |
| Stop everything | `docker compose down` |
| See container status | `.\scripts\status.ps1` |
| Open Grafana | http://localhost:3001 |
| Login | `admin` / `AdminMonitor2024` |
| Make pretty charts | Open **Monitoring** dashboards |
| Create load | `.\scripts\generate-load.ps1` |
| Check scrapes | http://localhost:9090/targets |
| See fired alerts | http://localhost:9999 |
| Change passwords | Edit `.env` + recreate grafana volume |

---

## All important URLs

| Service | URL | Auth |
|---------|-----|------|
| **Grafana** | http://localhost:3001 | `admin` / `AdminMonitor2024` |
| Demo website | http://localhost:8080 | none |
| Demo API metrics | http://localhost:3000/metrics | none |
| Prometheus | http://localhost:9090 | none (local only) |
| Alertmanager | http://localhost:9093 | none (local only) |
| Alert Logger | http://localhost:9999 | none |
| Node exporter | http://localhost:9100/metrics | none |
| MySQL exporter | http://localhost:9104/metrics | none |
| Mongo exporter | http://localhost:9216/metrics | none |
| MongoDB (host) | localhost:27018 | root / RootMongo2024 (port 27018 avoids clashing with other local Mongo) |

> **Security:** On a public server, do **not** expose Prometheus/exporters without a firewall, VPN, or reverse-proxy auth. Only publish Grafana (HTTPS + strong password).

---

## Production hardening checklist

1. Change all passwords in `.env`  
2. Set `GRAFANA_ROOT_URL=https://grafana.yourdomain.com`  
3. Put Grafana behind Nginx/Traefik with **TLS certificates**  
4. Firewall: allow only 80/443 publicly  
5. Configure Slack/email alerts (`configure-alerts.ps1`)  
6. Restrict Docker ports — remove public binds for `9100`, `9104`, `9090`, etc.  
7. Regularly `docker compose pull` and restart for security updates  

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Can't connect to Docker | Start Docker Desktop; wait until engine is running |
| Port in use | Stop old `prometheus.exe` or other apps using 3001/9090 |
| Grafana login fails | Use values from `.env`; or reset volume (Step 7A) |
| Targets DOWN | `docker compose logs <service>` e.g. `docker compose logs mysql` |
| Empty graphs | Run load script; wait 1 minute; check time range in Grafana |
| MySQL exporter down | Wait for MySQL healthy; `docker compose restart mysqld-exporter` |
| Password in `.env` ignored | Grafana only sets admin password on **first** start of empty volume |

```powershell
# Reset Grafana completely (wipes Grafana settings/dashboards custom edits)
docker compose stop grafana
docker compose rm -f grafana
docker volume ls
# delete the grafana volume name you see, then:
docker compose up -d grafana
```

---

## What each part does (short)

- **Prometheus** — collects metrics every 15s  
- **Exporters** — expose system / Nginx / MySQL / Mongo metrics  
- **Demo app** — custom business metrics (`/metrics`)  
- **Grafana** — graphs and dashboards (you log in here)  
- **Alertmanager** — routes alerts  
- **Alert logger** — shows alerts in a simple web page  
- **Loki + Promtail** — log aggregation next to metrics  

You mainly live in **Grafana** day to day: login → dashboards → explore.
