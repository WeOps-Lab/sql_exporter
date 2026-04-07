## 嘉为蓝鲸mssql插件使用说明

## 使用说明

### 插件功能

基于配置连接数据库并从中收集指标，其收集的指标及其采集、生成方式均由配置文件定义。

### 版本支持

操作系统支持: linux, windows

是否支持arm: 支持

**组件支持版本：**


| **主版本号** | **次版本号** | **指标支持** |
|----------|----------|----------|
| 2008     | 10.x     | &#10004; |
| 2008 R2  | 10.5     | &#10004; |
| 2012     | 11.x     | &#10004; |
| 2014     | 12.x     | &#10004; |
| 2016     | 13.x     | &#10004; |
| 2017     | 14.x     | &#10004; |
| 2019     | 15.x     | &#10004; |
| 2022     | 16.x     | &#10004; |

**是否支持远程采集:**

是

### 参数说明


| **参数名**                 | **含义**                                                      | **是否必填** | **使用举例**       |
|-------------------------|-------------------------------------------------------------|----------|----------------|
| SQL_EXPORTER_USER       | 数据库用户名(环境变量)，特殊字符不需要编码转义                                    | 是        | SA             |
| SQL_EXPORTER_PASS       | 数据库密码(环境变量)，特殊字符不需要编码转义                                     | 是        |                |
| SQL_EXPORTER_HOST       | 数据库服务IP(环境变量)                                               | 是        | 127.0.0.1      |
| SQL_EXPORTER_PORT       | 数据库服务端口(环境变量)                                               | 是        | 1433           |
| COLLECTOR_REFS          | 采集指标配置名称，对应`collector_name`，未配置时默认使用`collector.file`中的采集器 | 否        | mssql*         |
| SCRAPE_TIMEOUT          | 采集超时时间                                                      | 否        | 10s            |
| MAX_CONNECTION_LIFETIME | 最长连接时长                                                      | 否        | 5m             |
| --collector.file        | 采集指标配置文件路径(文件参数), *.collector.yml 中需包含`db_type`、指标名、维度、sql等内容 | 是        |                |
| --log.level             | 日志级别                                                        | 否        | info           |
| --web.listen-address    | exporter监听IP及端口地址                                           | 否        | 127.0.0.1:9601 |

**采集指标配置文件(mssql_standard.collector.yml)**

```yaml
# 收集器的名字
collector_name: mssql_standard

metrics:
  - metric_name: mssql_version # 指标ID
    type: counter # 类型
    help: 'Fetched version of instance.' # 描述
    key_labels: # 维度值
      - ProductVersion
    values: [value] # 值
    query: | # sql语句
      SELECT CONVERT(VARCHAR(128), SERVERPROPERTY ('productversion')) AS ProductVersion, 1 AS value
```

### 使用指引

以下是在SQL Server中使用命令行创建监控用户的教程：

方式一:

1. 连接到 MSSQL 数据库服务器，并使用具有足够权限的管理员用户帐户登录。
2. 在 SQL Server Management Studio 中，右键单击 Security，然后选择 "New Login"。
3. 在 "Login - New" 对话框中，输入监控用户的用户名，选择 "SQL Server authentication" 作为登录类型，并设置一个**强密码**。
4. 在 "Default database" 下拉菜单中，选择用户需要访问的数据库，一般默认master即可。
5. 在 "Server Roles" 选项卡中，选择 "public" 角色。
6. 在 "User Mapping" 选项卡中，将需要访问的数据库分配给该用户。
7. 单击 "OK" 按钮以创建该用户。

在 MSSQL exporter 的配置文件中，使用此监控用户的凭据访问数据库。

方式二: 通过终端与数据库交互

1. 打开命令提示符或PowerShell，使用sqlcmd命令连接到SQL Server，如下所示：

   ```sql
   sqlcmd -S server_address -U sa -P your_password
   ```

   其中，server_address是SQL Server的访问地址，sa是具有足够权限的SQL Server管理员的登录名，your_password是对应的密码。
2. 使用以下命令创建监控用户，该用户只具有读取权限，允许用户查看所有对象的定义：

   ```sql
   CREATE LOGIN monitoring_user WITH PASSWORD = 'your_password';
   GRANT VIEW SERVER STATE TO monitoring_user;
   GRANT VIEW ANY DEFINITION TO monitoring_user;
   GO
   ```

   其中，monitoring_user是监控用户的名称，your_password是对应的密码。
3. 如果需要在特定的数据库中监控，请使用以下命令授予监控用户对该数据库的访问权限：

   ```sql
   USE database_name;
   CREATE USER monitoring_user FOR LOGIN monitoring_user;
   ALTER ROLE db_datareader ADD MEMBER monitoring_user;
   GO
   ```

   其中，database_name是要监控的数据库的名称，一般默认使用master。

### 指标简介

| **指标ID**                                   | **指标中文名**             | **维度ID**                              | **维度含义**                  | **单位**  | **指标类型** | **计算指标** |
|--------------------------------------------|-----------------------|---------------------------------------|---------------------------|---------|----------|----------|
| up                                         | 监控插件运行状态              | -                                     | -                         | -       | gauge    | 原始指标     |
| mssql_version                              | Mssql版本号              | ProductVersion                        | 产品版本号                     | -       | gauge    | 原始指标     |
| mssql_instance_uptime                      | Mssql已运行时间            | -                                     | -                         | s       | gauge    | 原始指标     |
| mssql_database_state                       | Mssql数据库状态            | db                                    | 数据库名称                     | -       | gauge    | 原始指标     |
| mssql_local_time_seconds                   | Mssql本地时间             | -                                     | -                         | s       | gauge    | 原始指标     |
| mssql_always_on_status                     | Mssql AlwaysOn高可用性组状态 | -                                     | -                         | -       | gauge    | 原始指标     |
| mssql_total_page_file_bytes                | Mssql总页文件字节数          | -                                     | -                         | bytes   | gauge    | 原始指标     |
| mssql_available_page_file_bytes            | Mssql可用页文件字节数         | -                                     | -                         | bytes   | gauge    | 原始指标     |
| mssql_available_physical_memory_bytes      | Mssql可用物理内存字节数        | -                                     | -                         | bytes   | gauge    | 原始指标     |
| mssql_os_memory                            | Mssql操作系统内存           | state                                 | 内存状态                      | bytes   | gauge    | 原始指标     |
| mssql_total_physical_memory_bytes          | Mssql物理内存总字节数         | -                                     | -                         | bytes   | gauge    | 原始指标     |
| mssql_memory_utilization_percentage        | Mssql内存利用率            | -                                     | -                         | percent | gauge    | 原始指标     |
| mssql_virtual_memory_bytes                 | Mssql虚拟内存字节数          | -                                     | -                         | bytes   | gauge    | 原始指标     |
| mssql_batch_requests                       | Mssql批量请求             | -                                     | -                         | -       | counter  | 原始指标     |
| mssql_batch_requests_increase_5min         | Mssql每5分钟增长的批量请求      | -                                     | -                         | -       | gauge    | 衍生指标     |
| mssql_processes_blocked                    | Mssql进程阻塞数            | -                                     | -                         | -       | counter  | 原始指标     |
| mssql_processes_blocked_increase_5min      | Mssql每5分钟增长的进程阻塞数     | -                                     | -                         | -       | gauge    | 衍生指标     |
| mssql_buffer_cache_hit_ratio               | Mssql缓冲区高速缓存命中率       | -                                     | -                         | percent | gauge    | 原始指标     |
| mssql_checkpoint_pages_sec                 | Mssql检查点写入页数          | -                                     | -                         | -       | counter  | 原始指标     |
| mssql_checkpoint_pages_increase_5min       | Mssql每5分钟增长的检查点写入页数   | -                                     | -                         | -       | gauge    | 衍生指标     |
| mssql_io_stall_seconds                     | Mssql I/O暂停时间         | db, operation                         | 数据库名称, 操作类型               | s       | counter  | 原始指标     |
| mssql_io_stall_increase_5min               | Mssql每5分钟增长的I/O暂停时间   | db, operation                         | 数据库名称, 操作类型               | s       | gauge    | 衍生指标     |
| mssql_io_stall_total_seconds               | Mssql总I/O暂停时间         | db                                    | 数据库名称                     | s       | counter  | 原始指标     |
| mssql_io_stall_total_increase_5min         | Mssql每5分钟增长的总I/O暂停时间  | db                                    | 数据库名称                     | s       | gauge    | 衍生指标     |
| mssql_lazy_write_sec                       | Mssql延迟写入时间           | -                                     | -                         | s       | counter  | 原始指标     |
| mssql_lazy_write_increase_5min             | Mssql每5分钟增长的延迟写入时间    | -                                     | -                         | s       | gauge    | 衍生指标     |
| mssql_page_fault_count                     | Mssql页面错误次数           | -                                     | -                         | -       | counter  | 原始指标     |
| mssql_page_fault_increase_5min             | Mssql每5分钟增长的页面错误次数    | -                                     | -                         | -       | gauge    | 衍生指标     |
| mssql_page_life_expectancy                 | Mssql页面寿命期望值          | -                                     | -                         | s       | gauge    | 原始指标     |
| mssql_page_reads_sec                       | Mssql页读取数             | -                                     | -                         | -       | counter  | 原始指标     |
| mssql_page_reads_increase_5min             | Mssql每5分钟增长的页读取数      | -                                     | -                         | -       | gauge    | 衍生指标     |
| mssql_page_write_sec                       | Mssql页写入数             | -                                     | -                         | -       | counter  | 原始指标     |
| mssql_page_write_increase_5min             | Mssql每5分钟增长的页写入数      | -                                     | -                         | -       | gauge    | 衍生指标     |
| mssql_resident_memory_bytes                | Mssql常驻内存字节数          | -                                     | -                         | bytes   | gauge    | 原始指标     |
| mssql_client_connections                   | Mssql客户端连接数           | db, host                              | 数据库名称, 客户端主机名称            | -       | gauge    | 原始指标     |
| mssql_connections                          | Mssql连接数              | db                                    | 数据库名称                     | -       | gauge    | 原始指标     |
| mssql_deadlocks                            | Mssql死锁数              | -                                     | -                         | -       | counter  | 原始指标     |
| mssql_deadlocks_increase_5min              | Mssql每5分钟增长的死锁数       | -                                     | -                         | -       | gauge    | 衍生指标     |
| mssql_transactions                         | Mssql事务数              | db                                    | 数据库名称                     | -       | counter  | 原始指标     |
| mssql_transactions_increase_5min           | Mssql每5分钟增长的事务数       | db                                    | 数据库名称                     | -       | gauge    | 衍生指标     |
| mssql_kill_connection_errors               | Mssql终止连接错误数          | -                                     | -                         | -       | counter  | 原始指标     |
| mssql_kill_connection_errors_increase_5min | Mssql每5分钟增长的终止连接错误数   | -                                     | -                         | -       | gauge    | 衍生指标     |
| mssql_user_errors                          | Mssql用户错误数            | -                                     | -                         | -       | counter  | 原始指标     |
| mssql_user_errors_increase_5min            | Mssql每5分钟增长的用户错误数     | -                                     | -                         | -       | gauge    | 衍生指标     |
| mssql_database_filesize                    | Mssql数据库文件大小          | db, logical_name, physical_name, type | 数据库名称, 逻辑文件名, 物理文件名, 文件类型 | bytes   | gauge    | 原始指标     |
| mssql_db_file_used_ratio                   | Mssql数据库文件使用率         | db, file_name                         | 数据库名称, 文件名称               | percent | gauge    | 原始指标     |
| mssql_db_log_file_size                     | Mssql数据库日志文件大小        | db, file_name                         | 数据库名称, 文件名称               | bytes   | gauge    | 原始指标     |
| mssql_last_backup_duration                 | Mssql数据库距离最后一次备份时间    | db                                    | 数据库名称                     | days    | gauge    | 原始指标     |
| mssql_db_log_file_used_ratio               | Mssql数据库日志文件使用率       | db, file_name                         | 数据库名称, 文件名称               | percent | gauge    | 原始指标     |
| mssql_log_growths                          | Mssql日志增长数            |                                       | db                        | 数据库名称   | -        | counter  | 原始指标 |
| mssql_log_growths_increase_5min            | Mssql每5分钟的日志增长数       |                                       | db                        | 数据库名称   | -        | gauge    | 衍生指标 |
| scrape_duration_seconds                    | 监控探针最近一次抓取时长          | -                                     | -                         | s       | gauge    | 原始指标     |

### 版本日志

#### weops_mssql_exporter 3.0.2

- weops调整

#### weops_mssql_exporter 3.1.1

- DSN拆分
- 隐藏敏感参数
- 优化探针性能

#### weops_mssql_exporter 3.1.2

- 修复2014及以下版本sql server连接问题

#### weops_mssql_exporter 3.1.3

- 更正部分官方解释不准确的指标

#### weops_mssql_exporter 3.1.4

- 新增内置部分计算指标

#### weops_mssql_exporter 3.1.5

- 修复mssql_last_backup_duration指标维度缺失问题

#### weops_mssql_exporter 4.1.1
- 基础探针移除采集器全局配置文件
- 更新说明文档
