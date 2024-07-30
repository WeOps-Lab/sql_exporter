## 嘉为蓝鲸OpenGauss数据库监控插件使用说明

### 插件功能

采集器连接数据库后执行sql，转换为监控指标。

### 版本支持：

操作系统支持: linux, windows

是否支持arm: 支持

**组件支持版本：**

OpenGauss: >= 2.0.1

### 使用指引

登录数据库并执行命令创建蓝鲸监控账号和授权：  
创建账户名 `weops`, 密码 `Weops123!`  
```sql
CREATE USER weops PASSWORD 'Weops123!';
```

### 参数说明

| **参数名**                | **含义**                                                               | **是否必填** | **使用举例**       |
|------------------------|----------------------------------------------------------------------|----------|----------------|
| SQL_EXPORTER_USER      | 数据库用户名(环境变量)                                                         | 是        | SYSDBA         |
| SQL_EXPORTER_PASS      | 数据库密码(环境变量)                                                          | 是        | SYSDBA001      |
| SQL_EXPORTER_DB_TYPE   | 数据库类型(环境变量)                                                          | 是        | dm             |
| SQL_EXPORTER_HOST      | 数据库服务IP(环境变量)                                                        | 是        | 127.0.0.1      |
| SQL_EXPORTER_PORT      | 数据库服务端口(环境变量)                                                        | 是        | 5236           |
| SQL_EXPORTER_DB_NAME   | 数据库名(环境变量)                                                           | 是        | postgres       |
| -config.file           | sql_exporter.yml 采集器全局配置文件, 包含超时设置、最大连接数、目标配置、采集指标配置文件名等             | 是        | 默认已有采集器全局配置文件  |
| -log.level             | 日志级别                                                                 | 否        | info           |
| -web.listen-address    | exporter监听id及端口地址                                                    | 否        | 127.0.0.1:9601 |
| collector.file.content | *.collector.yml 采集指标配置文件, 包含指标名、维度、sql等内容。**注意！该参数为文件参数，非探针执行文件参数！** | 是        | 默认已有标准采集指标配置文件 |


### 指标列表
| **指标ID**                                     | **指标中文名**              | **维度ID**       | **维度含义**   | **单位**  |
|----------------------------------------------|------------------------|----------------|------------|---------|
| up                                           | 插件运行状态                 | -              | -          | -       |
| opengauss_exporter_memory_usage              | 内存使用情况                 | memorytype     | 内存类型       | mb      |
| opengauss_exporter_scheduled_checkpoints     | 执行定期checkpoint的数量      | -              | -          | -       |
| opengauss_exporter_request_checkpoints       | 执行请求checkpoint的数量      | -              | -          | -       |
| opengauss_exporter_checkpoint_write_time     | 处理checkpoint文件写入磁盘的时间  | -              | -          | ms      |
| opengauss_exporter_checkpoint_sync_time      | 处理checkpoint文件同步到磁盘的时间 | -              | -          | ms      |
| opengauss_exporter_buffers_checkpoint        | checkpoint期间写缓冲区数量     | -              | -          | -       |
| opengauss_exporter_buffers_clean             | 后端写进程写缓冲区数量            | -              | -          | -       |
| opengauss_exporter_buffers_backend           | 后端直接写缓冲区数              | -              | -          | -       |
| opengauss_exporter_buffers_backend_fsync     | 后端必须执行自己的fsync次数       | -              | -          | -       |
| opengauss_exporter_buffers_alloc             | 分配的缓冲区数量               | -              | -          | -       |
| opengauss_exporter_buffers_hit_ratio         | 数据库缓冲区缓存命中率            | datname        | 数据库名       | percent |
| opengauss_exporter_conflict_tablespaces      | 由于删除表空间而取消的查询数         | datname        | 数据库名       | -       |
| opengauss_exporter_conflict_locks            | 由于锁定超时而取消的查询数          | datname        | 数据库名       | -       |
| opengauss_exporter_conflict_snapshots        | 由于旧快照而取消的查询数           | datname        | 数据库名       | -       |
| opengauss_exporter_conflict_bufferpins       | 由于固定缓冲区而取消的查询数         | datname        | 数据库名       | -       |
| opengauss_exporter_conflict_deadlock         | 由于死锁而取消的查询数            | datname        | 数据库名       | -       |
| opengauss_exporter_max_transaction_time      | 当前最长的事务时间              | datname        | 数据库名       | s       |
| opengauss_exporter_xact_commit               | 数据库中已提交的事务数            | datname        | 数据库名       | -       |
| opengauss_exporter_xact_rollback             | 数据库中已回滚的事务数            | datname        | 数据库名       | -       |
| opengauss_exporter_xact_rollback_ratio       | 数据库事务回滚率               | datname        | 数据库名       | percent |
| opengauss_exporter_database_size             | 数据库磁盘使用空间              | datname        | 数据库名       | bytes   |
| opengauss_exporter_database_connection_limit | 数据库连接限制                | datname        | 数据库名       | -       |
| opengauss_exporter_connections               | 不同状态下的连接数              | datname, state | 数据库名, 连接状态 | -       |
| opengauss_exporter_connection_used_ratio     | 连接使用率                  | -              | -          | percent |
| opengauss_exporter_tup_returns               | 进行全表扫描的记录数             | datname        | 数据库名       | -       |
| opengauss_exporter_deadlocks_deadlocks       | 死锁数                    | datname        | 数据库名       | -       |
| opengauss_exporter_slow_queries              | 当前慢查询数量                | datname        | 数据库名       | -       |
| opengauss_exporter_locks                     | 数据库中锁数的数量              | datname, mode  | 数据库名, 锁类型  | -       |
| scrape_duration_seconds                      | 监控探针最近一次抓取时长           | -              | -          | s       |


### 版本日志

#### weops_opengauss_exporter 1.0.1
- weops调整
