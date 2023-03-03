apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mssql-exporter-standalone-{{VERSION}}
  namespace: mssql
spec:
  serviceName: mssql-exporter-standalone-{{VERSION}}
  replicas: 1
  selector:
    matchLabels:
      app: mssql-exporter-standalone-{{VERSION}}
  template:
    metadata:
      annotations:
        telegraf.influxdata.com/interval: 1s
        telegraf.influxdata.com/inputs: |+
          [[inputs.cpu]]
            percpu = false
            totalcpu = true
            collect_cpu_time = true
            report_active = true

          [[inputs.disk]]
            ignore_fs = ["tmpfs", "devtmpfs", "devfs", "iso9660", "overlay", "aufs", "squashfs"]

          [[inputs.diskio]]

          [[inputs.kernel]]

          [[inputs.mem]]

          [[inputs.processes]]

          [[inputs.system]]
            fielddrop = ["uptime_format"]

          [[inputs.net]]
            ignore_protocol_stats = true

          [[inputs.procstat]]
          ## pattern as argument for pgrep (ie, pgrep -f <pattern>)
            pattern = "exporter"
        telegraf.influxdata.com/class: opentsdb
        telegraf.influxdata.com/env-fieldref-NAMESPACE: metadata.namespace
        telegraf.influxdata.com/limits-cpu: '300m'
        telegraf.influxdata.com/limits-memory: '300Mi'
      labels:
        app: mssql-exporter-standalone-{{VERSION}}
        exporter_object: mssql
        object_mode: standalone
        object_version: {{VERSION}}
        pod_type: exporter
    spec:
      shareProcessNamespace: true
      volumes:
        - name: mssql-config
          configMap:
            name: mssql-config
        - name: mssql-collector
          configMap:
            name: mssql-collector
      containers:
      - name: mssql-exporter-standalone-{{VERSION}}
        image: registry-svc:25000/library/mssql-exporter:latest
        imagePullPolicy: Always
        securityContext:
          allowPrivilegeEscalation: false
          runAsUser: 0
        args:
          - -config.file /sql/sql_config.yaml
          - -config.data-source-name 'sqlserver://SA:Weops123!@mssqlserver-{{VERSION}}.mssql:1433'
        volumeMounts:
        - mountPath: /sql/sql_config.yaml
          name: mssql-config
        - mountPath: /sql/mssql.collector.yaml
          name: mssql-collector
        resources:
          requests:
            cpu: 100m
            memory: 100Mi
          limits:
            cpu: 300m
            memory: 300Mi
        ports:
        - containerPort: 9121

---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: mssql-exporter-standalone-{{VERSION}}
  name: mssql-exporter-standalone-{{VERSION}}
  namespace: mssql
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "9121"
    prometheus.io/path: '/metrics'
spec:
  ports:
  - port: 9121
    protocol: TCP
    targetPort: 9121
  selector:
    app: mssql-exporter-standalone-{{VERSION}}
