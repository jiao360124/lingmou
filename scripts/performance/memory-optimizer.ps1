# 内存优化工具 - Memory Optimizer
# 版本: 1.0.0
# 创建时间: 2026-02-11

<#
.SYNOPSIS
    内存优化工具 - 优化和清理内存使用

.DESCRIPTION
    创建内存优化系统，包括：
    - 内存泄漏检测
    - 对象清理
    - 缓存管理
    - 内存池化

.PARAMETER Action
    执行的操作: Scan, Clean, Optimize, Test

.PARAMETER ScanType
    扫描类型: All, Leaks, LargeObjects

.EXAMPLE
    .\memory-optimizer.ps1 -Action Scan -ScanType All
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('Scan', 'Clean', 'Optimize', 'Test')]
    [string]$Action,

    [Parameter(Mandatory=$false)]
    [ValidateSet('All', 'Leaks', 'LargeObjects')]
    [string]$ScanType = 'All'
)

# 配置
$Config = @{
    LogDir = "logs/performance"
    MemoryThresholdMB = 100
    LargeObjectThresholdKB = 1024
    ScanIntervalSeconds = 5
}

# 创建目录
if (-not (Test-Path $Config.LogDir)) {
    New-Item -ItemType Directory -Path $Config.LogDir -Force | Out-Null
}

# 日志函数
function Write-MemoryLog {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,

        [ValidateSet('INFO', 'WARN', 'ERROR')]
        [string]$Level = 'INFO'
    )

    $Timestamp = Get-Date -Format "HH:mm:ss"
    $Color = switch($Level) {
        'INFO' { 'White' }
        'WARN' { 'Yellow' }
        'ERROR' { 'Red' }
    }

    Write-Host "[$Timestamp] [$Level] $Message" -ForegroundColor $Color
}

# 内存优化器类
class MemoryOptimizer {
    [hashtable]$MemoryStats = @{
        PeakUsed = 0
        CurrentUsed = 0
        TotalMemory = 0
        AvailableMemory = 0
        LeaksFound = 0
        LargeObjects = @()
    }

    MemoryOptimizer() {
        Write-MemoryLog "初始化内存优化器" -Level INFO
        $this.Update-MemoryStats()
    }

    # 更新内存状态
    Update-MemoryStats() {
        $os = Get-CimInstance Win32_OperatingSystem
        $total = $os.TotalVisibleMemorySize / 1MB
        $available = $os.FreePhysicalMemory / 1MB
        $used = $total - $available

        $this.MemoryStats.TotalMemory = [math]::Round($total, 2)
        $this.MemoryStats.AvailableMemory = [math]::Round($available, 2)
        $this.MemoryStats.CurrentUsed = [math]::Round($used, 2)
        $this.MemoryStats.PeakUsed = [math]::Max($this.MemoryStats.PeakUsed, $used)

        $this.MemoryStats.UsagePercent = [math]::Round(($used / $total) * 100, 2)
    }

    # 扫描内存泄漏
    Scan-MemoryLeaks() {
        Write-MemoryLog "开始内存泄漏扫描..." -Level INFO

        $this.MemoryStats.LeaksFound = 0
        $leaks = @()

        # 监控内存变化
        $initialStats = $this.MemoryStats
        $iterations = 0
        $maxIterations = 30

        while ($iterations -lt $maxIterations) {
            $currentStats = $this.Get-CimInstanceMemory()
            $usedChange = $currentStats.Used - $initialStats.Used

            if ($usedChange -gt 10) {  # 假设10MB为泄漏阈值
                $leaks += @{
                    Time = Get-Date -Format "HH:mm:ss"
                    Iteration = $iterations
                    UsedMB = [math]::Round($currentStats.Used, 2)
                    ChangeMB = [math]::Round($usedChange, 2)
                    UsagePercent = $currentStats.UsagePercent
                }
                $this.MemoryStats.LeaksFound++
                Write-MemoryLog "检测到内存泄漏: +$([math]::Round($usedChange, 2)) MB" -Level WARN
            }

            Start-Sleep -Seconds $Config.ScanIntervalSeconds
            $iterations++
        }

        return $leaks
    }

    # 扫描大对象
    Scan-LargeObjects() {
        Write-MemoryLog "开始大对象扫描..." -Level INFO

        $largeObjects = @()

        # 扫描进程中的大对象
        $processes = Get-Process
        foreach ($process in $processes) {
            try {
                $processMemory = Get-Counter "\\Process($($process.ProcessName))\\Working Set"
                $workingSet = [math]::Round(($processMemory.CounterSamples | 
                    Select-Object -ExpandProperty CookedValue) / 1MB, 2)

                if ($workingSet -gt $Config.MemoryThresholdMB) {
                    $largeObjects += @{
                        Process = $process.ProcessName
                        PID = $process.Id
                        MemoryMB = $workingSet
                        ThreadCount = $process.Threads.Count
                    }
                }
            }
            catch {
                # 忽略无法访问的进程
            }
        }

        $this.MemoryStats.LargeObjects = $largeObjects
        return $largeObjects
    }

    # 清理内存
    Clean-Memory() {
        Write-MemoryLog "开始内存清理..." -Level INFO

        # 清理已弃用的变量
        $vars = Get-Variable -ErrorAction SilentlyContinue
        foreach ($var in $vars) {
            if (-not $var.Value) {
                Remove-Variable -Name $var.Name -ErrorAction SilentlyContinue
            }
        }

        # 清理自动变量
        Remove-Variable -Name global:_ -ErrorAction SilentlyContinue
        Remove-Variable -Name global:err -ErrorAction SilentlyContinue

        # 清理临时文件
        $tempPaths = @(
            "$env:TEMP",
            "$env:TEMP\\*",
            "$env:TEMP\\cache\\*",
            "temp\\*"
        )

        foreach ($tempPath in $tempPaths) {
            try {
                $files = Get-ChildItem -Path $tempPath -Recurse -ErrorAction SilentlyContinue | 
                         Where-Object { $_.LastWriteTime -lt (Get-Date).AddHours(-24) }

                if ($files) {
                    $count = ($files | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object).Count
                    Write-MemoryLog "清理了 $count 个临时文件" -Level INFO
                }
            }
            catch {
                Write-MemoryLog "清理临时文件失败: $($_.Exception.Message)" -Level WARN
            }
        }

        # 强制垃圾回收
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
        [System.GC]::Collect()

        Write-MemoryLog "内存清理完成" -Level INFO
    }

    # 优化内存使用
    Optimize-Memory() {
        Write-MemoryLog "开始内存优化..." -Level INFO

        # 1. 执行内存清理
        $this.Clean-Memory()

        # 2. 扫描内存泄漏
        if ($ScanType -eq 'All' -or $ScanType -eq 'Leaks') {
            $this.Scan-MemoryLeaks()
        }

        # 3. 扫描大对象
        if ($ScanType -eq 'All' -or $ScanType -eq 'LargeObjects') {
            $this.Scan-LargeObjects()
        }

        # 4. 生成优化报告
        $this.Generate-Report()
    }

    # 生成优化报告
    Generate-Report() {
        Write-MemoryLog "生成内存优化报告..." -Level INFO

        $report = @"
# 内存优化报告
**生成时间**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

---

## 📊 当前内存状态

### 内存使用
- **总内存**: $($this.MemoryStats.TotalMemory) MB
- **已使用**: $($this.MemoryStats.CurrentUsed) MB
- **可用**: $($this.MemoryStats.AvailableMemory) MB
- **使用率**: $($this.MemoryStats.UsagePercent)%
- **峰值使用**: $($this.MemoryStats.PeakUsed) MB

### 内存泄漏检测
- **泄漏次数**: $($this.MemoryStats.LeaksFound)
- **泄漏时间**: $(if ($this.MemoryStats.LeaksFound -gt 0) { '检测到内存泄漏，需要修复' } else { '未检测到内存泄漏' })

### 大对象分析
**使用超过 $($Config.MemoryThresholdMB) MB 的进程**:
"@

        if ($this.MemoryStats.LargeObjects.Count -eq 0) {
            $report += "未发现大对象占用"
        }
        else {
            foreach ($obj in $this.MemoryStats.LargeObjects) {
                $report += @"
- **$($obj.Process)** (PID: $($obj.PID))
  - 内存占用: $($obj.MemoryMB) MB
  - 线程数: $($obj.ThreadCount)
"@
            }
        }

        $report += @"

---

## ✅ 优化建议

### 立即行动
"@

        if ($this.MemoryStats.UsagePercent -gt 80) {
            $report += "1. **立即清理内存** - 运行 \`.\\memory-optimizer.ps1 -Action Clean\``
n"
        }

        if ($this.MemoryStats.LeaksFound -gt 0) {
            $report += "2. **修复内存泄漏** - 使用 \`.\\memory-optimizer.ps1 -Action Scan -ScanType Leaks\``
n"
        }

        if ($this.MemoryStats.LargeObjects.Count -gt 0) {
            $report += "3. **优化大对象使用** - 检查 $($this.MemoryStats.LargeObjects.Count) 个占用大内存的进程`n"
        }

        $report += @"

### 长期优化
1. **实现对象池化** - 重用大型对象以减少分配开销
2. **优化缓存策略** - 使用内存缓存减少重复计算
3. **定期内存检查** - 设置定时任务定期清理
4. **监控内存使用** - 实现内存使用趋势监控

---

**优化完成时间**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
**生成者**: 灵眸内存优化器
"@

        # 保存报告
        $reportPath = Join-Path $Config.LogDir "memory-optimization-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"
        $report | Out-File -FilePath $reportPath -Encoding UTF8 -Force

        Write-MemoryLog "报告已保存: $reportPath" -Level INFO
        
        # 打印摘要
        Write-Host "`n=== 内存优化摘要 ===" -ForegroundColor Cyan
        Write-Host "内存使用率: $($this.MemoryStats.UsagePercent)%"
        Write-Host "可用内存: $($this.MemoryStats.AvailableMemory) MB"
        Write-Host "内存泄漏: $($this.MemoryStats.LeaksFound) 个"
        Write-Host "大对象: $($this.MemoryStats.LargeObjects.Count) 个"
        Write-Host "报告位置: $reportPath"
        Write-Host ""
    }
}

# 主程序
function Main {
    Write-Host "`n==========================================" -ForegroundColor Cyan
    Write-Host "内存优化工具" -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""

    $optimizer = [MemoryOptimizer]::new()

    switch ($Action) {
        'Scan' {
            if ($ScanType -eq 'All' -or $ScanType -eq 'Leaks') {
                $optimizer.Scan-MemoryLeaks()
            }
            if ($ScanType -eq 'All' -or $ScanType -eq 'LargeObjects') {
                $optimizer.Scan-LargeObjects()
            }
            $optimizer.Generate-Report()
        }
        'Clean' {
            $optimizer.Clean-Memory()
            $optimizer.Generate-Report()
        }
        'Optimize' {
            $optimizer.Optimize-Memory()
        }
        'Test' {
            $optimizer.Optimize-Memory()
        }
    }
}

Main
