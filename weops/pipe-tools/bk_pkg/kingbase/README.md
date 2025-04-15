## 嘉为蓝鲸人大金仓数据库监控插件使用说明

### 插件功能

采集器连接数据库后执行sql，转换为监控指标。

### 版本支持：

操作系统支持: linux, windows

是否支持arm: 支持

**组件支持版本：**

人大金仓数据库: Gokb连接驱动无版本限制

### 使用指引

登录数据库并执行命令创建蓝鲸监控账号和授权：

 ```bash
# 创建用户: weops 密码: Weops123!
CREATE USER weops WITH PASSWORD 'Weops123!';
 ```

### 参数说明

| **参数名**                | **含义**                                                               | **是否必填** | **使用举例**       |
|------------------------|----------------------------------------------------------------------|----------|----------------|
| SQL_EXPORTER_USER      | 数据库用户名(环境变量)，特殊字符不需要编码转义                                             | 是        | SYSDBA         |
| SQL_EXPORTER_PASS      | 数据库密码(环境变量)，特殊字符不需要编码转义                                              | 是        | SYSDBA001      |
| SQL_EXPORTER_DB_TYPE   | 数据库类型(环境变量)                                                          | 是        | kingbase       |
| SQL_EXPORTER_HOST      | 数据库服务IP(环境变量)                                                        | 是        | 127.0.0.1      |
| SQL_EXPORTER_PORT      | 数据库服务端口(环境变量)                                                        | 是        | 5236           |
| SQL_EXPORTER_TIMEOUT   | 数据库连接的最长等待时间(环境变量)，单位为秒，0值或未指定均为无限等待                                 | 是        | 5              |
| -config.file           | sql_exporter.yml 采集器全局配置文件, 包含超时设置、最大连接数、目标配置、采集指标配置文件名等             | 是        | 默认已有采集器全局配置文件  |
| -log.level             | 日志级别                                                                 | 否        | info           |
| -web.listen-address    | exporter监听id及端口地址                                                    | 否        | 127.0.0.1:9601 |
| collector.file.content | *.collector.yml 采集指标配置文件, 包含指标名、维度、sql等内容。**注意！该参数为文件参数，非探针执行文件参数！** | 是        | 默认已有标准采集指标配置文件 |


### 指标列表
| **指标ID**                                    | **指标中文名**          | **维度ID**          | **维度含义**   | **单位**  |
|---------------------------------------------|--------------------|-------------------|------------|---------|
| up                                          | 插件运行状态             | -                 | -          | -       |
| kingbase_exporter_current_connections       | 数据库当前连接数           | -                 | -          | -       |
| kingbase_exporter_max_connections_limit     | 数据库最大连接数限制         | -                 | -          | -       |
| kingbase_exporter_active_connections        | 数据库活动进程数           | datname           | 数据库名称      | -       |
| kingbase_exporter_idle_connections          | 数据库空闲进程数           | datname           | 数据库名称      | -       |
| kingbase_exporter_idle_in_trans_connections | 数据库空闲事务进程数         | datname           | 数据库名称      | -       |
| kingbase_exporter_slow_query_number         | 慢查询数量              | datname           | 数据库名称      | -       |
| kingbase_exporter_db_max_tran_duration      | 数据库当前执行事务的最长时间     | datname           | 数据库名称      | s       |
| kingbase_exporter_buffers_clean             | 后台编写器写入的缓冲区数       | -                 | -          | -       |
| kingbase_exporter_buffers_checkpoint        | 检查点期间写入的缓冲区数       | -                 | -          | -       |
| kingbase_exporter_buffers_backend           | 后端直接写入的缓冲区数        | -                 | -          | -       |
| kingbase_exporter_conflict_tablespaces      | 由于删除表空间而取消的查询数     | datname           | 数据库名称      | -       |
| kingbase_exporter_conflict_locks            | 由于锁定超时而取消的查询数      | datname           | 数据库名称      | -       |
| kingbase_exporter_conflict_snapshots        | 由于旧快照而取消的查询数       | datname           | 数据库名称      | -       |
| kingbase_exporter_conflict_bufferpins       | 由于固定缓冲区而取消的查询数     | datname           | 数据库名称      | -       |
| kingbase_exporter_conflict_deadlock         | 由于死锁而取消的查询数        | datname           | 数据库名称      | -       |
| kingbase_exporter_database_used_disk        | 数据库使用的磁盘空间         | datname           | 数据库名称      | bytes   |
| kingbase_exporter_locks_waiting_all         | 当前等待封锁的进程数量        | -                 | -          | -       |
| kingbase_exporter_locks_granted             | 已授予的锁数量            | datname, locktype | 数据库名称, 锁类型 | -       |
| kingbase_exporter_locks_waiting             | 等待授予的锁数量           | datname, locktype | 数据库名称, 锁类型 | -       |
| kingbase_exporter_opened_cursors            | 打开的游标数             | -                 | -          | -       |
| kingbase_exporter_buffers_hit_percent       | 缓冲区缓存命中率           | datname           | 数据库名称      | percent |
| kingbase_exporter_deadlocks                 | 死锁数量               | datname           | 数据库名称      | -       |
| kingbase_exporter_returned_tuples           | 全表扫描记录数            | datname           | 数据库名称      | -       |
| kingbase_exporter_xact_commit               | 数据库中已提交的事务数        | datname           | 数据库名称      | -       |
| kingbase_exporter_xact_rollback             | 数据库中已回滚的事务数        | datname           | 数据库名称      | -       |
| kingbase_exporter_rollback_percent          | 数据库的事务回滚率          | datname           | 数据库名称      | percent |
| kingbase_exporter_database_frozen_age       | 数据库中最老事务的年龄        | datname           | 数据库名称      | -       |
| kingbase_exporter_database_min_mxid_age     | 数据库中最小mxid的年龄      | datname           | 数据库名称      | -       |
| kingbase_exporter_license_validdays         | license剩余有效期(days) | -                 | -          | days    |

### 版本日志

#### weops_kingbase_exporter 1.3.4
- weops调整

#### weops_kingbase_exporter 1.3.5
- 创建监控账户SQL文档内容更正
