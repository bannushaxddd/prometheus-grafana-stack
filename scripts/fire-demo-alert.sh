#!/usr/bin/env bash
# Temporarily add a always-firing demo alert, reload Prometheus, wait, then remove it.
# Usage: bash scripts/fire-demo-alert.sh

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RULES="$ROOT/prometheus/rules/alerting.yml"
MARKER="# DEMO_SLACK_ALERT_START"

cleanup() {
  if grep -q "$MARKER" "$RULES" 2>/dev/null; then
    # Remove demo block
    awk -v m="$MARKER" '
      $0 ~ m {skip=1; next}
      $0 ~ /DEMO_SLACK_ALERT_END/ {skip=0; next}
      !skip {print}
    ' "$RULES" > "$RULES.tmp" && mv "$RULES.tmp" "$RULES"
    echo "Removed demo alert from rules"
    curl -s -X POST http://localhost:9090/-/reload || docker compose -f "$ROOT/docker-compose.yml" restart prometheus || true
  fi
}
trap cleanup EXIT

if grep -q "$MARKER" "$RULES"; then
  echo "Demo alert already present"
else
  cat >> "$RULES" <<'EOF'

  # DEMO_SLACK_ALERT_START
  - name: demo_slack
    interval: 15s
    rules:
      - alert: DemoSlackAlert
        expr: vector(1)
        for: 0m
        labels:
          severity: warning
          team: infrastructure
        annotations:
          summary: "Demo alert to verify Slack integration"
          description: "If you see this in Slack/Alertmanager, routing works. Auto-removed by fire-demo-alert.sh."
  # DEMO_SLACK_ALERT_END
EOF
  echo "Added DemoSlackAlert rule"
fi

curl -s -X POST http://localhost:9090/-/reload || docker compose restart prometheus
echo "Reloaded Prometheus. Waiting 45s for alert to fire..."
sleep 45
echo "Check:"
echo "  - Prometheus:   http://localhost:9090/alerts"
echo "  - Alertmanager: http://localhost:9093"
echo "  - Alert logger: http://localhost:9999"
echo "  - Slack #alerts"
echo "Cleaning up demo rule on exit..."
