# Grafana for Render — same version as docker-compose, provisioned via files.
FROM grafana/grafana:11.5.2

# The base image runs as grafana (uid 472); switch to root for the build steps.
USER root
COPY provisioning/ /etc/grafana/provisioning/
COPY dashboards/ /var/lib/grafana/dashboards/
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh \
    && chown -R 472:472 /etc/grafana/provisioning /var/lib/grafana/dashboards

USER 472
ENTRYPOINT []
CMD ["/entrypoint.sh"]
