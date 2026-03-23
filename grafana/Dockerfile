FROM grafana/grafana:latest

# Copy provisioning configs (datasources & dashboard providers)
COPY provisioning /etc/grafana/provisioning

# Copy dashboard JSON files
COPY dashboards /var/lib/grafana/dashboards

# Expose Grafana port
EXPOSE 3000
