## 嘉为蓝鲸mssql插件使用说明

## 使用说明

### 插件功能

基于配置连接数据库并从中收集指标，其收集的指标及其采集、生成方式均由配置文件定义。

### 版本支持

理论上支持: linux, windows

是否支持arm: 支持

**组件支持版本：**


| **主版本号** | **次版本号** | **指标支持** |
|----------|----------|----------|
| 2008     | 10.x     | -        |
| 2008 R2  | 10.5     | -        |
| 2012     | 11.x     | -        |
| 2014     | 12.x     | -        |
| 2016     | 13.x     | &#10004; |
| 2017     | 14.x     | &#10004; |
| 2019     | 15.x     | &#10004; |
| 2022     | 16.x     | &#10004; |

**是否支持远程采集:**

是

### 参数说明


| **参数名**                  | **含义**                                                                            | **是否必填** | **使用举例**                                 |
|--------------------------|-----------------------------------------------------------------------------------|----------|------------------------------------------|
| -config.data-source-name | 数据源名称，填写会覆盖配置文件中的数据源data_source_name,**注意！在监控平台填写参数时不要用双引号将参数包起来**                | 是        | sqlserver://user:password@127.0.0.1:1433 |
| -config.file             | sql_exporter.yml 采集器全局配置文件, 包含超时设置、最大连接数、目标配置、采集指标配置文件名等                          | 是        | 默认已有采集器全局配置文件                            |
| -log.level               | 日志级别                                                                              | 否        | info                                     |
| -web.listen-address      | exporter监听id及端口地址                                                                 | 否        | 127.0.0.1:9601                           |
| collector.file.content   | mssql_standard.collector.yml 采集指标配置文件, 包含指标名、维度、sql等内容。**注意！该参数为文件参数，非探针执行文件参数！** | 是        | 默认已有标准采集指标配置文件                           |

**采集器全局配置文件说明(sql_exporter.yml)**

```yaml
# 全局配置
global:
  # sql语句的超时时间，这个值需要比prometheus的 `scrape_timeout` 值要小。如果配置了下方的 scrape_timeout_offset 值，那么最终的超时时间为， min(scrape_timeout, X-Prometheus-Scrape-Timeout-Seconds - scrape_timeout_offset)
  # X-Prometheus-Scrape-Timeout-Seconds 为 prometheus 的超时时间
  scrape_timeout: 10s
  # 从 prometheus 的超时时间中减去一个偏移量，防止 prometheus 先超时。
  scrape_timeout_offset: 500ms
  # 各个sql收集器之间运行间隔的秒数
  min_interval: 0s
  # 允许获取到的数据库最大的连接数， <=0 表示不限制。
  max_connections: 3
  # 允许空闲连接数的个数，<=0 不做限制
  max_idle_connections: 3

# 配置监控的数据库和抓取信息
target:
  # 配置数据库链接信息
  # sqlserver://user(用户名):password(密码)@127.0.0.1(数据库服务域名或者IP):1433(数据库服务端口号)
  data_source_name: "sqlserver://user:password@127.0.0.1:1433"
  # 收集器的名字, 对应下方 collector_files 中文件的 collector_name 的值
  collectors: [mssql_*]
collector_files: 
  - "*.collector.yml"
```

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
2. 使用以下命令创建监控用户，该用户只具有读取权限：

   ```sql
   CREATE LOGIN monitoring_user WITH PASSWORD = 'your_password';
   GRANT VIEW SERVER STATE TO monitoring_user;
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


| **指标ID**                              | **指标中文名**             | **维度ID**                              | **维度含义**                  | **单位**  |
|---------------------------------------|-----------------------|---------------------------------------|---------------------------|---------|
| up                                    | 监控插件运行状态              | -                                     | -                         | -       |
| mssql_version                         | Mssql版本号              | ProductVersion                        | 产品版本号                     | -       |
| mssql_instance_uptime                 | Mssql已运行时间            | -                                     | -                         | s       |
| mssql_database_state                  | Mssql数据库状态            | db                                    | 数据库名称                     | -       |
| mssql_local_time_seconds              | Mssql本地时间             | -                                     | -                         | s       |
| mssql_always_on_status                | Mssql AlwaysOn高可用性组状态 | -                                     | -                         | -       |
| mssql_total_page_file_bytes           | Mssql总页文件字节数          | -                                     | -                         | bytes   |
| mssql_available_page_file_bytes       | Mssql可用页文件字节数         | -                                     | -                         | bytes   |
| mssql_available_physical_memory_bytes | Mssql可用物理内存字节数        | -                                     | -                         | bytes   |
| mssql_os_memory                       | Mssql操作系统内存           | state                                 | 内存状态                      | bytes   |
| mssql_total_physical_memory_bytes     | Mssql物理内存总字节数         | -                                     | -                         | bytes   |
| mssql_memory_utilization_percentage   | Mssql内存利用率            | -                                     | -                         | percent |
| mssql_virtual_memory_bytes            | Mssql虚拟内存字节数          | -                                     | -                         | bytes   |
| mssql_batch_requests                  | Mssql批量请求             | -                                     | -                         | -       |
| mssql_processes_blocked               | Mssql进程阻塞数            | -                                     | -                         | -       |
| mssql_buffer_cache_hit_ratio          | Mssql缓冲区高速缓存命中率       | -                                     | -                         | percent |
| mssql_checkpoint_pages_sec            | Mssql检查点每秒写入页数        | -                                     | -                         | -       |
| mssql_io_stall_seconds                | Mssql I/O暂停时间         | db, operation                         | 数据库名称, 操作类型               | s       |
| mssql_io_stall_total_seconds          | Mssql总I/O暂停时间         | db                                    | 数据库名称                     | s       |
| mssql_lazy_write_sec                  | Mssql延迟写入时间           | -                                     | -                         | s       |
| mssql_page_fault_count                | Mssql页面错误次数           | -                                     | -                         | -       |
| mssql_page_life_expectancy            | Mssql页面寿命期望值          | -                                     | -                         | s       |
| mssql_page_reads_sec                  | Mssql每秒页读取数           | -                                     | -                         | -       |
| mssql_page_write_sec                  | Mssql每秒页写入数           | -                                     | -                         | -       |
| mssql_resident_memory_bytes           | Mssql常驻内存字节数          | -                                     | -                         | bytes   |
| mssql_client_connections              | Mssql客户端连接数           | db, host                              | 数据库名称, 客户端主机名称            | -       |
| mssql_connections                     | Mssql连接数              | db                                    | 数据库名称                     | -       |
| mssql_deadlocks                       | Mssql死锁数              | -                                     | -                         | -       |
| mssql_transactions                    | Mssql事务数              | db                                    | 数据库名称                     | -       |
| mssql_kill_connection_errors          | Mssql终止连接错误数          | -                                     | -                         | -       |
| mssql_user_errors                     | Mssql用户错误数            | -                                     | -                         | -       |
| mssql_database_filesize               | Mssql数据库文件大小          | db, logical_name, physical_name, type | 数据库名称, 逻辑文件名, 物理文件名, 文件类型 | bytes   |
| mssql_db_file_used_ratio              | Mssql数据库文件使用率         | db, file_name                         | 数据库名称, 文件名称               | percent |
| mssql_db_log_file_size                | Mssql数据库日志文件大小        | db, file_name                         | 数据库名称, 文件名称               | bytes   |
| mssql_last_backup_duration            | Mssql数据库距离最后一次备份时间    | db                                    | 数据库名称                     | days    |
| mssql_db_log_file_used_ratio          | Mssql数据库日志文件使用率       | db, file_name                         | 数据库名称, 文件名称               | percent |
| mssql_log_growths                     | Mssql日志增长数            | db                                    | 数据库名称                     | -       |
| scrape_duration_seconds               | 监控探针最近一次抓取时长          | -                                     | -                         | s       |

### 版本日志

#### weops_mssql_exporter 3.0.2

- weops调整

添加“小嘉”微信即可获取mssql监控指标最佳实践礼包，其他更多问题欢迎咨询

<img src="https://wedoc.canway.net/imgs/img/小嘉.jpg" width="50%" height="50%">
