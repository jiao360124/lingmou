# 集中配置管理器

## 功能
- 统一配置加载
- 配置验证
- 环境变量管理
- 配置热更新

## 配置文件结构

### 主配置文件 (config.json)
```json
{
    "global": {
        "version": "1.0.0",
        "environment": "development",
        "timezone": "Asia/Shanghai"
    },
    "api": {
        "timeout": 30,
        "retry": 3,
        "rateLimit": 60
    },
    "skills": {
        "copilot": {
            "enabled": true,
            "timeout": 20,
            "patterns": ["javascript", "python"]
        },
        "auto-gpt": {
            "enabled": true,
            "timeout": 60,
            "maxTasks": 10
        },
        "rag": {
            "enabled": true,
            "indexPath": "./data/knowledge-base.json",
            "maxResults": 10
        }
    },
    "storage": {
        "cachePath": "./data/cache",
        "logPath": "./logs",
        "maxCacheSize": "1GB"
    },
    "logging": {
        "level": "info",
        "format": "json",
        "output": "file"
    }
}
```

### 环境特定配置 (.env)
```bash
# development
ENV=development
DEBUG=true

# production
ENV=production
DEBUG=false
```

## 使用方法

### 加载配置
```powershell
.\config-manager.ps1 -Action load -Profile "development"
```

### 获取配置值
```powershell
# 获取全局配置
.\config-manager.ps1 -Action get -Key "global.environment"

# 获取技能配置
.\config-manager.ps1 -Action get -Key "skills.copilot.enabled"

# 获取特定技能的所有配置
.\config-manager.ps1 -Action get -Skill "copilot"
```

### 设置配置值
```powershell
# 更新单个值
.\config-manager.ps1 -Action set -Key "skills.copilot.timeout" -Value 25

# 批量更新
.\config-manager.ps1 -Action set -Config @{
    "skills.auto-gpt.enabled" = $true
    "api.timeout" = 40
}
```

### 验证配置
```powershell
.\config-manager.ps1 -Action validate
```

### 保存配置
```powershell
.\config-manager.ps1 -Action save
```

### 重置为默认
```powershell
.\config-manager.ps1 -Action reset
```

## 配置优先级

配置加载顺序（高到低）：
1. 环境变量（最高优先级）
2. 配置文件
3. 默认值（最低优先级）

## 配置验证规则

系统会自动验证以下内容：
- 必需字段是否存在
- 数据类型是否正确
- 值是否在有效范围内
- 路径是否存在
- 权限是否足够

验证失败会返回详细错误信息。

## 配置热更新

修改配置后可以立即生效（部分配置）：
```powershell
.\config-manager.ps1 -Action reload -Section "logging"
```

支持热更新的配置：
- 日志级别
- 日志格式
- 缓存大小
- 超时设置
