/**
 * Simple Alertmanager webhook receiver.
 * View fired alerts at http://localhost:9999
 */
const express = require('express');

const app = express();
const PORT = process.env.PORT || 9999;
const MAX = 200;
const alerts = [];

app.use(express.json({ limit: '2mb' }));

app.post('/webhook', (req, res) => {
  const payload = req.body || {};
  const entry = {
    receivedAt: new Date().toISOString(),
    status: payload.status,
    receiver: payload.receiver,
    groupLabels: payload.groupLabels,
    commonLabels: payload.commonLabels,
    commonAnnotations: payload.commonAnnotations,
    alertCount: (payload.alerts || []).length,
    alerts: (payload.alerts || []).map((a) => ({
      status: a.status,
      labels: a.labels,
      annotations: a.annotations,
      startsAt: a.startsAt,
      endsAt: a.endsAt,
    })),
  };

  alerts.unshift(entry);
  if (alerts.length > MAX) alerts.length = MAX;

  console.log(
    `[ALERT] ${entry.status} receiver=${entry.receiver} count=${entry.alertCount} ` +
      `name=${entry.commonLabels?.alertname || '?'} severity=${entry.commonLabels?.severity || '?'}`
  );

  res.status(200).json({ ok: true });
});

app.get('/api/alerts', (_req, res) => {
  res.json({ total: alerts.length, alerts });
});

app.get('/health', (_req, res) => res.json({ status: 'ok' }));

app.get('/', (_req, res) => {
  res.type('html').send(`<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Alert Logger</title>
  <style>
    :root { font-family: system-ui, sans-serif; background: #0f1419; color: #e8eaed; }
    body { max-width: 960px; margin: 2rem auto; padding: 0 1rem; }
    h1 { color: #e6522c; }
    .meta { color: #9aa0a6; margin-bottom: 1rem; }
    .card {
      background: #1a2332; border-radius: 10px; padding: 1rem 1.25rem;
      margin: 0.75rem 0; border-left: 4px solid #5f6368;
    }
    .card.firing { border-left-color: #ea4335; }
    .card.resolved { border-left-color: #34a853; }
    .sev { display: inline-block; padding: 0.1rem 0.5rem; border-radius: 4px; font-size: 0.8rem; }
    .sev.critical { background: #5c1a1a; color: #f28b82; }
    .sev.warning { background: #5c4a1a; color: #fdd663; }
    pre { white-space: pre-wrap; font-size: 0.8rem; background: #0d1117; padding: 0.75rem; border-radius: 6px; }
    button { background: #e6522c; color: #fff; border: 0; padding: 0.5rem 1rem; border-radius: 6px; cursor: pointer; }
  </style>
</head>
<body>
  <h1>Alert Logger</h1>
  <p class="meta">Webhook sink for Alertmanager. Auto-refreshes every 10s.
    Also open <a href="http://localhost:9093" style="color:#6cb6ff">Alertmanager UI</a>.</p>
  <button onclick="load()">Refresh</button>
  <div id="list"></div>
  <script>
    async function load() {
      const r = await fetch('/api/alerts');
      const data = await r.json();
      const el = document.getElementById('list');
      if (!data.alerts.length) {
        el.innerHTML = '<p class="meta">No alerts received yet. They appear when Prometheus rules fire.</p>';
        return;
      }
      el.innerHTML = data.alerts.map(a => {
        const sev = a.commonLabels?.severity || 'unknown';
        const name = a.commonLabels?.alertname || 'unknown';
        return \`<div class="card \${a.status || ''}">
          <div><strong>\${name}</strong>
            <span class="sev \${sev}">\${sev}</span>
            · \${a.status} · \${a.receivedAt}
          </div>
          <div class="meta">receiver: \${a.receiver || '-'} · alerts: \${a.alertCount}</div>
          <pre>\${JSON.stringify(a.alerts, null, 2)}</pre>
        </div>\`;
      }).join('');
    }
    load();
    setInterval(load, 10000);
  </script>
</body>
</html>`);
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Alert logger listening on :${PORT}`);
});
