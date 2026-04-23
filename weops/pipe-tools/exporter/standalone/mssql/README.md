# MSSQL Probe Standalone

This directory is the dedicated standalone deployment for MSSQL probes.

It targets the one-click deployed MSSQL instances in namespace `mssql` and uses the bootstrap monitoring account created during deployment:

- user: `monitoring_user`
- password: `Weops123!`

Targets:

- `mssqlserver-2022.mssql`
- `mssqlserver-2019.mssql`
- `mssql-2017-mssql-linux.mssql`

Apply all resources with:

```bash
kubectl apply -k weops/pipe-tools/exporter/standalone/mssql
```

Check the pods with:

```bash
kubectl get pods -n sql-exporter | grep sql-exporter-mssql-probe
```
