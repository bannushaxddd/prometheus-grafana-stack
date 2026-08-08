# Prometheus for Render — alpine base (shell for env substitution),
# binary + CA certs from the official image.
FROM prom/prometheus:v3.2.1 AS prom

FROM alpine:3.20
RUN apk add --no-cache ca-certificates
COPY --from=prom /bin/prometheus /bin/prometheus

COPY prometheus.yml.tpl /etc/prometheus/prometheus.yml.tpl
COPY rules/ /etc/prometheus/rules/
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /prometheus
EXPOSE 9090
ENTRYPOINT ["/entrypoint.sh"]
