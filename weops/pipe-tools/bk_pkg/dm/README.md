## 嘉为蓝鲸达梦数据库监控插件使用说明

### 插件功能

采集器连接数据库后执行sql，转换为监控指标。

### 版本支持：

操作系统支持: linux, windows

是否支持arm: 支持

**组件支持版本：**

达梦数据库: >=8.1.1.126

### 使用指引

登录数据库并执行命令创建蓝鲸监控账号和授权：

 ```bash
# 创建用户: weops 密码: Weops123!
CREATE USER weops IDENTIFIED BY "Weops123!";
# 要获取DB\table级别的监控信息必须拥有对应数据库的select权限
GRANT SELECT ON v$sessions TO weops;
GRANT SELECT ON V$SYSTEMINFO TO weops;
GRANT SELECT ON V$DM_INI TO weops;
GRANT SELECT ON V$SYSSTAT TO weops;
GRANT SELECT ON V$LOCK TO weops;
GRANT SELECT ON V$PARAMETER TO weops;
GRANT SELECT ON DBA_TABLES TO weops;
GRANT SELECT ON DBA_INDEXES TO weops;
GRANT SELECT ON V$OPEN_STMT TO weops;
GRANT SELECT ON V$RLOGFILE TO weops;
GRANT SELECT ON V$TRX TO weops;
GRANT SELECT ON V$ASMGROUP TO weops;
GRANT SELECT ON V$RLOG TO weops;
GRANT SELECT ON DBA_FREE_SPACE TO weops;
GRANT SELECT ON DBA_DATA_FILES TO weops;
GRANT SELECT ON DBA_OBJECTS TO weops;
GRANT SELECT ON V$BUFFERPOOL TO weops;
GRANT SELECT ON v$rapply_stat TO weops;
GRANT SELECT ON V$ARCH_STATUS TO weops;
GRANT SELECT ON V$UTSK_SYS2 TO weops;
GRANT SELECT ON v$instance TO weops;
GRANT SELECT ON v$dmwatcher TO weops;
GRANT SELECT ON V$DM_MAL_INI TO weops;
GRANT SELECT ON SYS.V$DM_MAL_INI TO weops;
GRANT SOI TO weops;
 ```

### 参数说明

| **参数名**                | **含义**                                                               | **是否必填** | **使用举例**       |
|------------------------|----------------------------------------------------------------------|----------|----------------|
| SQL_EXPORTER_USER      | 数据库用户名(环境变量)，特殊字符不需要编码转义                                             | 是        | SYSDBA         |
| SQL_EXPORTER_PASS      | 数据库密码(环境变量)，特殊字符不需要编码转义                                              | 是        | SYSDBA001      |
| SQL_EXPORTER_DB_TYPE   | 数据库类型(环境变量)                                                          | 是        | dm             |
| SQL_EXPORTER_HOST      | 数据库服务IP(环境变量)                                                        | 是        | 127.0.0.1      |
| SQL_EXPORTER_PORT      | 数据库服务端口(环境变量)                                                        | 是        | 5236           |
| -config.file           | sql_exporter.yml 采集器全局配置文件, 包含超时设置、最大连接数、目标配置、采集指标配置文件名等             | 是        | 默认已有采集器全局配置文件  |
| -log.level             | 日志级别                                                                 | 否        | info           |
| -web.listen-address    | exporter监听id及端口地址                                                    | 否        | 127.0.0.1:9601 |
| collector.file.content | *.collector.yml 采集指标配置文件, 包含指标名、维度、sql等内容。**注意！该参数为文件参数，非探针执行文件参数！** | 是        | 默认已有标准采集指标配置文件 |


### 指标列表
| **指标ID**                             | **指标中文名**       | **维度ID**                                                 | **维度含义**                  | **单位**  |
|--------------------------------------|-----------------|----------------------------------------------------------|---------------------------|---------|
| up                                   | 插件运行状态          | -                                                        | -                         | -       |
| dm_exporter_connections              | 当前连接数           | -                                                        | -                         | -       |
| dm_exporter_executions_total         | 执行sql语句总数       | -                                                        | -                         | -       |
| dm_exporter_session_rests            | 可用会话数           | -                                                        | -                         | -       |
| dm_exporter_session_used_ratio       | 会话使用率           | -                                                        | -                         | percent |
| dm_exporter_slow_query               | 超过2秒的慢查询        | -                                                        | -                         | -       |
| dm_exporter_tablespace_used_ratio    | 表空间使用率          | TABLESPACE_NAME                                          | 表名称                       | percent |
| dm_exporter_tablespace_size          | 表空间大小           | TABLESPACE_NAME                                          | 表名称                       | -       |
| dm_exporter_tablespace_used_size     | 表空间使用大小         | TABLESPACE_NAME                                          | 表名称                       | mb      |
| dm_exporter_tablespace_rest_size     | 表空间剩余大小         | TABLESPACE_NAME                                          | 表名称                       | mb      |
| dm_exporter_2pc_pending              | 长时间二阶段事务锁个数     | -                                                        | -                         | -       |
| dm_exporter_locks                    | 获取锁的进程数         | -                                                        | -                         | -       |
| dm_exporter_lock_blocks              | 等待锁的进程数         | -                                                        | -                         | -       |
| dm_exporter_redo_file_size           | ReDo文件大小        | PATH                                                     | 路径                        | mb      |
| dm_exporter_redo_log_size            | ReDo日志大小        | PATH, STATUS                                             | 路径, 状态                    | mb      |
| dm_exporter_roll_state               | 回滚状态            | ROLL_TYPE                                                | 类型                        | -       |
| dm_exporter_roll_size                | 回滚页大小           | ROLL_TYPE                                                | 类型                        | -       |
| dm_exporter_buffer_cache_hit_ratio   | 缓存命中率           | -                                                        | -                         | percent |
| dm_exporter_memory_used_size         | 内存使用量           | -                                                        | -                         | mb      |
| dm_exporter_shared_pool_size         | 共享内存大小          | -                                                        | -                         | -       |
| dm_exporter_checkpoint_dirty_pages   | CheckPoint重做日志块 | -                                                        | -                         | -       |
| dm_exporter_checkpoint_interval_time | CheckPoint间隔时间  | -                                                        | -                         | -       |
| dm_exporter_index_used_space         | 索引块数            | TABLE_OWNER, TABLE_NAME                                  | 表所有者, 表名称                 | -       |
| dm_exporter_load_five_average        | 数据库每5分钟工作负载     | -                                                        | -                         | -       |
| dm_exporter_open_cursor              | 打开的游标数          | -                                                        | -                         | -       |
| dm_exporter_table_used_space         | 表块数             | OWNER, TABLE_NAME                                        | 所有者, 表名称                  | -       |
| dm_exporter_unusable_index           | 失效索引数量          | -                                                        | -                         | -       |
| dm_exporter_asm_real_used_ratio      | ASM实际空间使用率      | GROUP_NAME                                               | 组名称                       | percent |
| dm_exporter_asm_free_size            | ASM安全使用空间大小     | GROUP_NAME                                               | 组名称                       | mb      |
| dm_exporter_backup_is_status         | 主备实例状态          | MAL_HOST, MAL_INST_HOST, INSTANCE_NAME, HOST_NAME, OGUID | 主机, 主机实例, 实例名, 主机名, OGUID | -       |
| dm_exporter_backup_arch_status       | 主备架构状态          | MAL_HOST, MAL_INST_HOST, INSTANCE_NAME, HOST_NAME, OGUID | 主机, 主机实例, 实例名, 主机名, OGUID | -       |
| dm_exporter_backup_dw_status         | 主备数据库观测状态       | MAL_HOST, MAL_INST_HOST, INSTANCE_NAME, HOST_NAME, OGUID | 主机, 主机实例, 实例名, 主机名, OGUID | -       |
| dm_exporter_backup_i_mode            | 主备实例模式          | MAL_HOST, MAL_INST_HOST, INSTANCE_NAME, HOST_NAME, OGUID | 主机, 主机实例, 实例名, 主机名, OGUID | -       |
| dm_exporter_backup_late_time         | 主备延迟时间          | -                                                        | -                         | s       |


注意: asm相关指标需要asm架构才能采集

### 版本日志

#### weops_dm_exporter 1.0.1
- weops调整
