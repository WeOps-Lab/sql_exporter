## 嘉为蓝鲸GBase8a数据库监控插件使用说明

### 插件功能

采集器连接数据库后执行sql，转换为监控指标。

### 版本支持：

操作系统支持: linux, windows

是否支持arm: 支持

**组件支持版本：**

GBase8a数据库

### 使用指引

登录数据库并执行命令创建蓝鲸监控账号和授权：

 ```bash
# 创建用户: weops 密码: Weops123!
CREATE USER 'weops' IDENTIFIED BY 'Weops123!';

# 要获取DB\table级别的监控信息必须拥有对应数据库的select权限
GRANT SELECT ON *.* TO 'weops';
 ```

### 参数说明

| **参数名**                | **含义**                                                               | **是否必填** | **使用举例**       |
|------------------------|----------------------------------------------------------------------|----------|----------------|
| SQL_EXPORTER_USER      | 数据库用户名(环境变量)                                                         | 是        | weops          |
| SQL_EXPORTER_PASS      | 数据库密码(环境变量)                                                          | 是        | Weops123!      |
| SQL_EXPORTER_DB_TYPE   | 数据库类型(环境变量)                                                          | 是        | gbase8a        |
| SQL_EXPORTER_HOST      | 数据库服务IP(环境变量)                                                        | 是        | 127.0.0.1      |
| SQL_EXPORTER_PORT      | 数据库服务端口(环境变量)                                                        | 是        | 5258           |
| SQL_EXPORTER_DB_NAME   | 数据库名(环境变量)                                                           | 是        | gbase          |
| -config.file           | sql_exporter.yml 采集器全局配置文件, 包含超时设置、最大连接数、目标配置、采集指标配置文件名等             | 是        | 默认已有采集器全局配置文件  |
| -log.level             | 日志级别                                                                 | 否        | info           |
| -web.listen-address    | exporter监听id及端口地址                                                    | 否        | 127.0.0.1:9601 |
| collector.file.content | *.collector.yml 采集指标配置文件, 包含指标名、维度、sql等内容。**注意！该参数为文件参数，非探针执行文件参数！** | 是        | 默认已有标准采集指标配置文件 |


### 指标列表
| **指标ID**                               | **指标中文名**         | **维度ID**           | **维度含义**   | **单位**  |
|----------------------------------------|-------------------|--------------------|------------|---------|
| up                                     | 插件运行状态            | -                  | -          | -       |
| gbase8a_exporter_total_dc              | DC总数量             | host               | 服务器名       | -       |
| gbase8a_exporter_unlocked_dc           | 没有被锁住的DC总数量       | host               | 服务器名       | -       |
| gbase8a_exporter_total_dc_size         | DC占用总内存大小         | host               | 服务器名       | bytes   |
| gbase8a_exporter_unlocked_dc_size      | 没有被锁住的DC占用内存大小    | host               | 服务器名       | bytes   |
| gbase8a_exporter_hot_total_dc          | 热数据DC数量           | host               | 服务器名       | -       |
| gbase8a_exporter_hot_unlocked_dc       | 没有被锁住的热数据DC数量     | host               | 服务器名       | -       |
| gbase8a_exporter_hot_total_dc_size     | 热数据DC占用总内存大小      | host               | 服务器名       | bytes   |
| gbase8a_exporter_hot_unlocked_dc_size  | 没有被锁住的热数据DC占用内存大小 | host               | 服务器名       | bytes   |
| gbase8a_exporter_cold_total_dc         | 冷数据DC数量           | host               | 服务器名       | -       |
| gbase8a_exporter_cold_unlocked_dc      | 没有被锁住的冷数据DC数量     | host               | 服务器名       | -       |
| gbase8a_exporter_cold_total_dc_size    | 冷数据DC占用总内存大小      | host               | 服务器名       | bytes   |
| gbase8a_exporter_cold_unlocked_dc_size | 没有被锁住的冷数据DC占用内存大小 | host               | 服务器名       | bytes   |
| gbase8a_exporter_dc_hit_rate           | DC命中率             | host               | 服务器名       | percent |
| gbase8a_exporter_heap_size             | 堆总大小              | host, heap_type    | 服务器名, 堆类型  | bytes   |
| gbase8a_exporter_used_in_heap          | 堆使用中的大小           | host, heap_type    | 服务器名, 堆类型  | bytes   |
| gbase8a_exporter_used_in_system        | 从操作系统额外申请的堆大小     | host, heap_type    | 服务器名, 堆类型  | bytes   |
| gbase8a_exporter_max_used_block        | 当前堆中最大块的大小        | host, heap_type    | 服务器名, 堆类型  | bytes   |
| gbase8a_exporter_max_free_block        | 当前堆中最大可用块的大小      | host, heap_type    | 服务器名, 堆类型  | bytes   |
| gbase8a_exporter_used_blocks           | 堆中使用的块个数          | host, heap_type    | 服务器名, 堆类型  | -       |
| gbase8a_exporter_session_current_mem   | session当前使用的内存总量  | host               | 服务器名       | bytes   |
| gbase8a_exporter_session_temp_space    | session临时空间使用总量   | host               | 服务器名       | bytes   |
| gbase8a_exporter_sessions              | 当前session连接数      | host               | 服务器名       | -       |
| gbase8a_exporter_running_threads       | 当前运行中的线程数         | -                  | -          | -       |
| gbase8a_exporter_memory_upper_limit    | 内存上限大小            | host               | 服务器名       | bytes   |
| gbase8a_exporter_phsical_memory_usage  | 物理内存使用率           | host               | 服务器名       | percent |
| gbase8a_exporter_memory_current_used   | 内存当前使用量           | host               | 服务器名       | bytes   |
| gbase8a_exporter_memory_peak_used      | 内存使用峰值            | host               | 服务器名       | bytes   |
| gbase8a_exporter_table_max_rowid       | 数据表历史最大rowid      | dbname, table_name | 数据库名, 表名   | -       |
| gbase8a_exporter_table_deleted_rows    | 数据表标记为已删除的数据行数    | dbname, table_name | 数据库名, 表名   | -       |
| gbase8a_exporter_table_rows            | 数据表行数             | dbname, table_name | 数据库名, 表名   | -       |
| gbase8a_exporter_table_storage_size    | 数据表占用存储空间         | dbname, table_name | 数据库名, 表名   | bytes   |
| gbase8a_exporter_table_deletable_size  | 数据表标记为已删除的空间大小    | dbname, table_name | 数据库名, 表名   | bytes   |
| gbase8a_exporter_table_shrinkable_size | 数据表可收缩空间大小        | dbname, table_name | 数据库名, 表名   | bytes   |
| gbase8a_exporter_table_delete_ratio    | 数据表数据空洞率          | dbname, table_name | 数据库名, 表名   | percent |
| gbase8a_exporter_db_tables             | 数据库中表数量           | dbname, table_name | 数据库名, 表名   | -       |
| gbase8a_exporter_db_storage_size       | 数据库占用空间           | dbname, table_name | 数据库名, 表名   | bytes   |
| gbase8a_exporter_db_deletable_size     | 数据库中标记为已删除的数据大小   | dbname, table_name | 数据库名, 表名   | bytes   |
| gbase8a_exporter_db_shrinkable_size    | 数据库中可收缩空间大小       | dbname, table_name | 数据库名, 表名   | bytes   |
| gbase8a_exporter_file_disk_used_size   | 数据库文件磁盘使用空间       | host, dir_type     | 服务器名, 文件类型 | bytes   |


### 版本日志

#### weops_gbase8a_exporter 1.0.1
- weops调整
