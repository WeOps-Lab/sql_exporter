## WeOps PolarDB PG SQL Exporter

### 功能

通过 SQL Exporter 连接 PolarDB PostgreSQL 兼容版数据库，执行 PolarDB 专有视图与标准 PostgreSQL 视图查询，并转换为 Prometheus 监控指标。

采集内容分两类：

- **PolarDB 专用增强指标**：基于 `polar_monitor` 扩展的 `polar_stat_*` 视图，覆盖存算分离架构特有的 PFS（共享存储）IO、按 backend 的 CPU/RSS/PFS 资源、以及活跃会话等待。
- **通用 PostgreSQL 健康指标**：基于标准 `pg_*` 视图，覆盖连接、事务、缓存、锁、容量、长事务、事务 ID 回卷、checkpoint/bgwriter、WAL 等日常告警所需信号。

### 采集来源

PolarDB 专用视图（来自 `polar_monitor` 扩展，默认安装在 `postgres` 库；扩展为按库安装，故 exporter 默认连接 `postgres` 库）：

- `polar_stat_io_info`
- `polar_stat_io_latency`
- `polar_stat_activity`

标准 PostgreSQL 视图：

- `pg_stat_database`、`pg_stat_activity`、`pg_locks`
- `pg_stat_bgwriter`、`pg_stat_wal`
- `pg_settings`、`pg_database`

如果目标库未安装 `polar_monitor` 扩展或连接到不含该扩展的库，PolarDB 专用 SQL 会采集失败，并通过 exporter 的 scrape error 指标暴露；标准 `pg_*` 指标不受影响。

### 参数说明

| 参数名 | 含义 | 是否必填 | 示例 |
| --- | --- | --- | --- |
| `SQL_EXPORTER_DB_TYPE` | 数据库类型 | 是 | `polardb_pg` |
| `SQL_EXPORTER_USER` | 数据库用户名 | 是 | `weops` |
| `SQL_EXPORTER_PASS` | 数据库密码 | 是 | `Weops123!` |
| `SQL_EXPORTER_HOST` | 数据库地址 | 是 | `127.0.0.1` |
| `SQL_EXPORTER_PORT` | 数据库端口 | 是 | `5432` |
| `SQL_EXPORTER_DB_NAME` | 数据库名称（不填默认 `postgres`，即 `polar_monitor` 视图所在库） | 否 | `postgres` |
| `COLLECTOR_REFS` | 采集器名称 | 否 | `polardb_pg_sql` |
| `SCRAPE_TIMEOUT` | 采集超时时间 | 否 | `10s` |
| `--collector.file` | 采集配置文件 | 是 | `polardb_pg.collector.yml` |
| `--web.listen-address` | exporter 监听地址 | 否 | `127.0.0.1:9601` |

### 权限建议

采集账号需要能连接到 `polar_monitor` 视图所在库（默认 `postgres`），并对监控视图具备查询权限。建议授予 `pg_monitor` 角色，以便完整读取 `pg_stat_activity` / `polar_stat_activity` 中其他会话的查询与资源列。

```sql
-- 完整可见性（推荐）
GRANT pg_monitor TO weops;

-- 或按视图最小授权
GRANT SELECT ON polar_stat_io_info TO weops;
GRANT SELECT ON polar_stat_io_latency TO weops;
GRANT SELECT ON polar_stat_activity TO weops;
```

不同 PolarDB PG 版本的视图与权限模型可能不同，请以实际环境为准。

### 指标列表

#### PolarDB 专用指标

| 指标名 | 含义 | 维度 |
| --- | --- | --- |
| `polardb_pg_exporter_io_read_count` | IO 读取次数 | `fileloc`, `filetype` |
| `polardb_pg_exporter_io_read_throughput` | IO 读取吞吐 | `fileloc`, `filetype` |
| `polardb_pg_exporter_io_read_latency_us` | IO 读取延迟（微秒） | `fileloc`, `filetype` |
| `polardb_pg_exporter_io_write_count` | IO 写入次数 | `fileloc`, `filetype` |
| `polardb_pg_exporter_io_write_throughput` | IO 写入吞吐 | `fileloc`, `filetype` |
| `polardb_pg_exporter_io_write_latency_us` | IO 写入延迟（微秒） | `fileloc`, `filetype` |
| `polardb_pg_exporter_io_fsync_count` | fsync 次数 | `fileloc`, `filetype` |
| `polardb_pg_exporter_io_fsync_latency_us` | fsync 延迟（微秒） | `fileloc`, `filetype` |
| `polardb_pg_exporter_io_latency_distribution` | IO 延迟分桶计数（非累积） | `ioloc`, `iokind`, `latency_bucket` |
| `polardb_pg_exporter_process_cpu_user` | backend 用户态 CPU | `backend_type` |
| `polardb_pg_exporter_process_cpu_sys` | backend 系统态 CPU | `backend_type` |
| `polardb_pg_exporter_process_rss` | backend RSS 内存 | `backend_type` |
| `polardb_pg_exporter_process_pfs_read_ps` | backend PFS 读次数速率 | `backend_type` |
| `polardb_pg_exporter_process_pfs_read_throughput` | backend PFS 读吞吐 | `backend_type` |
| `polardb_pg_exporter_process_pfs_read_latency_ms` | backend PFS 读延迟（毫秒） | `backend_type` |
| `polardb_pg_exporter_process_pfs_write_ps` | backend PFS 写次数速率 | `backend_type` |
| `polardb_pg_exporter_process_pfs_write_throughput` | backend PFS 写吞吐 | `backend_type` |
| `polardb_pg_exporter_process_pfs_write_latency_ms` | backend PFS 写延迟（毫秒） | `backend_type` |
| `polardb_pg_exporter_activity_wait_count` | 活跃会话等待数量 | `wait_event_type`, `wait_event`, `queryid` |

#### 通用 PostgreSQL 健康指标

| 指标名 | 含义 | 维度 |
| --- | --- | --- |
| `polardb_pg_exporter_connections` | 按会话状态的连接数 | `state` |
| `polardb_pg_exporter_max_connections` | 配置的最大连接数 | 无 |
| `polardb_pg_exporter_db_numbackends` | 各库当前连接数 | `datname` |
| `polardb_pg_exporter_db_xact_commit_total` | 各库事务提交数 | `datname` |
| `polardb_pg_exporter_db_xact_rollback_total` | 各库事务回滚数 | `datname` |
| `polardb_pg_exporter_db_blks_read_total` | 各库磁盘块读取数 | `datname` |
| `polardb_pg_exporter_db_blks_hit_total` | 各库缓冲命中数 | `datname` |
| `polardb_pg_exporter_db_tup_inserted_total` | 各库插入行数 | `datname` |
| `polardb_pg_exporter_db_tup_updated_total` | 各库更新行数 | `datname` |
| `polardb_pg_exporter_db_tup_deleted_total` | 各库删除行数 | `datname` |
| `polardb_pg_exporter_db_deadlocks_total` | 各库死锁数 | `datname` |
| `polardb_pg_exporter_db_temp_bytes_total` | 各库临时文件字节数 | `datname` |
| `polardb_pg_exporter_db_conflicts_total` | 各库恢复冲突取消的查询数 | `datname` |
| `polardb_pg_exporter_db_size_bytes` | 各库磁盘占用字节数 | `datname` |
| `polardb_pg_exporter_locks_count` | 按锁模式的持锁数 | `mode` |
| `polardb_pg_exporter_locks_waiting_count` | 等待中（未授予）的锁请求数 | 无 |
| `polardb_pg_exporter_in_recovery` | 节点角色：0 主库、1 只读/备库 | 无 |
| `polardb_pg_exporter_uptime_seconds` | postmaster 启动至今秒数 | 无 |
| `polardb_pg_exporter_longest_xact_seconds` | 最久未结束事务年龄（秒） | 无 |
| `polardb_pg_exporter_longest_active_query_seconds` | 最久活跃查询年龄（秒） | 无 |
| `polardb_pg_exporter_max_xid_age` | 各库最大事务 ID 年龄（回卷风险） | 无 |
| `polardb_pg_exporter_max_mxid_age` | 各库最大 multixact ID 年龄 | 无 |
| `polardb_pg_exporter_idle_in_transaction` | idle in transaction 会话数 | 无 |
| `polardb_pg_exporter_idle_in_transaction_aborted` | aborted idle in transaction 会话数 | 无 |
| `polardb_pg_exporter_checkpoints_timed_total` | 定时 checkpoint 次数 | 无 |
| `polardb_pg_exporter_checkpoints_req_total` | 请求触发 checkpoint 次数 | 无 |
| `polardb_pg_exporter_checkpoint_write_time_total` | checkpoint 写缓冲耗时（毫秒） | 无 |
| `polardb_pg_exporter_buffers_checkpoint_total` | checkpoint 写出缓冲数 | 无 |
| `polardb_pg_exporter_buffers_clean_total` | bgwriter 写出缓冲数 | 无 |
| `polardb_pg_exporter_buffers_backend_total` | backend 直接写出缓冲数 | 无 |
| `polardb_pg_exporter_maxwritten_clean_total` | bgwriter 因写满上限提前停止的次数 | 无 |
| `polardb_pg_exporter_wal_records_total` | 生成的 WAL 记录数 | 无 |
| `polardb_pg_exporter_wal_fpi_total` | 生成的 WAL 全页镜像数 | 无 |
| `polardb_pg_exporter_wal_bytes_total` | 生成的 WAL 字节数 | 无 |
| `polardb_pg_exporter_wal_buffers_full_total` | 因 WAL 缓冲写满触发刷盘的次数 | 无 |
