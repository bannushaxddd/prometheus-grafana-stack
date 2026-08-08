# Prometheus + Grafana Monitoring Stack

Full infrastructure monitoring: **Prometheus**, **Grafana**, **Alertmanager**, **Loki**, **MySQL**, **MongoDB**, system/app exporters, and a demo Node.js app with custom metrics.

## Grafana login (default)

| | |
|---|---|
| **URL** | http://localhost:3001 |
| **Username** | `admin` |
| **Password** | `AdminMonitor2024` |

Viewer (read-only): `viewer` / `ViewerMonitor2024`

Passwords are set in **`.env`**. Full walkthrough: **[HOW_TO_USE.md](./HOW_TO_USE.md)**.

---

## Quick start

1. Start **Docker Desktop** (wait until engine is running)
2. In PowerShell:

```powershell
cd D:\prometheus-3.13.1.windows-amd64
.\scripts\start.ps1
```

3. Open http://localhost:3001 → login with `admin` / `AdminMonitor2024`
4. Dashboards → **Monitoring** folder
5. Generate traffic: `.\scripts\generate-load.ps1`

---

## What's included

| Component | Port | Role |
|-----------|------|------|
| Grafana | 3001 | Dashboards (login required) |
| Prometheus | 9090 | Metrics + PromQL + rules |
| Demo app (Nginx) | 8080 | Sample traffic UI |
| Demo API | 3000 | Custom `/metrics` |
| Alertmanager | 9093 | Alert routing |
| Alert Logger | 9999 | See alerts without Slack |
| MySQL + exporter | 3306 / 9104 | Database metrics |
| MongoDB + exporter | 27017 / 9216 | Database metrics |
| Node exporter | 9100 | CPU, memory, disk, network |
| cAdvisor | 8081 | Container metrics |
| Loki | 3100 | Logs |

### Dashboards (auto-loaded)

- System Overview  
- Application Metrics  
- Database Metrics (MySQL + MongoDB)  
- Logs & Metrics Correlation  

### Advanced features

- Alerting rules + Alertmanager (+ optional Slack/email via `.\scripts\configure-alerts.ps1`)
- Recording rules for faster queries  
- File-based service discovery (`prometheus/file_sd/`)  
- Loki log correlation in Grafana  
- Custom app instrumentation (`app/server.js`)

---

## Scripts

| Script | Purpose |
|--------|---------|
| `.\scripts\start.ps1` | Build, start, print logins, create viewer user |
| `.\scripts\status.ps1` | Health + Prometheus target check |
| `.\scripts\generate-load.ps1` | Fill dashboards with sample traffic |
| `.\scripts\configure-alerts.ps1` | Enable Slack/email from `.env` |

---

## Optional Slack / email alerts

Edit `.env`, then:

```powershell
.\scripts\configure-alerts.ps1
docker compose restart alertmanager
```

Details in [HOW_TO_USE.md](./HOW_TO_USE.md) Step 9.

---

## Project layout

```
docker-compose.yml
.env / .env.example
HOW_TO_USE.md
app/                  # Node.js + custom Prometheus metrics
nginx/
mysql/init/           # exporter user + sample data
alert-logger/         # webhook UI for alerts
prometheus/           # scrape config + rules + file_sd
alertmanager/
grafana/              # provisioning + dashboards
loki/  promtail/
scripts/
```

---

## Stop / reset

```powershell
docker compose down          # keep data volumes
docker compose down -v       # wipe all metrics/DB data
```

---

## Real-world upgrades (job portfolio)

Step-by-step guides in **`docs/`**:

1. [Deploy on DigitalOcean / AWS](./docs/01-CLOUD-DEPLOY.md)
2. [Grafana behind HTTPS (Caddy + Let’s Encrypt)](./docs/02-HTTPS-GRAFANA.md)
3. [Real Slack alerts](./docs/03-SLACK-ALERTS.md)
4. [High-latency debugging writeup / interview story](./docs/04-POSTMORTEM-HIGH-LATENCY.md)

Overview: [docs/README.md](./docs/README.md)

## Security (production)

- Change every password in `.env`
- Do not expose exporters/Prometheus publicly
- Put Grafana on HTTPS behind a reverse proxy
- Configure real Slack/email receivers
