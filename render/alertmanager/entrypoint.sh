#!/bin/sh
# Point all webhook receivers at the deployed alert-logger service.
set -e

sed "s|__ALERT_LOGGER_URL__|$ALERT_LOGGER_URL|g" \
    /etc/alertmanager/alertmanager.yml.tpl \
    > /etc/alertmanager/alertmanager.yml

exec /bin/alertmanager \
  --config.file=/etc/alertmanager/alertmanager.yml \
  --web.listen-address=":${PORT:-9093}"
