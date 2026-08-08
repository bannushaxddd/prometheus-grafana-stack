# Grafana for Render — same version as docker-compose, provisioned via files.
FROM grafana/grafana:11.5.2

COPY provisioning/ /etc/grafana/provisioning/
COPY dashboards/ /var/lib/grafana/dashboards/
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh \
    && chown -R grafana:grafana /etc/grafana/provisioning /var/lib/grafana/dashboards

ENTRYPOINT []
CMD ["/entrypoint.sh"]
