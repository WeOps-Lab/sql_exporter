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
| SQL_EXPORTER_USER       | 数据库登录用户名(环境变量，需包含租户名)，特殊字符不需要编码转义                         | 是        | weops@sys      |
| SQL_EXPORTER_PASS       | 数据库密码(环境变量)，特殊字符不需要编码转义                                     | 是        |                |
| SQL_EXPORTER_HOST       | 数据库服务IP(环境变量)                                               | 是        | 127.0.0.1      |
| SQL_EXPORTER_PORT       | 数据库服务端口(环境变量)                                               | 是        | 2881           |
| SQL_EXPORTER_DB_NAME    | 数据库名称(环境变量)，未配置时使用数据库默认上下文                                | 否        | oceanbase      |
| COLLECTOR_REFS          | 采集指标配置名称，对应`collector_name`，未配置时默认使用`collector.file`中的采集器 | 否        | oceanbase*     |
| SCRAPE_TIMEOUT          | 采集超时时间                                                      | 否        | 10s            |
| MAX_CONNECTION_LIFETIME | 最长连接时长                                                      | 否        | 5m             |
| --collector.file        | 采集指标配置文件路径(文件参数), *.collector.yml 中需包含`db_type`、指标名、维度、sql等内容 | 是        |                |
| --log.level             | 日志级别                                                        | 否        | info           |
| --web.listen-address    | exporter监听IP及端口地址                                           | 否        | 127.0.0.1:9601 |


### 使用指引

> **关键说明：** 当前插件使用 MySQL 驱动，并通过 OceanBase v4.x 系统视图采集集群级和租户级指标，不能直接使用 Oracle 模式业务租户的账号。
>
> 如果客户允许使用 `sys` 租户，推荐直接在 `sys` 租户创建只读监控账号。如果客户安全策略禁止插件使用 `sys` 租户账号，请按照第 6 节创建独立的 MySQL 模式监控租户。

#### 1. 确认连接方式

OceanBase 登录用户名必须包含租户信息：

| **连接方式**       | **用户名格式**                    | **示例**                 |
|----------------|-------------------------------|------------------------|
| 直连 Observer    | `username@tenant`             | `weops@sys`            |
| 通过 OBProxy/ODP | `username@tenant#cluster_name` | `weops@sys#obcluster`  |

其中：

- `username` 是数据库用户。
- `tenant` 是用户所属租户。使用 `sys` 方案时填写 `sys`；使用独立监控租户方案时填写 `monitor_tenant`。
- `cluster_name` 是 OceanBase 集群名称，仅通过 OBProxy/ODP 连接时填写。

不要填写 Oracle 模式业务租户的账号，例如 `weops@oracle_tenant#obcluster`。

#### 2. 在 `sys` 租户创建监控账号

使用 OceanBase 管理员账号连接 `sys` 租户。以下示例为直连 Observer；请将地址、端口和密码替换为现场实际值：

```bash
obclient -h<observer_host> -P<observer_port> -uroot@sys -p
```

在 `root@sys` 会话中执行：

```sql
-- 创建 sys 租户下的监控用户。该操作只创建用户，不会创建新租户。
CREATE USER 'weops' IDENTIFIED BY '<monitor_password>';

-- 授予监控查询权限。生产环境可由 DBA 按下方系统视图列表收敛权限。
GRANT SELECT ON *.* TO 'weops';
```

#### 3. 验证监控账号

根据实际连接方式选择一种登录命令：

```bash
# 直连 Observer
obclient -h<observer_host> -P<observer_port> -uweops@sys -p

# 通过 OBProxy/ODP
obclient -h<proxy_host> -P<proxy_port> -uweops@sys#<cluster_name> -p
```

登录成功后执行：

```sql
-- 必须返回 MYSQL
SHOW VARIABLES LIKE 'ob_compatibility_mode';

-- 确认能够读取插件所需的系统视图
SELECT COUNT(*) FROM DBA_OB_SERVERS;
SELECT COUNT(*) FROM DBA_OB_TENANTS;
SELECT COUNT(*) FROM v$sysstat;
```

只有兼容模式返回 `MYSQL`，并且上述查询均成功时，才能将该账号配置到插件。

#### 4. 配置插件

| **参数名**              | **填写说明**                                      |
|----------------------|-----------------------------------------------|
| SQL_EXPORTER_HOST    | Observer 或 OBProxy/ODP 的访问地址                  |
| SQL_EXPORTER_PORT    | 与访问地址对应的端口                                  |
| SQL_EXPORTER_USER    | 直连填写 `weops@<tenant>`；代理连接填写 `weops@<tenant>#<cluster_name>` |
| SQL_EXPORTER_PASS    | `weops` 用户的密码                                  |
| SQL_EXPORTER_DB_TYPE | 固定填写 `oceanbase`                               |
| SQL_EXPORTER_DB_NAME | 默认留空                                          |

保存配置后，检查 exporter 指标：

```bash
curl -sS http://127.0.0.1:9601/metrics | grep -E '^up |scrape_errors'
```

正常情况下应看到 `up 1`，且日志中不再出现租户模式或系统视图权限错误。

#### 5. Oracle 租户报错说明

如果日志出现以下错误：

```text
Error 1235 (0A000): Oracle tenant for current client driver is not supported
```

表示 `SQL_EXPORTER_USER` 指向了 Oracle 模式租户。请改用 `sys` 租户账号，或者按照下一节创建独立的 MySQL 模式监控租户，并根据连接方式正确填写 `#cluster_name`。不要将 `SQL_EXPORTER_DB_TYPE` 改成 `oracle`。

#### 6. 不使用 `sys` 时创建 MySQL 模式监控租户

创建租户属于集群管理操作，必须由 OceanBase DBA 临时登录 `sys` 租户执行。租户创建完成后，exporter 只配置并使用 `monitor_tenant` 中的监控账号，不需要保存或使用 `sys` 管理员凭据。

以下示例中的资源规格、Zone、地址、端口、集群名和密码必须替换为现场实际值。

##### 6.1 查询可用 Zone

使用管理员账号登录 `sys` 租户：

```bash
obclient -h<observer_host> -P<observer_port> -uroot@sys -p
```

查询集群中的 Zone：

```sql
SELECT zone, status
FROM oceanbase.DBA_OB_ZONES;
```

记录一个状态正常且有足够资源的 Zone。下方示例使用 `zone1`。

##### 6.2 创建资源单元

```sql
CREATE RESOURCE UNIT monitor_unit
  MAX_CPU = 1,
  MIN_CPU = 1,
  MEMORY_SIZE = '2G',
  LOG_DISK_SIZE = '2G';
```

`CPU`、`MEMORY_SIZE` 和 `LOG_DISK_SIZE` 仅为示例。OceanBase DBA 应根据现场版本、最小资源要求和剩余容量调整；如果资源不足，租户创建或启动会失败。

##### 6.3 创建资源池

```sql
CREATE RESOURCE POOL monitor_pool
  UNIT = 'monitor_unit',
  UNIT_NUM = 1,
  ZONE_LIST = ('zone1');
```

`ZONE_LIST` 必须使用第 6.1 节查询到的实际 Zone。

##### 6.4 创建 MySQL 模式监控租户

```sql
CREATE TENANT monitor_tenant
  RESOURCE_POOL_LIST = ('monitor_pool')
  SET ob_compatibility_mode = 'mysql',
      ob_tcp_invited_nodes = '%';
```

租户兼容模式必须在 `CREATE TENANT` 时指定。已经创建的 Oracle 模式租户不能通过 `SET` 修改为 MySQL 模式。

在 `sys` 租户中确认创建结果：

```sql
SELECT tenant_name, compatibility_mode, status
FROM oceanbase.DBA_OB_TENANTS
WHERE tenant_name = 'monitor_tenant';
```

确认 `compatibility_mode` 为 `MYSQL`，并且租户状态正常。

##### 6.5 在监控租户创建账号

使用新租户的管理员账号登录：

```bash
# 直连 Observer
obclient -h<observer_host> -P<observer_port> -uroot@monitor_tenant -p

# 通过 OBProxy/ODP
obclient -h<proxy_host> -P<proxy_port> -u'root@monitor_tenant#<cluster_name>' -p
```

创建监控账号并授权：

```sql
CREATE USER 'weops' IDENTIFIED BY '<monitor_password>';
GRANT SELECT ON *.* TO 'weops';
```

##### 6.6 验证监控租户

使用 `weops` 账号登录：

```bash
# 直连 Observer
obclient -h<observer_host> -P<observer_port> -uweops@monitor_tenant -p

# 通过 OBProxy/ODP
obclient -h<proxy_host> -P<proxy_port> -u'weops@monitor_tenant#<cluster_name>' -p
```

执行：

```sql
-- 必须返回 MYSQL
SHOW VARIABLES LIKE 'ob_compatibility_mode';

-- 验证插件依赖的系统视图
SELECT COUNT(*) FROM DBA_OB_SERVERS;
SELECT COUNT(*) FROM DBA_OB_TENANTS;
SELECT COUNT(*) FROM GV$OB_SERVERS;
SELECT COUNT(*) FROM v$sysstat;
```

##### 6.7 配置插件

| **连接方式**       | **SQL_EXPORTER_USER**                         |
|----------------|-----------------------------------------------|
| 直连 Observer    | `weops@monitor_tenant`                        |
| 通过 OBProxy/ODP | `weops@monitor_tenant#<cluster_name>`         |

其他参数继续按照第 4 节填写，`SQL_EXPORTER_DB_TYPE` 必须保持为 `oceanbase`。

##### 6.8 采集范围和权限限制

独立 MySQL 租户与 `sys` 租户的系统视图可见范围可能不同，具体取决于 OceanBase 版本和客户授权策略。创建租户成功不代表插件一定能够完整采集。

- 第 6.6 节的系统视图查询全部成功后，才能接入插件。
- 如果出现“表或视图不存在”或“权限不足”，应由 OceanBase DBA 根据第 7 节逐项开放视图权限。
- 如果普通租户无法访问某些集群级或跨租户视图，相应指标将无法采集。该限制不能仅通过修改 exporter 页面参数解决，需要调整数据库授权策略，或者为普通租户单独适配采集 SQL。

#### 7. 所需系统视图权限说明

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

#### weops_oceanbase_exporter v4.2.1
- 补充 `SQL_EXPORTER_DB_NAME` 参数说明

#### weops_oceanbase_exporter v4.2.2
- 补充 OceanBase `Oracle` 业务租户场景的监控指引，包括 `sys` 监控账号方案、独立 MySQL 模式监控租户创建步骤、连接格式、权限验证和常见报错处理
