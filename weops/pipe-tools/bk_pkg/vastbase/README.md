## 嘉为蓝鲸海量数据库监控插件使用说明

### 插件功能

采集器连接数据库后执行sql，转换为监控指标。

### 版本支持：

操作系统支持: linux, windows

是否支持arm: 支持

**组件支持版本：**

海量数据库G100: Vastbase2.X

### 使用指引

登录数据库并执行命令创建蓝鲸监控账号和授权： 

创建用户: weops 密码: Weops123!  
```sql
CREATE USER weops IDENTIFIED BY "Weops123!";

GRANT CREATE ON TABLESPACE pg_global TO "weops";

GRANT USAGE ON SCHEMA dbms_pipe TO "weops";
GRANT SELECT ON ALL TABLES IN SCHEMA dbms_pipe TO "weops";

GRANT USAGE ON SCHEMA dbe_pldeveloper TO "weops";

GRANT SELECT ON pg_catalog.pg_authid TO "weops";

GRANT USAGE ON SCHEMA dbe_perf TO "weops";
GRANT SELECT ON ALL TABLES IN SCHEMA dbe_perf TO "weops";

GRANT USAGE ON SCHEMA sys TO "weops";
GRANT SELECT ON ALL TABLES IN SCHEMA sys TO "weops";
```

### 参数说明

| **参数名**                 | **含义**                                                      | **是否必填** | **使用举例**       |
|-------------------------|-------------------------------------------------------------|----------|----------------|
| SQL_EXPORTER_USER       | 数据库用户名(环境变量)，特殊字符不需要编码转义                                    | 是        | alphay         |
| SQL_EXPORTER_PASS       | 数据库密码(环境变量)，特殊字符不需要编码转义                                     | 是        | alphay123      |
| SQL_EXPORTER_HOST       | 数据库服务IP(环境变量)                                               | 是        | 127.0.0.1      |
| SQL_EXPORTER_PORT       | 数据库服务端口(环境变量)                                               | 是        | 5432           |
| SQL_EXPORTER_DB_NAME    | 数据库名称(环境变量)，未配置时使用数据库默认上下文                                | 否        | vastbase       |
| COLLECTOR_REFS          | 采集指标配置名称，对应`collector_name`，未配置时默认使用`collector.file`中的采集器 | 否        | vastbase*      |
| SCRAPE_TIMEOUT          | 采集超时时间                                                      | 否        | 10s            |
| MAX_CONNECTION_LIFETIME | 最长连接时长                                                      | 否        | 5m             |
| --collector.file        | 采集指标配置文件路径(文件参数), *.collector.yml 中需包含`db_type`、指标名、维度、sql等内容 | 是        |                |
| --log.level             | 日志级别                                                        | 否        | info           |
| --web.listen-address    | exporter监听IP及端口地址                                           | 否        | 127.0.0.1:9601 |


### 指标列表
| **up**                                            | **插件运行状态**      | **-**                                        | **-**                       | **-**   |
|---------------------------------------------------|-----------------|----------------------------------------------|-----------------------------|---------|
| vastbaseG100_exporter_database_used_disk_bytes    | 数据库使用的磁盘空间      | datname                                      | 数据库名称                       | bytes   |
| vastbaseG100_exporter_slow_query                  | 慢查询数量           | -                                            | -                           | -       |
| vastbaseG100_exporter_wait_count                  | 等待数量            | -                                            | -                           | -       |
| vastbaseG100_exporter_memory_info                 | 内存使用情况          | memorytype                                   | 内存类型                        | bytes   |
| vastbaseG100_exporter_buffers_clean               | 后台编写器写入的缓冲区数    | -                                            | 数据库名称, 锁模式                  | -       |
| vastbaseG100_exporter_buffers_checkpoint          | 检查点期间写入的缓冲区数    | -                                            | 数据库名称                       | -       |
| vastbaseG100_exporter_buffers_backend             | 后端直接写入的缓冲区数     | -                                            | -                           | -       |
| vastbaseG100_exporter_checkpoint_write_percent    | 检查点期间写入率        | -                                            | -                           | percent |
| vastbaseG100_exporter_buffers_hit_percent         | 缓存命中率           | datname                                      | 数据库名称                       | percent |
| vastbaseG100_exporter_xact_trans_percent          | 事务提交率           | datname                                      | 数据库名称                       | percent |
| vastbaseG100_exporter_xact_commit                 | 已提交事务数          | datname                                      | 数据库名称                       | -       |
| vastbaseG100_exporter_xact_rollback               | 已回滚事务数          | datname                                      | 数据库名称                       | -       |
| vastbaseG100_exporter_blks_read                   | 块读取数            | datname                                      | 数据库名称                       | -       |
| vastbaseG100_exporter_blks_hit                    | 块命中数            | datname                                      | 数据库名称                       | -       |
| vastbaseG100_exporter_tup_returned                | 查询返回行数          | datname                                      | 数据库名称                       | -       |
| vastbaseG100_exporter_tup_fetched                 | 查询获取行数          | datname                                      | 数据库名称                       | -       |
| vastbaseG100_exporter_tup_inserted                | 插入行数            | datname                                      | 数据库名称                       | -       |
| vastbaseG100_exporter_tup_updated                 | 更新行数            | datname                                      | 数据库名称                       | -       |
| vastbaseG100_exporter_tup_deleted                 | 删除行数            | datname                                      | 数据库名称                       | -       |
| vastbaseG100_exporter_conflicts                   | 取消查询数量          | datname                                      | 数据库名称                       | -       |
| vastbaseG100_exporter_temp_files                  | 临时文件数           | datname                                      | 数据库名称                       | -       |
| vastbaseG100_exporter_temp_bytes                  | 临时文件字节数         | datname                                      | 数据库名称                       | bytes   |
| vastbaseG100_exporter_deadlocks                   | 死锁数             | datname                                      | 数据库名称                       | -       |
| vastbaseG100_exporter_blk_read_time               | 读取数据文件块耗时       | datname                                      | 数据库名称                       | ms      |
| vastbaseG100_exporter_blk_write_time              | 写入数据文件块耗时       | datname                                      | 数据库名称                       | ms      |
| vastbaseG100_exporter_backend_connections         | 后端连接数           | datname                                      | 数据库名称                       | -       |
| vastbaseG100_exporter_process_used_memory_percent | 进程最大使用内存百分比     | -                                            | -                           | percent |
| vastbaseG100_exporter_dynamic_used_memory_percent | 动态最大使用内存百分比     | -                                            | -                           | percent |
| vastbaseG100_exporter_shared_used_memory_percent  | 共享最大使用内存百分比     | -                                            | -                           | percent |
| vastbaseG100_exporter_user_pass_valid             | 用户密码剩余有效时间      | rolname                                      | 用户名称                        | days    |
| vastbaseG100_exporter_table_size_bytes            | 数据库表大小          | datname, table_name, table_schema            | 数据库名称, 表名称, 表Schema名称       | bytes   |
| vastbaseG100_exporter_tablespace_total_used_mb    | 表已用空间大小         | pg_tablespace_location, spcname              | 表空间位置, 表空间名称                | MB      |
| vastbaseG100_exporter_granted_locks               | 已授予的锁数量         | datname                                      | 数据库名称                       | -       |
| vastbaseG100_exporter_db_locks                    | 数据库中不同类型锁的数量    | datname, mode                                | 数据库名称, 锁模式                  | -       |
| vastbaseG100_exporter_long_xact                   | 执行时间大于300秒的长事务数 | datname                                      | 数据库名称                       | -       |
| vastbaseG100_exporter_long_xact_duration          | 数据库执行查询的事务最大耗时  | datname                                      | 数据库名称                       | s       |
| vastbaseG100_exporter_connections                 | 数据库当前会话数        | -                                            | -                           | -       |
| vastbaseG100_exporter_setting_max_connections     | 数据库允许的最大会话数     | -                                            | -                           | -       |
| vastbaseG100_exporter_connection_used_percent     | 当前会话数使用率        | -                                            | -                           | percent |
| vastbaseG100_exporter_active_connections          | 当前活跃会话数         | -                                            | -                           | -       |
| vastbaseG100_exporter_block_connections           | 阻塞会话数           | -                                            | -                           | -       |
| vastbaseG100_exporter_idle_connections            | 空闲会话数           | -                                            | -                           | -       |
| vastbaseG100_exporter_index_ipages                | 索引页数            | datname, iname, schemaname, tablename        | 数据库名称, 索引名称, Schema名称, 表名称  | -       |
| vastbaseG100_exporter_index_iotta                 | 索引预期页数          | datname, iname, schemaname, tablename        | 数据库名称, 索引名称, Schema名称, 表名称  | -       |
| vastbaseG100_exporter_index_ibloat                | 索引膨胀比率          | datname, iname, schemaname, tablename        | 数据库名称, 索引名称, Schema名称, 表名称  | -       |
| vastbaseG100_exporter_index_wastedpages           | 索引浪费页数          | datname, iname, schemaname, tablename        | 数据库名称, 索引名称, Schema名称, 表名称  | -       |
| vastbaseG100_exporter_index_wastedibytes          | 索引浪费字节数         | datname, iname, schemaname, tablename        | 数据库名称, 索引名称, Schema名称, 表名称  | bytes   |
| vastbaseG100_exporter_index_totalwastedbytes      | 索引总浪费字节数        | datname, iname, schemaname, tablename        | 数据库名称, 索引名称, Schema名称, 表名称  | bytes   |
| vastbaseG100_exporter_table_tups                  | 表行数             | datname, iname, schemaname, tablename        | 数据库名称, 索引名称, Schema名称, 表名称  | -       |
| vastbaseG100_exporter_table_pages                 | 表页数             | datname, iname, schemaname, tablename        | 数据库名称, 索引名称, Schema名称, 表名称  | -       |
| vastbaseG100_exporter_table_otta                  | 表预期页数           | datname, iname, schemaname, tablename        | 数据库名称, 索引名称, Schema名称, 表名称  | -       |
| vastbaseG100_exporter_table_tbloat                | 表膨胀比率           | datname, iname, schemaname, tablename        | 数据库名称, 索引名称, Schema名称, 表名称  | -       |
| vastbaseG100_exporter_table_wastedbytes           | 表浪费空间大小         | datname, iname, schemaname, tablename        | 数据库名称, 索引名称, Schema名称, 表名称  | bytes   |
| vastbaseG100_exporter_wal_write_buffer            | WAL写入缓冲区数       | -                                            | -                           | -       |
| vastbaseG100_exporter_wal_write_block             | WAL写入块数         | -                                            | -                           | -       |
| vastbaseG100_exporter_backup_state                | 主备进程状态          | application_name, client_addr, backend_start | 应用名称, 客户端IP, 进程启动时间         | -       |
| vastbaseG100_exporter_backup_sync_state           | 主备进程同步状态        | application_name, client_addr, backend_start | 应用名称, 客户端IP, 进程启动时间         | -       |
| vastbaseG100_exporter_backup_slave_latency        | 备库WAL延迟应用量      | application_name, client_addr, backend_start | 应用名称, 客户端IP, 进程启动时间         | MB      |
| vastbaseG100_exporter_backup_send_latency         | 备库WAL延迟接收量      | application_name, client_addr, backend_start | 应用名称, 客户端IP, 进程启动时间         | MB      |
| vastbaseG100_exporter_backup_flush_latency        | 备库WAL延迟刷盘量      | application_name, client_addr, backend_start | 应用名称, 客户端IP, 进程启动时间         | MB      |


### 版本日志

#### weops_vastbaseG100_exporter 1.1.6
- weops调整

#### weops_vastbaseG100_exporter 4.1.1
- 基础探针移除采集器全局配置文件
- 更新说明文档

#### weops_vastbaseG100_exporter 4.2.1
- 补充 `SQL_EXPORTER_DB_NAME` 参数说明
