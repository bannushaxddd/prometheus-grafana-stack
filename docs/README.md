# Real-world upgrades (portfolio / interview)

Do these **in order**. Each one makes the project much stronger for junior/mid DevOps interviews.

| # | Guide | Time | You get |
|---|--------|------|---------|
| 1 | [01-CLOUD-DEPLOY.md](./01-CLOUD-DEPLOY.md) | 1–2 hours | Stack on DigitalOcean or AWS |
| 2 | [02-HTTPS-GRAFANA.md](./02-HTTPS-GRAFANA.md) | 30–60 min | `https://` Grafana with Let’s Encrypt |
| 3 | [03-SLACK-ALERTS.md](./03-SLACK-ALERTS.md) | 30–45 min | Real Slack notifications |
| 4 | [04-POSTMORTEM-HIGH-LATENCY.md](./04-POSTMORTEM-HIGH-LATENCY.md) | 30 min write + 5 min demo | Case study + interview story |

## Suggested weekend plan

**Saturday**

1. Create $6–12 droplet / EC2  
2. Copy project, `docker compose up -d --build`  
3. Screenshots: public IP + dashboards  

**Sunday morning**

4. Point domain → server, enable Caddy HTTPS  
5. Slack webhook + demo alert  

**Sunday afternoon**

6. Run latency debug demo  
7. Polish postmortem writeup + GitHub README  
8. Record 3–5 min Loom walkthrough  

## Interview one-liners

- Cloud: *“Deployed on Ubuntu VM with Docker Compose and least-privilege firewall.”*  
- HTTPS: *“TLS at reverse proxy, Grafana only public entrypoint.”*  
- Slack: *“Alertmanager routes firing alerts to Slack with resolve notifications.”*  
- Postmortem: *“Used RED/USE-style dashboards to isolate app latency vs infra/DB.”*
