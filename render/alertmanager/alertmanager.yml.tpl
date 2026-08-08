# Alertmanager for Render — webhook receivers point at the deployed
# alert-logger service (__ALERT_LOGGER_URL__ substituted by entrypoint.sh).
global:
  resolve_timeout: 5m

templates:
  - /etc/alertmanager/templates/*.tmpl

inhibit_rules:
  - source_matchers:
      - severity="critical"
    target_matchers:
      - severity="warning"
    equal: [alertname, instance]

route:
  receiver: default-receiver
  group_by: [alertname, severity, team]
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 4h
  routes:
    - matchers:
        - severity="critical"
      receiver: critical-receiver
      continue: true
    - matchers:
        - team="application"
      receiver: app-team
    - matchers:
        - team="infrastructure"
      receiver: infra-team
    - matchers:
        - team="database"
      receiver: db-team

receivers:
  - name: default-receiver
    webhook_configs:
      - url: "__ALERT_LOGGER_URL__/webhook"
        send_resolved: true

  - name: critical-receiver
    webhook_configs:
      - url: "__ALERT_LOGGER_URL__/webhook"
        send_resolved: true

  - name: app-team
    webhook_configs:
      - url: "__ALERT_LOGGER_URL__/webhook"
        send_resolved: true

  - name: infra-team
    webhook_configs:
      - url: "__ALERT_LOGGER_URL__/webhook"
        send_resolved: true

  - name: db-team
    webhook_configs:
      - url: "__ALERT_LOGGER_URL__/webhook"
        send_resolved: true
