apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: sql-exporter-{{SQL_OBJECT}}
  namespace: sql-exporter
spec:
  serviceName: sql-exporter-{{SQL_OBJECT}}
  replicas: 1
  selector:
    matchLabels:
      app: sql-exporter-{{SQL_OBJECT}}
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
        app: sql-exporter-{{SQL_OBJECT}}
        exporter_type: sql-exporter
        pod_type: exporter
    spec:
      nodeSelector:
        node-role: worker
      shareProcessNamespace: true
      volumes:
        - name: {{SQL_OBJECT}}-sql-config
          configMap:
            name: {{SQL_OBJECT}}-sql-config
      containers:
      - name: sql-exporter-{{SQL_OBJECT}}
        image: registry-svc:25000/library/sql-exporter-{{SQL_OBJECT}}:latest
        imagePullPolicy: Always
        envFrom:
          - configMapRef:
              name: {{SQL_OBJECT}}-dsn
        securityContext:
          allowPrivilegeEscalation: false
          runAsUser: 0
        args:
          - --config.file=/collector/{{SQL_OBJECT}}_config.yaml
        volumeMounts:
        - mountPath: /collector
          name: {{SQL_OBJECT}}-sql-config
        resources:
          requests:
            cpu: 100m
            memory: 100Mi
          limits:
            cpu: 300m
            memory: 300Mi
        ports:
        - containerPort: 9399

---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: sql-exporter-{{SQL_OBJECT}}
  name: sql-exporter-{{SQL_OBJECT}}
  namespace: sql-exporter
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "9399"
    prometheus.io/path: '/metrics'
spec:
  ports:
  - port: 9399
    protocol: TCP
    targetPort: 9399
  selector:
    app: sql-exporter-{{SQL_OBJECT}}
