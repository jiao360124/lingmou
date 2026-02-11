# 系统性能基准测试和瓶颈分析
# System Performance Benchmark and Bottleneck Analysis
# 版本: 1.0.0
# 创建时间: 2026-02-11

<#
.SYNOPSIS
    系统性能基准测试 - 分析性能瓶颈和优化机会

.DESCRIPTION
    创建性能监控系统，包括：
    - 系统资源监控（CPU、内存、磁盘、网络）
    - 脚本性能分析
    - API调用分析
    - 热点检测

.PARAMETER TestDuration
    测试持续时间（秒）
    
.PARAMETER TestType
    测试类型: All, Memory, CPU, API, Script

.PARAMETER OutputFile
    输出报告文件路径

.EXAMPLE
    .\system-benchmark.ps1 -TestDuration 60 -TestType All
#>

param(
    [int]$TestDuration = 60,
    [Parameter(Mandatory=$false)]
    [ValidateSet('All', 'Memory', 'CPU', 'API', 'Script')]
    [string]$TestType = 'All',
    [string]$OutputFile = "reports/performance-benchmark-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"
)

# 配置
$Config = @{
    LogDir = "logs/performance"
    ReportDir = "reports/performance"
    SampleInterval = 1
    MaxSamples = $TestDuration
}

# 创建目录
if (-not (Test-Path $Config.LogDir)) {
    New-Item -ItemType Directory -Path $Config.LogDir -Force | Out-Null
}
if (-not (Test-Path $Config.ReportDir)) {
    New-Item -ItemType Directory -Path $Config.ReportDir -Force | Out-Null
}

# 日志函数
function Write-BenchmarkLog {
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

# 性能监控类
class PerformanceMonitor {
    [hashtable]$Metrics = @{
        CPU = @()
        Memory = @()
        Disk = @()
        Network = @()
        Scripts = @()
        API = @()
    }
    
    [datetime]$StartTime
    [int]$SampleCount = 0

    PerformanceMonitor($duration) {
        $this.StartTime = Get-Date
        Write-BenchmarkLog "开始性能监控，持续时间: $duration 秒" -Level INFO
    }

    # 获取CPU使用率
    Get-CPUUsage() {
        $cpu = Get-Counter "\Processor(_Total)\% Processor Time" | 
               Select-Object -ExpandProperty CounterSamples | 
               Select-Object -ExpandProperty CookedValue
        return [math]::Round($cpu, 2)
    }

    # 获取内存使用情况
    Get-MemoryUsage() {
        $memory = Get-CimInstance Win32_OperatingSystem
        $total = $memory.TotalVisibleMemorySize / 1MB
        $available = $memory.FreePhysicalMemory / 1MB
        $used = $total - $available
        $percent = [math]::Round(($used / $total) * 100, 2)
        
        return @{
            TotalMB = [math]::Round($total, 2)
            FreeMB = [math]::Round($available, 2)
            UsedMB = [math]::Round($used, 2)
            Percent = $percent
        }
    }

    # 获取磁盘使用情况
    Get-DiskUsage() {
        $disk = Get-PSDrive C
        return @{
            FreeGB = [math]::Round($disk.Free / 1GB, 2)
            UsedGB = [math]::Round($disk.Used / 1GB, 2)
            TotalGB = [math]::Round(($disk.Free + $disk.Used) / 1GB, 2)
            FreePercent = [math]::Round(($disk.Free / ($disk.Free + $disk.Used)) * 100, 2)
        }
    }

    # 获取网络接口信息
    Get-NetworkInfo() {
        $interface = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
        $bandwidth = if ($interface.Speed -gt 0) {
            [math]::Round($interface.Speed / 1Mbps, 2)
        }
        else {
            "Unknown"
        }
        
        return @{
            Interface = $interface.Name
            BandwidthMbps = $bandwidth
            IPv4 = ($interface.IPv4Address.IPAddressToString) -join ', '
        }
    }

    # 监控脚本性能
    Monitor-ScriptPerformance($scriptPath) {
        Write-BenchmarkLog "监控脚本性能: $scriptPath" -Level INFO
        
        if (Test-Path $scriptPath) {
            $scriptInfo = Get-Item $scriptPath
            $metrics = @{
                SizeKB = [math]::Round($scriptInfo.Length / 1KB, 2)
                LastModified = $scriptInfo.LastWriteTime
                Dependencies = @()
            }

            # 检查依赖文件
            $lines = Get-Content $scriptPath
            foreach ($line in $lines) {
                if ($line -match '\.ps1"') {
                    $depPath = $line -match '"(.+\.ps1)"' | Out-Null; if ($matches[1]) {
                        $metrics.Dependencies += $matches[1]
                    }
                }
            }

            return $metrics
        }
        
        return $null
    }

    # 监控API调用
    Monitor-APIUsage() {
        Write-BenchmarkLog "监控API调用" -Level INFO
        
        # 检查当前活跃的API调用
        $apiCalls = Get-Counter "\\Process(*)\\IO Data Bytes/sec" | 
                    Select-Object -ExpandProperty CounterSamples | 
                    Where-Object { $_.CookedValue -gt 0 } |
                    Sort-Object -Property CookedValue -Descending |
                    Select-Object -First 5
        
        $results = @()
        foreach ($call in $apiCalls) {
            $processName = $call.Path -replace '.*\\', ''
            $results += @{
                Process = $processName
                DataReadMB = [math]::Round($call.CookedValue / 1MB, 2)
                SampleCount = $call.SampleCount
            }
        }
        
        return $results
    }

    # 执行监控
    Run-Monitor($type) {
        Write-BenchmarkLog "开始采集数据..." -Level INFO
        $this.SampleCount = 0
        
        while ((Get-Date) - $this.StartTime -lt [timespan]::FromSeconds($TestDuration)) {
            $currentMetrics = @{
                Timestamp = Get-Date -Format "HH:mm:ss"
                Sample = $this.SampleCount
            }

            if ($type -eq 'All' -or $type -eq 'Memory') {
                $currentMetrics.Memory = $this.Get-MemoryUsage()
            }
            
            if ($type -eq 'All' -or $type -eq 'CPU') {
                $currentMetrics.CPU = $this.Get-CPUUsage()
            }
            
            if ($type -eq 'All' -or $type -eq 'API') {
                $currentMetrics.APICalls = $this.Monitor-APIUsage()
            }

            $this.Metrics.Memory += $currentMetrics.Memory
            $this.Metrics.CPU += $currentMetrics.CPU
            $this.Metrics.API += $currentMetrics.APICalls
            $this.SampleCount++

            Start-Sleep -Seconds $Config.SampleInterval
        }

        Write-BenchmarkLog "数据采集完成，共采样 $this.SampleCount 次" -Level INFO
    }

    # 生成性能报告
    Generate-Report() {
        Write-BenchmarkLog "生成性能报告..." -Level INFO
        
        $report = @"
# 系统性能基准测试报告
**测试时间**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
**测试时长**: $TestDuration 秒
**采样次数**: $this.SampleCount

---

## 📊 性能指标摘要

### CPU 使用率
- **平均值**: $([math]::Round(($this.Metrics.CPU | Measure-Object -Average).Average, 2))%
- **最大值**: $($this.Metrics.CPU | Measure-Object -Maximum).Maximum%
- **最小值**: $($this.Metrics.CPU | Measure-Object -Minimum).Minimum%

### 内存使用情况
- **平均使用**: $([math]::Round(($this.Metrics.Memory | Measure-Object -Property Percent -Average).Average, 2))%
- **最大使用**: $($this.Metrics.Memory | Measure-Object -Property Percent -Maximum).Maximum%
- **最小可用**: $([math]::Round(($this.Metrics.Memory | Measure-Object -Property FreeMB -Minimum).Minimum, 2)) MB

### 磁盘使用情况
\`\`\`
$( ($this.Get-DiskUsage() | ConvertTo-Json) )
\`\`\`

---

## 🚀 性能瓶颈分析

### 高CPU使用率时段
"@

        # 找到CPU使用率高的时段
        $highCPU = $this.Metrics.CPU | Where-Object { $_ -gt 80 }
        if ($highCPU.Count -gt 0) {
            $report += "**检测到高CPU使用率时段** ($highCPU.Count 次):`n"
            foreach ($cpu in $highCPU) {
                $report += "- $($cpu)% (在 $(Get-Date -Format 'HH:mm:ss'))`n"
            }
            $report += "**建议**: 优化CPU密集型任务，考虑并行处理`n`n"
        }
        else {
            $report += "**无高CPU使用率问题**`n`n"
        }

        # 找到内存使用率高的时段
        $highMemory = $this.Metrics.Memory | Where-Object { $_.Percent -gt 80 }
        if ($highMemory.Count -gt 0) {
            $report += "**检测到高内存使用率时段** ($highMemory.Count 次):`n"
            foreach ($mem in $highMemory) {
                $report += "- $($mem.Percent)% (可用: $($mem.FreeMB) MB) (在 $(Get-Date -Format 'HH:mm:ss'))`n"
            }
            $report += "**建议**: 优化内存使用，检查内存泄漏`n`n"
        }
        else {
            $report += "**无高内存使用率问题**`n`n"
        }

        # API调用分析
        $report += "### API调用分析`n"
        $totalAPICalls = ($this.Metrics.API | Measure-Object -Sum).Count
        $report += "**总API调用次数**: $totalAPICalls`n"
        
        if ($totalAPICalls -gt 100) {
            $report += "**建议**: 优化API调用，考虑缓存和批量操作`n`n"
        }

        $report += @"
---

## 📈 趋势分析

### 内存使用趋势
\`\`\`text
时间,使用率(%),可用(MB)
$(($this.Metrics.Memory | ForEach-Object { "$($_.Timestamp),$($_.Percent),$($_.FreeMB)" }) -join "`n")
\`\`\`

---

## ✅ 优化建议

### 高优先级优化
"@

        if ($highCPU.Count -gt 0) {
            $report += "1. **优化CPU密集型操作** - 考虑使用后台任务、并行处理`n"
        }
        
        if ($highMemory.Count -gt 0) {
            $report += "2. **优化内存使用** - 检查内存泄漏，优化数据结构`n"
        }
        
        if ($totalAPICalls -gt 100) {
            $report += "3. **减少API调用** - 实现缓存机制，合并请求`n"
        }

        if ($highCPU.Count -eq 0 -and $highMemory.Count -eq 0 -and $totalAPICalls -le 100) {
            $report += "**当前系统性能良好，无需紧急优化**`n"
        }

        $report += @"

---

**测试完成时间**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
**生成者**: 灵眸性能监控系统
"@

        # 保存报告
        $report | Out-File -FilePath $OutputFile -Encoding UTF8 -Force
        Write-BenchmarkLog "报告已保存: $OutputFile" -Level INFO
        
        # 打印摘要
        Write-Host "`n=== 性能测试摘要 ===" -ForegroundColor Cyan
        Write-Host "测试时长: $TestDuration 秒"
        Write-Host "采样次数: $this.SampleCount"
        Write-Host "平均CPU: $([math]::Round(($this.Metrics.CPU | Measure-Object -Average).Average, 2))%"
        Write-Host "平均内存: $([math]::Round(($this.Metrics.Memory | Measure-Object -Property Percent -Average).Average, 2))%"
        Write-Host "报告位置: $OutputFile"
        Write-Host ""
    }
}

# 主程序
function Main {
    Write-Host "`n==========================================" -ForegroundColor Cyan
    Write-Host "系统性能基准测试" -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""

    $monitor = [PerformanceMonitor]::new($TestDuration)
    $monitor.Run-Monitor($TestType)
    $monitor.Generate-Report()
}

Main
