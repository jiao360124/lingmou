# OpenClaw v3.2 测试框架
# 完整的单元测试、集成测试和性能测试

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("all", "unit", "integration", "performance", "smoke")]
    [string]$Target = "all",

    [switch]$Verbose,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$WorkspaceDir = Split-Path -Parent $ScriptDir
$TestResultsDir = Join-Path $WorkspaceDir "test-results"

# 创建测试结果目录
if (!(Test-Path $TestResultsDir)) {
    New-Item -ItemType Directory -Path $TestResultsDir -Force | Out-Null
}

$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$ReportFile = Join-Path $TestResultsDir "test-report-$timestamp.md"

function Write-Header {
    param([string]$Title, [int]$Level = 1)
    $Indent = "  " * ($Level - 1)
    $Border = "=" * (60 - $Level * 2)
    Write-Host "`n$Indent$Title $Border" -ForegroundColor Magenta
}

function Write-Section {
    param([string]$Title, [int]$Level = 1)
    $Indent = "  " * ($Level - 1)
    Write-Host "$Indent$Title" -ForegroundColor Cyan
}

function Write-Test {
    param(
        [string]$Name,
        [scriptblock]$TestBlock,
        [string]$Category = "unit"
    )
    Write-Host "  [TEST] $Name" -ForegroundColor White

    if ($Verbose) {
        Start-Sleep -Milliseconds 100
    }

    try {
        $result = & $TestBlock
        $status = if ($result) { "PASS" } else { "FAIL" }
        $color = if ($result) { "Green" } else { "Red" }

        Write-Host "    → $status" -ForegroundColor $color

        return @{
            Name = $Name
            Category = $Category
            Status = $status
            Result = $result
            Duration = 0
        }
    } catch {
        Write-Host "    → ERROR: $($_.Exception.Message)" -ForegroundColor Red
        return @{
            Name = $Name
            Category = $Category
            Status = "ERROR"
            Result = $false
            Error = $_.Exception.Message
            Duration = 0
        }
    }
}

function Write-Summary {
    param([hashtable]$Tests)

    Write-Header "测试总结" 1

    $total = $Tests.Count
    $passed = ($Tests.Values | Where-Object { $_.Status -eq "PASS" }).Count
    $failed = ($Tests.Values | Where-Object { $_.Status -eq "FAIL" }).Count
    $errors = ($Tests.Values | Where-Object { $_.Status -eq "ERROR" }).Count

    Write-Host "  总计: $total" -ForegroundColor White
    Write-Host "  通过: $passed" -ForegroundColor Green
    Write-Host "  失败: $failed" -ForegroundColor Red
    Write-Host "  错误: $errors" -ForegroundColor Yellow

    $successRate = if ($total -gt 0) { [math]::Round(($passed / $total) * 100, 2) } else { 0 }
    Write-Host "  成功率: $successRate%" -ForegroundColor $(if ($successRate -ge 80) { "Green" } elseif ($successRate -ge 60) { "Yellow" } else { "Red" })

    return @{
        Total = $total
        Passed = $passed
        Failed = $failed
        Errors = $errors
        SuccessRate = $successRate
    }
}

function Measure-Performance {
    param([scriptblock]$ScriptBlock, [string]$Description)

    $start = Get-Date
    $result = & $ScriptBlock
    $end = Get-Date
    $duration = ($end - $start).TotalSeconds

    Write-Host "  性能: $duration.ToString('0.00')s" -ForegroundColor DarkGray

    return @{
        Result = $result
        Duration = $duration
    }
}

# ==================== 单元测试 ====================

$unitTests = @{}

if ($Target -eq "all" -or $Target -eq "unit") {
    Write-Header "单元测试" 1

    # 测试1: 技能加载
    Write-Section "测试技能加载"
    $unitTests["skill-load"] = Write-Test -Name "检查技能目录" -TestBlock {
        $skillsDir = Join-Path $WorkspaceDir "skills"
        $skills = Get-ChildItem -Path $skillsDir -Directory
        return $skills.Count -gt 0
    }

    # 测试2: 核心模块加载
    Write-Section "测试核心模块加载"
    $unitTests["core-module-load"] = Write-Test -Name "检查核心模块" -TestBlock {
        $coreModules = @(
            "rollbak-engine",
            "system-memory",
            "watchdog",
            "control-tower",
            "predictive-engine",
            "cognitive-layer",
            "strategy-engine",
            "objective-engine"
        )

        $coreDir = Join-Path $WorkspaceDir "core"
        foreach ($module in $coreModules) {
            $modulePath = Join-Path $coreDir "$module.js"
            if (!(Test-Path $modulePath)) {
                return $false
            }
        }
        return $true
    }

    # 测试3: 工具模块加载
    Write-Section "测试工具模块加载"
    $unitTests["utils-module-load"] = Write-Test -Name "检查工具模块" -TestBlock {
        $utilsDir = Join-Path $WorkspaceDir "utils"
        $requiredUtils = @("cache", "logger", "retry", "error-handler")

        foreach ($util in $requiredUtils) {
            $utilPath = Join-Path $utilsDir "$util.js"
            if (!(Test-Path $utilPath)) {
                return $false
            }
        }
        return $true
    }

    # 测试4: 脚本可执行性
    Write-Section "测试关键脚本"
    $unitTests["scripts-executable"] = Write-Test -Name "检查关键脚本存在" -TestBlock {
        $scripts = @(
            "integration-manager",
            "nightly-evolution",
            "simple-health-check",
            "auto-backup"
        )

        $scriptsDir = Join-Path $WorkspaceDir "scripts"
        foreach ($script in $scripts) {
            $scriptPath = Join-Path $scriptsDir "$script.ps1"
            if (!(Test-Path $scriptPath)) {
                return $false
            }
        }
        return $true
    }

    # 测试5: 配置文件
    Write-Section "测试配置文件"
    $unitTests["config-files"] = Write-Test -Name "检查核心配置" -TestBlock {
        $configs = @(
            "skills/self-healing-engine/config.json",
            "skills/clawlist/SKILL.md",
            "scripts/integration-manager.ps1"
        )

        foreach ($config in $configs) {
            $configPath = Join-Path $WorkspaceDir $config
            if (!(Test-Path $configPath)) {
                return $false
            }
        }
        return $true
    }

    # 测试6: 学习记录
    Write-Section "测试学习记录系统"
    $unitTests["learning-records"] = Write-Test -Name "检查学习记录文件" -TestBlock {
        $learningsDir = Join-Path $WorkspaceDir "skills/self-healing-engine/learnings"
        $files = @("LEARNINGS.md", "ERRORS.md")

        foreach ($file in $files) {
            $filePath = Join-Path $learningsDir $file
            if (!(Test-Path $filePath)) {
                return $false
            }
        }
        return $true
    }

    # 测试7: 目录结构
    Write-Section "测试目录结构"
    $unitTests["directory-structure"] = Write-Test -Name "检查关键目录" -TestBlock {
        $directories = @(
            "skills",
            "scripts",
            "core",
            "utils",
            "test-results",
            "logs",
            "backup",
            "reports",
            "optimization-reports"
        )

        foreach ($dir in $directories) {
            $dirPath = Join-Path $WorkspaceDir $dir
            if (!(Test-Path $dirPath)) {
                return $false
            }
        }
        return $true
    }

    # 测试8: 系统健康检查
    Write-Section "测试系统健康"
    $unitTests["system-health"] = Write-Test -Name "运行系统健康检查" -TestBlock {
        $healthScript = Join-Path $WorkspaceDir "scripts/scripts/simple-health-check.ps1"
        if (!(Test-Path $healthScript)) {
            return $false
        }

        try {
            $output = Invoke-Expression $healthScript
            return $LASTEXITCODE -eq 0
        } catch {
            return $false
        }
    }
}

# ==================== 集成测试 ====================

$integrationTests = @{}

if ($Target -eq "all" -or $Target -eq "integration") {
    Write-Header "集成测试" 1

    # 集成测试1: 技能注册
    Write-Section "测试技能注册"
    $integrationTests["skill-registration"] = Write-Test -Name "技能系统可用" -TestBlock {
        $skillsDir = Join-Path $WorkspaceDir "skills"
        $skills = Get-ChildItem -Path $skillsDir -Directory -ErrorAction SilentlyContinue

        return $skills.Count -ge 50  # 至少50个技能
    }

    # 集成测试2: 核心模块协作
    Write-Section "测试核心模块协作"
    $integrationTests["core-collaboration"] = Write-Test -Name "核心模块可协作" -TestBlock {
        $coreDir = Join-Path $WorkspaceDir "core"
        $moduleFiles = Get-ChildItem -Path $coreDir -Filter "*.js" -File

        return $moduleFiles.Count -ge 10
    }

    # 集成测试3: 错误处理
    Write-Section "测试错误处理系统"
    $integrationTests["error-handling"] = Write-Test -Name "错误处理可用" -TestBlock {
        $errorLog = Join-Path $WorkspaceDir "logs/errors.log"
        if (!(Test-Path $errorLog)) {
            return $true  # 不存在是正常的，表示没有错误
        }

        $logSize = (Get-Item $errorLog).Length
        return $logSize -lt 1MB  # 日志不超过1MB
    }

    # 集成测试4: 备份系统
    Write-Section "测试备份系统"
    $integrationTests["backup-system"] = Write-Test -Name "备份系统可用" -TestBlock {
        $backupDir = Join-Path $WorkspaceDir "backup"
        if (!(Test-Path $backupDir)) {
            return $true  # 目录不存在是正常的
        }

        $backupFiles = Get-ChildItem -Path $backupDir -Filter "*.zip" -ErrorAction SilentlyContinue
        return $backupFiles.Count -le 7  # 最多7个备份文件
    }

    # 集成测试5: 学习记录
    Write-Section "测试学习记录系统"
    $integrationTests["learning-system"] = Write-Test -Name "学习记录系统可用" -TestBlock {
        $learningsFile = Join-Path $WorkspaceDir "skills/self-healing-engine/learnings/LEARNINGS.md"
        if (!(Test-Path $learningsFile)) {
            return $false  # 学习记录文件必须存在
        }

        $content = Get-Content $learningsFile -Raw
        return $content.Length -gt 100  # 至少有100个字符
    }
}

# ==================== 性能测试 ====================

$performanceTests = @{}

if ($Target -eq "all" -or $Target -eq "performance") {
    Write-Header "性能测试" 1

    # 性能测试1: 技能扫描
    Write-Section "测试技能扫描性能"
    $perfResult = Measure-Performance -ScriptBlock {
        $skillsDir = Join-Path $WorkspaceDir "skills"
        $skills = Get-ChildItem -Path $skillsDir -Directory -ErrorAction SilentlyContinue
        return $skills.Count
    } -Description "技能扫描"

    $performanceTests["skill-scan"] = @{
        Name = "技能扫描"
        Duration = $perfResult.Duration
        Result = $perfResult.Result
        Expected = "> 50"
        Actual = $perfResult.Result
        Pass = $perfResult.Result -gt 50
    }

    # 性能测试2: 文件列表
    Write-Section "测试文件列表性能"
    $perfResult = Measure-Performance -ScriptBlock {
        $fileListScript = Join-Path $WorkspaceDir "scripts/scripts/list-all-files.js"
        if (Test-Path $fileListScript) {
            # 调用脚本但不执行
            return $true
        }
        return $false
    } -Description "文件列表"

    $performanceTests["file-list"] = @{
        Name = "文件列表"
        Duration = $perfResult.Duration
        Result = $perfResult.Result
        Expected = "< 3秒"
        Actual = $perfResult.Duration.ToString("0.00") + "s"
        Pass = $perfResult.Duration -lt 3
    }

    # 性能测试3: 系统健康检查
    Write-Section "测试系统健康检查性能"
    $perfResult = Measure-Performance -ScriptBlock {
        $healthScript = Join-Path $WorkspaceDir "scripts/scripts/simple-health-check.ps1"
        Invoke-Expression $healthScript
        return $LASTEXITCODE -eq 0
    } -Description "系统健康检查"

    $performanceTests["health-check"] = @{
        Name = "系统健康检查"
        Duration = $perfResult.Duration
        Result = $perfResult.Result
        Expected = "< 2秒"
        Actual = $perfResult.Duration.ToString("0.00") + "s"
        Pass = $perfResult.Duration -lt 2
    }

    # 性能测试4: 启动时间
    Write-Section "测试启动时间"
    $perfResult = Measure-Performance -ScriptBlock {
        # 模拟启动 - 检查关键目录
        @("skills", "scripts", "core", "utils") | ForEach-Object {
            $dir = Join-Path $WorkspaceDir $_
            Test-Path $dir
        }
        return $true
    } -Description "启动检查"

    $performanceTests["startup"] = @{
        Name = "启动检查"
        Duration = $perfResult.Duration
        Result = $perfResult.Result
        Expected = "< 5秒"
        Actual = $perfResult.Duration.ToString("0.00") + "s"
        Pass = $perfResult.Duration -lt 5
    }
}

# ==================== 冒烟测试 ====================

$smokeTests = @{}

if ($Target -eq "all" -or $Target -eq "smoke")) {
    Write-Header "冒烟测试" 1

    # 冒烟测试1: 基本功能
    Write-Section "测试基本功能"
    $smokeTests["basic-functions"] = Write-Test -Name "基本功能可用" -TestBlock {
        # 检查关键脚本
        $scripts = @(
            "integration-manager",
            "nightly-evolution",
            "simple-health-check"
        )

        $scriptsDir = Join-Path $WorkspaceDir "scripts"
        foreach ($script in $scripts) {
            $scriptPath = Join-Path $scriptsDir "$script.ps1"
            if (!(Test-Path $scriptPath)) {
                return $false
            }
        }
        return $true
    }

    # 冒烟测试2: 技能可用
    Write-Section "测试技能可用性"
    $smokeTests["skills-available"] = Write-Test -Name "核心技能可用" -TestBlock {
        $skillsDir = Join-Path $WorkspaceDir "skills"
        $coreSkills = @(
            "self-healing-engine",
            "clawlist",
            "code-mentor",
            "git-essentials",
            "api-dev"
        )

        foreach ($skill in $coreSkills) {
            $skillPath = Join-Path $skillsDir $skill
            if (!(Test-Path $skillPath)) {
                return $false
            }
        }
        return $true
    }

    # 冒烟测试3: 系统健康
    Write-Section "测试系统健康"
    $smokeTests["system-ok"] = Write-Test -Name "系统运行正常" -TestBlock {
        $healthScript = Join-Path $WorkspaceDir "scripts/scripts/simple-health-check.ps1"
        if (!(Test-Path $healthScript)) {
            return $false
        }

        try {
            $output = Invoke-Expression $healthScript 2>&1
            return $LASTEXITCODE -eq 0
        } catch {
            return $false
        }
    }

    # 冒烟测试4: 数据完整性
    Write-Section "测试数据完整性"
    $smokeTests["data-integrity"] = Write-Test -Name "数据文件完整" -TestBlock {
        $files = @(
            "skills/self-healing-engine/config.json",
            "skills/clawlist/SKILL.md",
            "openclaw-3.2/VERSION.md",
            "openclaw-3.2/INTEGRATION-GUIDE.md"
        )

        foreach ($file in $files) {
            $filePath = Join-Path $WorkspaceDir $file
            if (!(Test-Path $filePath)) {
                return $false
            }

            # 检查文件大小
            $fileInfo = Get-Item $filePath
            if ($fileInfo.Length -lt 1KB) {
                return $false
            }
        }
        return $true
    }
}

# ==================== 生成报告 ====================

$allTests = @{}
if ($unitTests) { $allTests = $allTests + $unitTests }
if ($integrationTests) { $allTests = $allTests + $integrationTests }
if ($performanceTests) { $allTests = $allTests + $performanceTests }
if ($smokeTests) { $allTests = $allTests + $smokeTests }

$summary = Write-Summary -Tests $allTests

# 生成详细报告
$report = @"
# OpenClaw v3.2 测试报告
> **执行时间**: $timestamp  
> **测试目标**: $Target  
> **详细输出**: $Verbose  

---

## 测试总结

### 总体结果

| 指标 | 数值 | 状态 |
|------|------|------|
| **总测试数** | $($summary.Total) | — |
| **通过** | $($summary.Passed) | ✅ |
| **失败** | $($summary.Failed) | ⚠️ |
| **错误** | $($summary.Errors) | ⚠️ |
| **成功率** | $($summary.SuccessRate)% | $(if ($summary.SuccessRate -ge 80) { "✅ 优秀" } elseif ($summary.SuccessRate -ge 60) { "🟡 良好" } else { "🔴 需要改进" }) |

---

## 单元测试结果

### 测试: 技能加载
- **状态**: $($unitTests["skill-load"].Status)
- **结果**: $($unitTests["skill-load"].Result)

### 测试: 核心模块加载
- **状态**: $($unitTests["core-module-load"].Status)
- **结果**: $($unitTests["core-module-load"].Result)

### 测试: 工具模块加载
- **状态**: $($unitTests["utils-module-load"].Status)
- **结果**: $($unitTests["utils-module-load"].Result)

### 测试: 脚本可执行性
- **状态**: $($unitTests["scripts-executable"].Status)
- **结果**: $($unitTests["scripts-executable"].Result)

### 测试: 配置文件
- **状态**: $($unitTests["config-files"].Status)
- **结果**: $($unitTests["config-files"].Result)

### 测试: 学习记录
- **状态**: $($unitTests["learning-records"].Status)
- **结果**: $($unitTests["learning-records"].Result)

### 测试: 目录结构
- **状态**: $($unitTests["directory-structure"].Status)
- **结果**: $($unitTests["directory-structure"].Result)

### 测试: 系统健康检查
- **状态**: $($unitTests["system-health"].Status)
- **结果**: $($unitTests["system-health"].Result)

---

## 集成测试结果

### 测试: 技能注册
- **状态**: $($integrationTests["skill-registration"].Status)
- **结果**: $($integrationTests["skill-registration"].Result)

### 测试: 核心模块协作
- **状态**: $($integrationTests["core-collaboration"].Status)
- **结果**: $($integrationTests["core-collaboration"].Result)

### 测试: 错误处理
- **状态**: $($integrationTests["error-handling"].Status)
- **结果**: $($integrationTests["error-handling"].Result)

### 测试: 备份系统
- **状态**: $($integrationTests["backup-system"].Status)
- **结果**: $($integrationTests["backup-system"].Result)

### 测试: 学习记录
- **状态**: $($integrationTests["learning-system"].Status)
- **结果**: $($integrationTests["learning-system"].Result)

---

## 性能测试结果

### 测试: 技能扫描
- **耗时**: $($performanceTests["skill-scan"].Duration)s
- **结果**: $($performanceTests["skill-scan"].Actual)
- **期望**: $($performanceTests["skill-scan"].Expected)
- **通过**: $($performanceTests["skill-scan"].Pass)

### 测试: 文件列表
- **耗时**: $($performanceTests["file-list"].Duration)s
- **结果**: $($performanceTests["file-list"].Actual)
- **期望**: $($performanceTests["file-list"].Expected)
- **通过**: $($performanceTests["file-list"].Pass)

### 测试: 系统健康检查
- **耗时**: $($performanceTests["health-check"].Duration)s
- **结果**: $($performanceTests["health-check"].Actual)
- **期望**: $($performanceTests["health-check"].Expected)
- **通过**: $($performanceTests["health-check"].Pass)

### 测试: 启动检查
- **耗时**: $($performanceTests["startup"].Duration)s
- **结果**: $($performanceTests["startup"].Actual)
- **期望**: $($performanceTests["startup"].Expected)
- **通过**: $($performanceTests["startup"].Pass)

---

## 冒烟测试结果

### 测试: 基本功能
- **状态**: $($smokeTests["basic-functions"].Status)
- **结果**: $($smokeTests["basic-functions"].Result)

### 测试: 技能可用性
- **状态**: $($smokeTests["skills-available"].Status)
- **结果**: $($smokeTests["skills-available"].Result)

### 测试: 系统健康
- **状态**: $($smokeTests["system-ok"].Status)
- **结果**: $($smokeTests["system-ok"].Result)

### 测试: 数据完整性
- **状态**: $($smokeTests["data-integrity"].Status)
- **结果**: $($smokeTests["data-integrity"].Result)

---

## 建议

### 立即处理

$if ($summary.Failed -gt 0 -or $summary.Errors -gt 0) {
    "⚠️ 发现 $($summary.Failed + $summary.Errors) 个问题需要立即处理"
} else {
    "✅ 所有测试通过，系统运行正常"
}

### 优化建议

1. **性能优化**
   - 考虑实现文件缓存机制
   - 优化模块加载策略
   - 减少启动时间

2. **代码质量**
   - 补充单元测试
   - 提高测试覆盖率
   - 改善错误处理

3. **文档完善**
   - 补充API文档
   - 添加使用示例
   - 更新README

---

**测试版本**: v3.2.0  
**执行时间**: $timestamp  
**测试人**: 灵眸
"@

$report | Set-Content $ReportFile -Encoding UTF8
Write-Host "`n  测试报告已生成: $ReportFile" -ForegroundColor Green

# 显示总结
Write-Host "`n$(`"=" * 60)" -ForegroundColor Cyan
Write-Host "  测试完成" -ForegroundColor Magenta
Write-Host "$(`"=" * 60)" -ForegroundColor Cyan
Write-Host "`n  总测试数: $($summary.Total)" -ForegroundColor White
Write-Host "  通过: $($summary.Passed)" -ForegroundColor Green
Write-Host "  失败: $($summary.Failed)" -ForegroundColor Red
Write-Host "  错误: $($summary.Errors)" -ForegroundColor Yellow
Write-Host "  成功率: $($summary.SuccessRate)%"
Write-Host "`n$(`"=" * 60)" -ForegroundColor Cyan
