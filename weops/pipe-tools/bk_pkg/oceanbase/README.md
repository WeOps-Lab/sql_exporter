## 嘉为蓝鲸oceanbase插件使用说明

## 使用说明

### 插件功能

基于配置连接数据库并从中收集指标，其收集的指标及其采集、生成方式均由配置文件定义。

### 版本支持

操作系统支持: linux, windows

是否支持arm: 支持

**组件支持版本：**
oceanbase: v4.x+

**是否支持远程采集:**

是

### 参数说明


| **参数名**                 | **含义**                                                      | **是否必填** | **使用举例**       |
|-------------------------|-------------------------------------------------------------|----------|----------------|
| SQL_EXPORTER_USER       | 数据库用户名(环境变量)，特殊字符不需要编码转义                                    | 是        | root           |
| SQL_EXPORTER_PASS       | 数据库密码(环境变量)，特殊字符不需要编码转义                                     | 是        |                |
| SQL_EXPORTER_DB_TYPE    | 数据库类型(环境变量)                                                 | 是        | oceanbase      |
| SQL_EXPORTER_HOST       | 数据库服务IP(环境变量)                                               | 是        | 127.0.0.1      |
| SQL_EXPORTER_PORT       | 数据库服务端口(环境变量)                                               | 是        | 2881           |
| COLLECTOR_REFS          | 采集指标配置名称，对应`collector_name`，一般使用模糊匹配                        | 是        | oceanbase*     |
| SCRAPE_TIMEOUT          | 采集超时时间                                                      | 否        | 10s            |
| MAX_CONNECTION_LIFETIME | 最长连接时长                                                      | 否        | 5m             |
| --collector.file        | 采集指标配置文件路径(文件参数), *.collector.yml 采集指标配置文件, 包含指标名、维度、sql等内容 | 是        |                |
| --log.level             | 日志级别                                                        | 否        | info           |
| --web.listen-address    | exporter监听IP及端口地址                                           | 否        | 127.0.0.1:9601 |


### 使用指引

> **注意：** 创建监控账户需要使用超级管理员权限（root@sys）连接数据库。

#### 1. 使用超管权限连接到 OceanBase 数据库

```bash
obclient -h127.0.0.1 -P2881 -uroot@sys -p
```

#### 2. 创建监控用户并授权（需超管权限）

```sql
-- 创建监控用户
CREATE USER 'weops' IDENTIFIED BY 'weops@123!';

-- 授予查询权限（用于采集监控指标）
GRANT SELECT ON *.* TO 'weops';
```

#### 3. 所需系统视图权限说明

监控采集需要访问以下系统视图，请确保监控用户具有这些视图的 SELECT 权限：

| **视图名称**                 | **用途说明**             |
|--------------------------|----------------------|
| DBA_OB_SERVERS           | 获取服务器状态信息            |
| DBA_OB_TENANTS           | 获取租户信息               |
| GV$OB_SERVERS            | 获取服务器资源信息            |
| GV$OB_KVCACHE            | 获取缓存信息               |
| GV$OB_PROCESSLIST        | 获取会话连接信息             |
| GV$OB_MEMSTORE           | 获取内存存储信息             |
| GV$OB_MEMORY             | 获取内存使用信息             |
| V$OB_PLAN_CACHE_STAT     | 获取计划缓存统计             |
| v$sysstat                | 获取系统统计信息（CPU/内存/IO等） |
| v$system_event           | 获取系统等待事件信息           |
| gv$ob_units / v$ob_units | 获取资源单元信息             |
| dba_ob_units             | 获取资源单元配置             |
| CDB_TABLES               | 获取表数量统计              |
| CDB_INDEXES              | 获取索引状态信息             |

#### 4. 验证权限

```sql
-- 使用监控用户登录验证
obclient -h127.0.0.1 -P2881 -uweops -p'weops@123!'

-- 测试查询系统视图
SELECT count(*) FROM DBA_OB_SERVERS;
SELECT count(*) FROM v$sysstat;
```

### 指标简介
| **指标ID**                                  | **指标中文名**           | **维度ID**               | **维度含义**   | **单位**  | **指标类型** |
|-------------------------------------------|---------------------|------------------------|------------|---------|----------|
| up                                        | 插件运行状态              | -                      | -          | -       | gauge    |
| oceanbase_uptime                          | OceanBase服务器运行时间    | -                      | -          | s       | gauge    |
| oceanbase_version                         | OceanBase版本信息       | version                | 版本号        | -       | gauge    |
| oceanbase_server_status                   | OceanBase服务器状态      | servers, status        | 服务名称, 状态   | -       | gauge    |
| oceanbase_active_session                  | OceanBase当前活跃连接会话数量 | tenant_name, tenant_id | 租户名称, 租户ID | -       | gauge    |
| oceanbase_all_session                     | OceanBase所有连接会话总数量  | tenant_name, tenant_id | 租户名称, 租户ID | -       | gauge    |
| oceanbase_cache_size                      | OceanBase缓存大小       | cache_name, tenant_id  | 缓存名称, 租户ID | bytes   | gauge    |
| oceanbase_plan_cache_hit_percent          | OceanBase计划缓存命中率    | tenant_id              | 租户ID       | percent | gauge    |
| oceanbase_disk_free                       | OceanBase磁盘剩余容量     | -                      | -          | bytes   | gauge    |
| oceanbase_disk_total                      | OceanBase磁盘总容量      | -                      | -          | bytes   | gauge    |
| oceanbase_disk_used_percent               | OceanBase磁盘使用率      | -                      | -          | percent | gauge    |
| oceanbase_memstore_active                 | OceanBase内存存储活跃空间   | tenant_id              | 租户ID       | bytes   | gauge    |
| oceanbase_memstore_freeze_count           | OceanBase内存存储冻结次数   | tenant_id              | 租户ID       | -       | gauge    |
| oceanbase_memstore_freeze_trigger         | OceanBase内存存储冻结触发阈值 | tenant_id              | 租户ID       | bytes   | gauge    |
| oceanbase_memstore_total                  | OceanBase内存存储总空间    | tenant_id              | 租户ID       | bytes   | gauge    |
| oceanbase_server_cpu_assigned             | OceanBase服务器CPU已分配  | -                      | -          | -       | gauge    |
| oceanbase_server_cpu_total                | OceanBase服务器CPU总量   | -                      | -          | -       | gauge    |
| oceanbase_server_disk_total               | OceanBase服务器磁盘总量    | -                      | -          | bytes   | gauge    |
| oceanbase_server_memory_assigned          | OceanBase服务器内存已分配   | -                      | -          | bytes   | gauge    |
| oceanbase_server_memory_total             | OceanBase服务器内存总量    | -                      | -          | bytes   | gauge    |
| oceanbase_sysstat_active_memstore_used    | 活跃Memstore使用量       | tenant_id              | 租户ID       | bytes   | gauge    |
| oceanbase_sysstat_block_cache_hit_percent | 块缓存命中率              | tenant_id              | 租户ID       | percent | gauge    |
| oceanbase_sysstat_cpu_usage               | CPU使用率              | tenant_id              | 租户ID       | percent | gauge    |
| oceanbase_sysstat_io_read                 | IO读取次数              | tenant_id              | 租户ID       | -       | counter  |
| oceanbase_sysstat_io_read_bytes           | IO读取字节数             | tenant_id              | 租户ID       | bytes   | counter  |
| oceanbase_sysstat_io_write                | IO写入次数              | tenant_id              | 租户ID       | -       | counter  |
| oceanbase_sysstat_io_write_bytes          | IO写入字节数             | tenant_id              | 租户ID       | bytes   | counter  |
| oceanbase_sysstat_max_memory              | 最大内存                | tenant_id              | 租户ID       | bytes   | gauge    |
| oceanbase_sysstat_memory_usage            | 内存使用量               | tenant_id              | 租户ID       | bytes   | gauge    |
| oceanbase_sysstat_memory_usage_percent    | 内存使用率               | tenant_id              | 租户ID       | percent | gauge    |
| oceanbase_sysstat_memstore_limit          | MEMStore的最大使用限制     | tenant_id              | 租户ID       | bytes   | gauge    |
| oceanbase_sysstat_sql_delete_rt           | SQL DELETE平均响应时间    | tenant_id              | 租户ID       | µs      | gauge    |
| oceanbase_sysstat_sql_insert_rt           | SQL INSERT平均响应时间    | tenant_id              | 租户ID       | µs      | gauge    |
| oceanbase_sysstat_sql_select_rt           | SQL SELECT平均响应时间    | tenant_id              | 租户ID       | µs      | gauge    |
| oceanbase_sysstat_sql_update_rt           | SQL UPDATE平均响应时间    | tenant_id              | 租户ID       | µs      | gauge    |
| oceanbase_sysstat_total_memstore_used     | Memstore总使用量        | tenant_id              | 租户ID       | bytes   | gauge    |
| oceanbase_sysstat_trans_commit            | 事务提交数量              | tenant_id              | 租户ID       | -       | counter  |
| oceanbase_sysstat_trans_rollback          | 事务回滚数量              | tenant_id              | 租户ID       | -       | counter  |
| oceanbase_sysstat_trans_timeout           | 事务超时数量              | tenant_id              | 租户ID       | -       | counter  |
| oceanbase_waitevent_avg_time              | OceanBase等待事件平均耗时   | tenant_id              | 租户ID       | µs      | gauge    |
| oceanbase_system_event_avg_time           | OceanBase系统事件平均耗时   | event_group, tenant_id | 事件, 租户ID   | µs      | gauge    |
| oceanbase_table_count                     | OceanBase表数量统计      | tenant_id              | 租户ID       | -       | gauge    |
| oceanbase_tenant500_memory_hold           | OceanBase系统租户内存持有量  | -                      | -          | bytes   | gauge    |
| oceanbase_tenant500_memory_used           | OceanBase系统租户内存使用量  | -                      | -          | bytes   | gauge    |
| oceanbase_tenant500_memory_used_percent   | OceanBase系统租户内存使用率  | -                      | -          | percent | gauge    |
| oceanbase_index_error                     | OceanBase索引错误数量     | -                      | -          | -       | gauge    |
| oceanbase_is_rootservice                  | OceanBase根服务状态      | svr_port, svr_ip       | 服务端口, 服务IP | -       | gauge    |
| oceanbase_tenant_cpu_assigned             | OceanBase租户CPU已分配   | tenant_name, tenant_id | 租户名称, 租户ID | -       | gauge    |
| oceanbase_tenant_cpu_total                | OceanBase租户CPU总量    | tenant_name, tenant_id | 租户名称, 租户ID | -       | gauge    |
| oceanbase_tenant_data_disk                | OceanBase租户数据磁盘使用量  | tenant_name, tenant_id | 租户名称, 租户ID | bytes   | gauge    |
| oceanbase_tenant_log_disk                 | OceanBase租户日志磁盘使用量  | tenant_name, tenant_id | 租户名称, 租户ID | bytes   | gauge    |
| oceanbase_tenant_memory_assigned          | OceanBase租户内存已分配    | tenant_name, tenant_id | 租户名称, 租户ID | bytes   | gauge    |
| oceanbase_tenant_memory_total             | OceanBase租户内存总量     | tenant_name, tenant_id | 租户名称, 租户ID | bytes   | gauge    |
| scrape_duration_seconds                   | 监控探针最近一次抓取时长        | -                      | -          | s       | -        |

### 版本日志

#### weops_oceanbase_exporter v4.1.3

- weops调整
