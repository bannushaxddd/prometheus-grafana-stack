#!/bin/bash
# Render injects PORT + RENDER_EXTERNAL_URL; wire Grafana to both, then
# point the Prometheus datasource at the deployed prometheus service.
set -e

export GF_SERVER_HTTP_PORT="${PORT:-3000}"
export GF_SERVER_ROOT_URL="${RENDER_EXTERNAL_URL:-http://localhost:3000}"

sed "s|__PROMETHEUS_URL__|$PROMETHEUS_URL|g" \
    /etc/grafana/provisioning/datasources/datasources.yml.tpl \
    > /etc/grafana/provisioning/datasources/datasources.yml

exec /run.sh
