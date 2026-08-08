apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    uid: prometheus
    access: proxy
    url: __PROMETHEUS_URL__
    isDefault: true
    editable: true
    jsonData:
      timeInterval: 15s
      httpMethod: POST
