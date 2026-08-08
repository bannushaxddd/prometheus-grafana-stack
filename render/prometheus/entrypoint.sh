#!/bin/sh
# Render injects PORT (proxy target) and service URLs via fromService env vars.
set -e

host_of() {
  echo "$1" | sed -E 's#^https?://##; s#/.*##'
}

APP_HOST=$(host_of "$APP_URL")
ALERTMANAGER_HOST=$(host_of "$ALERTMANAGER_URL")
GRAFANA_HOST=$(host_of "$GRAFANA_URL")
PROM_PORT="${PORT:-9090}"

sed -e "s|__APP_HOST__|$APP_HOST|g" \
    -e "s|__ALERTMANAGER_HOST__|$ALERTMANAGER_HOST|g" \
    -e "s|__GRAFANA_HOST__|$GRAFANA_HOST|g" \
    -e "s|__PROMETHEUS_PORT__|$PROM_PORT|g" \
    /etc/prometheus/prometheus.yml.tpl > /etc/prometheus/prometheus.yml

exec /bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/prometheus \
  --web.enable-lifecycle \
  --web.listen-address=":$PROM_PORT"
