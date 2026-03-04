# 开发工具包 (Dev Toolkit)

整合了灵眸的开发工具集，包括API开发、数据库管理和SQL操作。

## 概述

本技能包整合了三个核心开发工具：

### 1. API Development (原 api-dev 技能)
REST和GraphQL API的完整开发工具，涵盖API生命周期所有阶段。

**核心功能：**
- API端点脚手架（scaffolding）
- 使用curl测试API
- 生成OpenAPI/Swagger文档
- 模拟外部API
- HTTP请求/响应调试
- 负载测试

**使用场景：**
- 创建新API端点
- 使用curl测试API
- 生成OpenAPI规范
- 开发时模拟外部服务
- 调试HTTP问题
- API负载测试

**快速开始：**
```bash
# GET请求
curl -s https://api.example.com/users | jq .

# POST JSON
curl -s -X POST https://api.example.com/users \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"name": "Alice", "email": "alice@example.com"}' | jq .

# 生成OpenAPI文档
openapi-generator generate -i swagger.json -g typescript-axios -o ./client
```

**支持的API类型：**
- REST API
- GraphQL API
- OpenAPI/Swagger
- GraphQL Schema

---

### 2. Database Manager (原 database 技能)
多数据库管理工具，支持连接、查询和管理。

**核心功能：**
- 连接SQL和NoSQL数据库
- 执行查询
- 模式管理
- 数据导入/导出
- 备份和恢复
- 性能监控

**支持数据库：**
- PostgreSQL
- MySQL
- SQLite
- MongoDB
- Redis

**快速开始：**
```
# 连接数据库
"Connect to PostgreSQL database"

# 执行查询
"Run query: SELECT * FROM users LIMIT 10"

# 导出数据
"Export table to CSV"

# 备份数据库
"Backup database to file"
```

**安全规则：**
1. 删除/Drop操作前**必须**确认
2. 无WHERE子句的查询**警告**
3. 敏感操作需要权限

---

### 3. SQL Toolkit (原 sql-toolkit 技能)
关系型数据库直接操作工具，专注于SQLite、PostgreSQL、MySQL。

**核心功能：**
- 数据库模式设计和修改
- 复杂查询编写（joins、聚合、窗口函数、CTE）
- 迁移脚本创建
- 索引优化和EXPLAIN分析
- 数据库备份和恢复
- 零配置SQLite快速数据探索

**支持数据库：**
- SQLite（零配置）
- PostgreSQL
- MySQL

**快速开始 - SQLite（零配置）：**
```bash
# 创建/打开数据库
sqlite3 mydb.sqlite

# 直接导入CSV
sqlite3 mydb.sqlite ".mode csv" ".import data.csv mytable" "SELECT COUNT(*) FROM mytable;"

# 一行查询
sqlite3 mydb.sqlite "SELECT * FROM users WHERE created_at > '2026-01-01' LIMIT 10;"

# 导出为CSV
sqlite3 -header -csv mydb.sqlite "SELECT * FROM orders;" > orders.csv

# 交互模式
sqlite3 -header -column mydb.sqlite
```

**模式操作：**
```sql
-- 创建表
CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    email TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 修改表
ALTER TABLE users ADD COLUMN phone TEXT;

-- 删除表
DROP TABLE users;
```

**迁移脚本：**
```sql
-- 迁移1: 创建表
CREATE TABLE users (...);

-- 迁移2: 添加字段
ALTER TABLE users ADD COLUMN phone TEXT;

-- 迁移3: 修改字段
ALTER TABLE users ALTER COLUMN email SET NOT NULL;
```

**性能优化：**
```sql
-- 添加索引
CREATE INDEX idx_users_email ON users(email);

-- 分析查询
EXPLAIN QUERY PLAN SELECT * FROM users WHERE email = 'test@example.com';

-- 分析表
ANALYZE;

-- 优化表
VACUUM;
```

---

## 集成架构

### 开发工具协作
```
Dev Toolkit
├── API Development (API开发)
│   ├── REST API
│   ├── GraphQL API
│   ├── OpenAPI文档
│   └── API测试
│       ↓
├── Database Manager (数据库管理)
│   ├── SQL数据库
│   ├── NoSQL数据库
│   ├── 数据导入/导出
│   └── 备份/恢复
│       ↓
└── SQL Toolkit (SQL工具包)
    ├── SQLite（零配置）
    ├── PostgreSQL
    └── MySQL
```

### 典型工作流

**场景1: API开发**
```
1. 使用API Development创建端点
2. 使用SQL Toolkit设计数据库
3. 使用Database Manager管理数据库
4. 使用API Development测试API
```

**场景2: 数据库开发**
```
1. 使用SQL Toolkit设计Schema
2. 创建迁移脚本
3. 使用Database Manager执行迁移
4. 使用SQL Toolkit优化查询
```

**场景3: 数据迁移**
```
1. 使用Database Manager导出数据
2. 使用SQL Toolkit导入到新数据库
3. 验证数据完整性
4. 使用API Development测试新API
```

---

## 目录结构

```
skills/dev-toolkit/
├── SKILL.md                    # 本文档
├── api-dev/                    # API开发模块
│   ├── scripts/
│   └── config/
├── database/                   # 数据库管理模块
│   ├── scripts/
│   └── config/
└── sql-toolkit/                # SQL工具包模块
    ├── scripts/
    └── config/
```

---

## 性能指标

| 工具 | 指标 | 目标值 |
|------|------|--------|
| API Development | 请求响应 | <100ms |
| Database Manager | 查询响应 | <1s |
| SQL Toolkit | 查询响应 | <500ms |
| SQL Toolkit | 迁移执行 | <5s |

---

## 最佳实践

### API Development
1. **RESTful设计** - 遵循REST原则
2. **GraphQL** - 使用GraphQL简化API
3. **OpenAPI** - 保持文档更新
4. **测试驱动** - 先测试后部署

### Database Manager
1. **安全第一** - 删除操作前确认
2. **权限管理** - 最小权限原则
3. **定期备份** - 自动化备份策略
4. **监控性能** - 定期分析慢查询

### SQL Toolkit
1. **SQLite快速原型** - 开发阶段使用
2. **迁移版本控制** - 使用迁移脚本
3. **索引优化** - 为常用查询添加索引
4. **EXPLAIN分析** - 优化慢查询

---

## 安全规则

### Database Manager
1. **ALWAYS**确认DELETE/DROP操作
2. **WARN**无WHERE子句的查询
3. **SECURE**敏感数据加密
4. **LOG**所有操作记录

### SQL Toolkit
1. **BACKUP**执行前备份数据
2. **TEST**迁移在测试环境
3. **VALIDATE**数据完整性
4. **AUDIT**关键操作

---

## 资源

### API Development
- OpenAPI规范: https://swagger.io/specification/
- GraphQL: https://graphql.org/
- REST最佳实践: https://restfulapi.net/

### Database Manager
- PostgreSQL: https://www.postgresql.org/
- MySQL: https://www.mysql.com/
- MongoDB: https://.../

### SQL Toolkit
- SQLite: https://sqlite.org/
- PostgreSQL文档: https://www.postgresql.org/docs/
- MySQL文档: https://dev.mysql.com/doc/

---

## 扩展和定制

### 自定义API模板
```bash
# 在 api-dev/templates/ 中创建
```

### 自定义数据库连接
```json
{
  "connections": {
    "production": {
      "host": "...",
      "port": 5432,
      "database": "...",
      "username": "...",
      "password": "..."
    }
  }
}
```

### SQL工具包配置
```json
{
  "default_db": "sqlite",
  "migrations_path": "./migrations",
  "optimize_on_save": true
}
```

---

## 更新日志

### v1.0.0 (2026-02-26)
- 整合三个开发工具
- 创建统一使用指南
- 建立工具协作流程
- 优化目录结构

---

## 版本信息

- **整合版本**: v3.2.6
- **整合日期**: 2026-02-26
- **原始技能**: api-dev, database, sql-toolkit
