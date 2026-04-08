## 嘉为蓝鲸Sybase数据库监控插件使用说明

### 插件功能

采集器连接数据库后执行sql，转换为监控指标。

### 版本支持：

操作系统支持: linux, windows

是否支持arm: 支持

**组件支持版本：**

Sybase ASE: 12.5+ 

### 使用指引

登录数据库并执行命令创建蓝鲸监控账号和授权： 

创建用户: weops 密码: Weops123!  
```bash
sp_addlogin weops, "Weops123!", master
go

sp_role "grant",mon_role,weops
go
```


开启后才能监控
sp_configure 'enable monitoring',1

不开启会报错
Msg: 12052, Level: 17, State: 1\nServer: MYSYBASE, Procedure: gtds1, Line: 1:\nCollection of monitoring data for table 'monState' requires that the 'enable monitoring' configuration option(s) be enabled. To set the necessary configuration, contact a user who has the System Administrator (SA) role.\n"

### 参数说明

| **参数名**                 | **含义**                                                      | **是否必填** | **使用举例**       |
|-------------------------|-------------------------------------------------------------|----------|----------------|
| SQL_EXPORTER_USER       | 数据库用户名(环境变量)，特殊字符不需要编码转义                                    | 是        | sa             |
| SQL_EXPORTER_PASS       | 数据库密码(环境变量)，特殊字符不需要编码转义                                     | 是        | myPassword     |
| SQL_EXPORTER_HOST       | 数据库服务IP(环境变量)                                               | 是        | 127.0.0.1      |
| SQL_EXPORTER_PORT       | 数据库服务端口(环境变量)                                               | 是        | 5000           |
| SQL_EXPORTER_DB_NAME    | 数据库名称(环境变量)，未配置时使用登录账号的默认数据库                              | 否        | sybase         |
| COLLECTOR_REFS          | 采集指标配置名称，对应`collector_name`，未配置时默认使用`collector.file`中的采集器 | 否        | sybase*        |
| SCRAPE_TIMEOUT          | 采集超时时间                                                      | 否        | 10s            |
| MAX_CONNECTION_LIFETIME | 最长连接时长                                                      | 否        | 5m             |
| --collector.file        | 采集指标配置文件路径(文件参数), *.collector.yml 中需包含`db_type`、指标名、维度、sql等内容 | 是        |                |
| --log.level             | 日志级别                                                        | 否        | info           |
| --web.listen-address    | exporter监听IP及端口地址                                           | 否        | 127.0.0.1:9601 |


### 指标列表
| **指标ID**                                 | **指标中文名**   | **维度ID**                              | **维度含义**         | **单位**  |
|------------------------------------------|-------------|---------------------------------------|------------------|---------|
| up                                       | 插件运行状态      | -                                     | -                | -       |
| sybase_servername                        | 服务实例名称      | servername                            | 服务实例名称           | -       |
| sybase_uptime_days                       | 已运行时间       | InstanceID                            | 实例ID             | day     |
| sybase_deadlocks_total                   | 死锁总数        | InstanceID                            | 实例ID             | -       |
| sybase_lock_waits_total                  | 锁等待总数       | InstanceID                            | 实例ID             | -       |
| sybase_connections_total                 | 连接总数        | InstanceID                            | 实例ID             | -       |
| sybase_transactions_total                | 事务总数        | InstanceID                            | 实例ID             | -       |
| sybase_cache_hit_percent                 | 缓存命中率       | InstanceID, CacheName                 | 实例ID, 缓存名称       | percent |
| sybase_cache_size_kb                     | 缓存大小        | InstanceID, CacheName                 | 实例ID, 缓存名称       | kb      |
| sybase_physical_writes_total             | 物理写入总数      | InstanceID, CacheName                 | 实例ID, 缓存名称       | -       |
| sybase_buffer_pools                      | 缓冲池数量       | InstanceID, CacheName                 | 实例ID, 缓存名称       | -       |
| sybase_cache_partitions                  | 缓存分区数量      | InstanceID, CacheName                 | 实例ID, 缓存名称       | -       |
| sybase_last_backup_failed                | 上次备份是否失败    | InstanceID, DBName                    | 实例ID, 数据库名称      | -       |
| sybase_last_backup_duration_seconds      | 上次备份到现在的时间差 | InstanceID, DBName                    | 实例ID, 数据库名称      | s       |
| sybase_transaction_log_full              | 事务日志是否已满    | InstanceID, DBName                    | 实例ID, 数据库名称      | -       |
| sybase_device_filesystem_used_percent    | 设备文件系统使用率   | InstanceID, LogicalName, PhysicalName | 实例ID, 逻辑名称, 文件路径 | percent |
| sybase_device_filesystem_free_mb         | 设备文件系统空闲空间  | InstanceID, LogicalName, PhysicalName | 实例ID, 逻辑名称, 文件路径 | mb      |
| sybase_device_size_mb                    | 设备空间大小      | InstanceID, LogicalName, PhysicalName | 实例ID, 逻辑名称, 文件路径 | mb      |
| sybase_locks_total                       | 锁总数         | InstanceID, DBName, LockState         | 实例ID, 数据库名称, 锁状态 | -       |
| sybase_lock_max_wait_time                | 最大等待时间      | InstanceID, DBName, LockState         | 实例ID, 数据库名称, 锁状态 | -       |
| sybase_packet_received_total             | 接收网络包总数     | InstanceID                            | 实例ID             | -       |
| sybase_packet_sent_total                 | 发送网络包总数     | InstanceID                            | 实例ID             | -       |
| sybase_bytes_received_total              | 接收字节总数      | InstanceID                            | 实例ID             | -       |
| sybase_bytes_sent_total                  | 发送字节总数      | InstanceID                            | 实例ID             | -       |
| sybase_threads_active                    | 活动线程数       | InstanceID                            | 实例ID             | -       |
| sybase_thread_worker_memory_bytes        | 工作线程内存使用    | InstanceID                            | 实例ID             | bytes   |
| sybase_thread_worker_memory_used_percent | 工作线程内存使用率   | InstanceID                            | 实例ID             | percent |

### 版本日志

#### weops_sybase_exporter v4.1.2

#### weops_sybase_exporter v4.2.1
- 补充 `SQL_EXPORTER_DB_NAME` 参数说明
- weops调整
