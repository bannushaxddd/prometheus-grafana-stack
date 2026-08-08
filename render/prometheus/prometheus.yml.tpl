# Render deployment — generated from prometheus.yml.tpl by entrypoint.sh.
# Scrapes the app/alertmanager/grafana services over their public HTTPS URLs.
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  scrape_timeout: 10s
  external_labels:
    cluster: "render"
    env: "production"
    monitor: "prometheus-stack"

alerting:
  alertmanagers:
    - scheme: https
      static_configs:
        - targets:
            - __ALERTMANAGER_HOST__:443
      timeout: 10s

rule_files:
  - /etc/prometheus/rules/*.yml

scrape_configs:
  - job_name: "prometheus"
    static_configs:
      - targets: ["localhost:__PROMETHEUS_PORT__"]
        labels:
          service: "prometheus"
          component: "monitoring"

  - job_name: "app"
    scheme: https
    metrics_path: /metrics
    static_configs:
      - targets: ["__APP_HOST__:443"]
        labels:
          service: "monitored-app"
          component: "application"
          app: "demo-api"

  - job_name: "alertmanager"
    scheme: https
    metrics_path: /metrics
    static_configs:
      - targets: ["__ALERTMANAGER_HOST__:443"]
        labels:
          service: "alertmanager"
          component: "monitoring"

  - job_name: "grafana"
    scheme: https
    metrics_path: /metrics
    static_configs:
      - targets: ["__GRAFANA_HOST__:443"]
        labels:
          service: "grafana"
          component: "monitoring"
