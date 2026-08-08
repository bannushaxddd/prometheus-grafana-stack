# 4) Postmortem-style writeup: debugging high latency

Use this as a **portfolio case study** and interview story.  
It shows how you *think* with dashboards — not only that you installed tools.

You can paste a shortened version into GitHub README or Notion portfolio.

---

## Title

**Incident case study: Investigating elevated API latency with Prometheus & Grafana**

---

## Summary (executive)

Users (or synthetic load) experienced slower API responses. Using the observability stack, latency was confirmed via p95/p99 histograms, correlated with application and infrastructure signals, and traced to a slow application path rather than CPU exhaustion or database saturation. Mitigation included reducing expensive endpoints under load and validating recovery on dashboards.

*(In a real job, replace the root cause with whatever you actually found.)*

---

## Impact

| Field | Example |
|-------|---------|
| Severity | Medium (degraded performance, not full outage) |
| User impact | Higher response times on order/API endpoints |
| Duration | ~N minutes (lab: duration of synthetic load) |
| Detection | Grafana Application Metrics + Prometheus alert `HighRequestLatency` |
| Customer report? | No (detected via metrics) — this is the point of monitoring |

---

## Detection

### How we would notice

1. **Alert (ideal):** `HighRequestLatency`  
   - PromQL: p95 of `http_request_duration_seconds` > 1s for 3 minutes  
2. **Dashboard:** Grafana → **Application Metrics**  
   - Panel: *Request Latency (p50 / p95 / p99)* trending up  
3. **Optional Slack:** Alertmanager posts to `#alerts`

### First 2 minutes (triage checklist)

Open these **in parallel**:

1. **Application Metrics** dashboard  
   - Request rate  
   - Error rate %  
   - Latency p95/p99  
   - In-flight requests  
2. **System Overview**  
   - CPU / memory / disk / network  
3. **Database Metrics**  
   - MySQL/Mongo up  
   - Connection counts  
4. **Logs & Metrics Correlation** (Loki)  
   - `{compose_service="app"}` around the incident window  
5. Prometheus **Targets** — anything DOWN?

---

## Investigation timeline (example lab narrative)

### T+0 — Signal

- p95 latency rose from ~50ms to >1s  
- Request rate increased after load generation / `/api/slow` traffic  
- Error rate remained low (not a 500 storm)

**Conclusion so far:** performance degradation, not total failure.

### T+2m — Isolate the layer

| Hypothesis | Dashboard / query | Result (example) |
|------------|-------------------|------------------|
| Host CPU saturated? | System Overview CPU % | CPU elevated but not pegged at 100% |
| Memory pressure / OOM? | Memory % + app logs | No OOM; memory stable |
| DB down / slow? | `mysql_up`, `mongodb_up`, connections | DBs UP; connections normal |
| Network / proxy? | Nginx active connections, request rate | Proxy healthy |
| App endpoint slow? | Latency histogram + route labels | Latency concentrated on slow routes |
| Dependency unreachable? | `app_dependency_up` | MySQL/Mongo reachable |

**Conclusion:** issue is in the **application path**, not infra collapse.

### T+5m — Confirm with PromQL

```promql
# Overall p95 latency
histogram_quantile(0.95,
  sum by (le) (rate(http_request_duration_seconds_bucket[5m]))
)

# Latency by route (if labels present)
histogram_quantile(0.95,
  sum by (le, route) (rate(http_request_duration_seconds_bucket[5m]))
)

# Are 5xx rising?
sum(rate(http_requests_total{status_code=~"5.."}[5m]))
/
sum(rate(http_requests_total[5m]))
```

### T+7m — Logs correlation

Loki:

```logql
{compose_service="app"} |= "slow"
```

or broader:

```logql
{compose_service=~"app|nginx"}
```

Look for timestamps aligning with latency spike.

---

## Root cause (lab version — honest)

In this project, elevated latency can be induced by:

1. **Synthetic slow endpoint** `/api/slow` (intentional 1.5–2.5s delay)  
2. **Load burst** overwhelming the single Node.js process  
3. Occasional intentional **~5% failed orders** (errors, not always latency)

**Root cause statement (lab):**

> Latency increased because the application served deliberately slow requests and/or high concurrency on a single instance without horizontal scaling. Infrastructure and databases remained healthy.

**Root cause statement template (real production):**

> Latency increased because [deploy / query / lock / downstream timeout / GC / thread pool exhaustion]. Confirmed by [metric X] and [log Y]. Mitigated by [rollback / scale / index / timeout change].

---

## Mitigation

### Immediate

- Stop generating load / block abusive path  
- Scale app replicas (in real k8s: `kubectl scale`)  
- Restart unhealthy instance if wedged  
- Feature-flag or rate-limit expensive endpoint  

### Lab commands

```bash
# stop load generators
# scale is single-container here — restart app if needed:
docker compose restart app

# verify recovery
curl -s http://localhost:3000/health
```

Watch Grafana: p95 should fall back toward baseline within 1–5 minutes.

---

## Verification (how we know it’s fixed)

- [ ] p95 latency back under threshold (e.g. < 200–300ms for normal routes)  
- [ ] `HighRequestLatency` alert **resolved**  
- [ ] Error rate normal  
- [ ] No DB connection saturation  
- [ ] Slack resolved notification received (if configured)

---

## What monitoring made possible

Without this stack:

- We might only learn from user complaints  
- We would SSH and guess (CPU? disk? app?)  

With this stack:

- **Detection:** alert + latency panel  
- **Localization:** system vs app vs DB in minutes  
- **Evidence:** PromQL + logs with timestamps  
- **Communication:** Slack to the team  

That is the business value.

---

## Action items / follow-ups (sounds senior in interviews)

1. Add per-route latency SLO dashboard (p95 < 300ms for `/api/orders`)  
2. Alert only on **user-facing** routes, not `/metrics`  
3. Add tracing (OpenTelemetry → Tempo/Jaeger) for multi-service latency  
4. Autoscale app on high `http_requests_in_flight` or CPU  
5. Recording rules already compute p95 — use them in alerts for cheaper queries  
6. Write a runbook link in the alert annotation (`runbook_url`)

Example improved annotation:

```yaml
annotations:
  summary: "High p95 request latency"
  description: "p95 is {{ $value }}s"
  runbook_url: "https://github.com/YOU/monitoring-stack/blob/main/docs/04-POSTMORTEM-HIGH-LATENCY.md"
```

---

## How to demo this live (5 minutes)

1. Open Grafana Application Metrics + System Overview  
2. Run:

```powershell
.\scripts\generate-load.ps1 -Requests 30
# also hit slow endpoint in a loop from demo UI
```

3. Show latency panels rising  
4. Walk the hypothesis table out loud  
5. Show logs in Explore → Loki  
6. Stop load → show recovery  
7. (Optional) show Slack alert  

---

## 45-second interview story (STAR)

**Situation:**  
“API latency spiked in our monitored environment.”

**Task:**  
“I needed to determine whether it was infrastructure, database, or application-related and restore performance.”

**Action:**  
“I used Grafana latency histograms and error rates, checked node CPU/memory, verified MySQL/Mongo were up, and correlated app logs in Loki. PromQL showed the regression on application request duration while databases stayed healthy.”

**Result:**  
“I identified an application-level slow path under load, mitigated by stopping the abusive traffic pattern and restarting the service, then confirmed p95 returned to baseline. I documented a runbook so the next incident is faster.”

---

## One-line takeaway

> Monitoring doesn’t fix latency by itself — it turns “the site feels slow” into a **measurable, localizable, evidence-based** investigation in minutes.
