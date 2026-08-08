# Alertmanager for Render — alpine base (shell for env substitution),
# binary from the official image.
FROM prom/alertmanager:v0.28.1 AS am

FROM alpine:3.20
RUN apk add --no-cache ca-certificates
COPY --from=am /bin/alertmanager /bin/alertmanager

COPY alertmanager.yml.tpl /etc/alertmanager/alertmanager.yml.tpl
COPY templates/ /etc/alertmanager/templates/
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 9093
ENTRYPOINT ["/entrypoint.sh"]
