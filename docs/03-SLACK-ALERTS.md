# 3) Send a real Slack alert

Goal: when Prometheus fires an alert, a Slack channel gets a message.  
This is the “ops team gets paged/notified” story.

---

## Architecture (what happens)

```
Prometheus rule fires
        │
        ▼
  Alertmanager
        │
        ├── webhook → alert-logger (always, for UI)
        └── slack   → #alerts channel (this guide)
```

---

## Step 1: Create a Slack Incoming Webhook

1. Open Slack in browser  
2. Go to: https://api.slack.com/apps  
3. **Create New App → From scratch**  
   - Name: `Prometheus Alerts`  
   - Workspace: your workspace  
4. Left menu → **Incoming Webhooks** → **On**  
5. **Add New Webhook to Workspace**  
6. Pick channel (create `#alerts` first if needed)  
7. Copy the webhook URL:

```text
https://hooks.slack.com/services/your-workspace-id/your-channel-id/your-webhook-token
```

**Treat this like a password.** Never commit it to public GitHub.

---

## Step 2: Put webhook in `.env`

On your machine or cloud VM:

```env
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/your-workspace-id/your-channel-id/your-webhook-token
SLACK_CHANNEL=#alerts
```

---

## Step 3: Render Alertmanager config

### On Windows (local stack)

```powershell
cd D:\prometheus-3.13.1.windows-amd64
.\scripts\configure-alerts.ps1
docker compose restart alertmanager
```

### On Linux cloud VM

```bash
cd /opt/monitoring
# If you only have the PowerShell script, use the bash helper:
bash scripts/configure-alerts.sh
docker compose restart alertmanager
docker compose logs alertmanager --tail 30
```

---

## Step 4: Test the webhook by itself

Before involving Prometheus, prove Slack works:

```bash
curl -X POST -H 'Content-type: application/json' \
  --data '{"text":"Test from monitoring stack - webhook OK"}' \
  "$SLACK_WEBHOOK_URL"
```

PowerShell:

```powershell
$u = "PASTE_WEBHOOK_URL"
Invoke-RestMethod -Method Post -Uri $u -ContentType "application/json" `
  -Body '{"text":"Test from monitoring stack - webhook OK"}'
```

You should see a message in `#alerts`.

---

## Step 5: Fire a real Prometheus → Slack alert

### Method A — easiest demo (recommended)

Temporarily make a guaranteed-firing rule.

Edit `prometheus/rules/alerting.yml` and add at the bottom of a group:

```yaml
      - alert: DemoSlackAlert
        expr: vector(1)
        for: 0m
        labels:
          severity: warning
          team: infrastructure
        annotations:
          summary: "Demo alert to verify Slack integration"
          description: "If you see this in Slack, Alertmanager routing works."
```

Reload Prometheus:

```bash
curl -X POST http://localhost:9090/-/reload
# or:
docker compose restart prometheus
```

Within ~30–60 seconds:

1. Prometheus → http://YOUR_HOST:9090/alerts → **DemoSlackAlert** firing  
2. Alertmanager → http://YOUR_HOST:9093 → alert visible  
3. Slack `#alerts` → message received  
4. Alert logger → http://YOUR_HOST:9999 → payload visible  

**Screenshot all four** for portfolio.

Then **remove** `DemoSlackAlert` so it does not fire forever, and reload again.

### Method B — realistic app alert

1. Stop the demo app:

```bash
docker compose stop app
```

2. Wait ~1–2 minutes for `ApplicationDown` / `InstanceDown`  
3. Slack should notify  
4. Start app again:

```bash
docker compose start app
```

5. Alert resolves (if `send_resolved: true`)

### Method C — high latency simulation

```bash
# hammer the slow endpoint
for i in $(seq 1 50); do curl -s http://localhost:8080/api/slow >/dev/null & done
wait
```

If `HighRequestLatency` threshold is met long enough (`for: 3m`), it fires.

---

## Step 6: What a good Slack message looks like

With our templates you should see roughly:

- Status: FIRING  
- Alert name  
- Severity  
- Summary / description  
- Instance / job labels  

If messages are empty/ugly, re-check `alertmanager/templates/default.tmpl` and restart Alertmanager.

---

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| No Slack message | Webhook URL wrong; re-test with curl |
| Alertmanager logs 403/404 from Slack | Webhook revoked; create a new one |
| Alert firing in Prometheus but not Slack | `configure-alerts` not run; AM using old yml |
| Slack works for curl but not alerts | Receiver missing `slack_configs`; restart AM |
| Too many messages | Increase `for:` / `repeat_interval`; route only critical to Slack |

```bash
docker compose logs alertmanager --tail 100
```

---

## Security notes

- Store webhook only in `.env` (not in git)  
- Prefer a dedicated `#alerts` channel  
- For real jobs: use Slack app auth or PagerDuty, not a shared webhook in chat history  

---

## Portfolio artifacts

1. Slack screenshot of FIRING alert  
2. Slack screenshot of RESOLVED (optional but impressive)  
3. Prometheus Alerts page  
4. Alertmanager page  
5. Short note: “Alert path: Prom rule → Alertmanager → Slack webhook”

---

## Interview line

> “I integrated Alertmanager with Slack via an incoming webhook, verified with a synthetic alert, and demonstrated a realistic ApplicationDown path by stopping a service and watching the notification fire and resolve.”
