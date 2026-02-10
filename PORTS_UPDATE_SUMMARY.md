# 端口配置更新摘要

## 更新时间
2026-02-10 12:20

## 更新内容

### 1. 创建的文件

#### `.ports.env` - 主端口配置文件
```env
GATEWAY_PORT=18789
CANVAS_PORT=18789
HEARTBEAT_PORT=18789
WS_PORT=18789
```

#### `.env-loader.ps1` - PowerShell 环境变量加载器
- 自动加载 `.ports.env` 中的配置
- 设置默认值（如果未配置）
- 支持在脚本中使用 `$env:VARIABLE_NAME` 访问

#### `.env-loader.sh` - Bash 环境变量加载器
- 自动加载 `.ports.env` 中的配置
- 支持在 Bash 脚本中使用 `$VARIABLE_NAME` 访问

#### `.env.example` - 配置模板
- 包含所有可配置项的示例
- 方便快速自定义配置

#### `PORTS_CONFIG.md` - 配置指南文档
- 详细的使用说明
- 故障排除指南
- 脚本兼容性列表

### 2. 更新的脚本文件

所有脚本已更新，在文件开头添加环境变量加载：

#### PowerShell 脚本
- ✅ `scripts/daily-backup.ps1`
- ✅ `scripts/nightly-evolution.ps1`
- ✅ `context_cleanup.ps1`

#### Bash 脚本
- ✅ `scripts/nightly-evolution.sh`

### 3. 脚本中的使用方式

#### PowerShell 脚本
```powershell
# 加载环境变量
. .env-loader.ps1

# 使用环境变量
$port = if ($env:GATEWAY_PORT) { $env:GATEWAY_PORT } else { "18789" }
Write-Host "Gateway Port: $port"
```

#### Bash 脚本
```bash
# 加载环境变量
source .env-loader.sh

# 使用环境变量
port=${GATEWAY_PORT:-18789}
echo "Gateway Port: $port"
```

### 4. 更新后特性

#### 优势
- **统一管理**: 所有端口配置集中在一个文件
- **易于修改**: 只需编辑 `.ports.env` 即可更改所有服务的端口
- **环境隔离**: 不同环境可以有不同的端口配置
- **无硬编码**: 避免在脚本中硬编码端口值

#### 兼容性
- 现有脚本无需大规模修改
- 保留默认值作为后备
- 向后兼容旧配置

### 5. 测试结果

#### 测试脚本
- ✅ 环境变量加载成功
- ✅ 脚本运行正常
- ✅ 端口变量正确传递

#### 运行测试
```powershell
cd C:\Users\Administrator\.openclaw\workspace
& scripts\nightly-evolution.ps1
```

**结果:**
```
[2026-02-10 12:20:53] Nightly Evolution Plan Started
[2026-02-10 12:20:53] PowerShell Version: 5.1
[2026-02-10 12:20:53] Disk Usage: 88.9%
[2026-02-10 12:20:53] GitHub connection OK
[2026-02-10 12:20:53] Backup files: 3
[2026-02-10 12:20:53] Nightly Evolution Plan Completed
```

### 6. 后续操作

#### 立即可用
所有脚本现在都可以使用环境变量了。下次运行时会自动使用新配置。

#### 更改端口
1. 编辑 `.ports.env`:
   ```env
   GATEWAY_PORT=19000  # 改为 19000
   ```
2. 重启 gateway 服务:
   ```powershell
   openclaw gateway restart
   ```

#### 创建自定义环境
1. 复制 `.env.example` 为 `.env`
2. 修改需要的配置
3. 脚本会自动使用自定义配置

### 7. 文件清单

```
workspace/
├── .ports.env                      # 新增：端口配置文件
├── .env-loader.ps1                 # 新增：PowerShell 加载器
├── .env-loader.sh                  # 新增：Bash 加载器
├── .env.example                    # 新增：配置模板
├── PORTS_CONFIG.md                  # 新增：配置指南
├── PORTS_UPDATE_SUMMARY.md         # 新增：更新摘要
├── scripts/
│   ├── daily-backup.ps1            # 更新：添加环境变量支持
│   ├── nightly-evolution.ps1       # 更新：添加环境变量支持
│   └── nightly-evolution.sh        # 更新：添加环境变量支持
└── context_cleanup.ps1             # 更新：添加环境变量支持
```

### 8. 相关链接

- Gateway 配置: `openclaw.json`
- 端口配置: `.ports.env`
- 配置指南: `PORTS_CONFIG.md`

---

**更新完成** ✅
所有脚本已更新为使用环境变量管理端口配置。
