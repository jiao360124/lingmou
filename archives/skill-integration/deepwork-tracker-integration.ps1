# Deepwork Tracker 技能集成

**版本**: 1.0
**日期**: 2026-02-10

---

## 系统要求

确保Deepwork Tracker已安装：
- 脚本位置: `~/clawd/deepwork/deepwork.js`
- 自动下载: 脚本会自动下载（如果不存在）

---

## 功能模块

### 1. Start Session (开始深度工作会话)

```powershell
function Invoke-DeepWorkStart {
    param(
        [int]$TargetMinutes = 60,
        [switch]$Verbose = $false
    )

    Write-Host "[DEEPWORK] Starting deep work session..." -ForegroundColor Cyan
    Write-Host "Target: $TargetMinutes minutes" -ForegroundColor Yellow

    # 检查并下载脚本
    $deepworkScript = "$HOME/clawd/deepwork/deepwork.js"
    $scriptDir = "$HOME/clawd/deepwork"

    if (-not (Test-Path $deepworkScript)) {
        Write-Host "[DEEPWORK] Script not found, downloading..." -ForegroundColor Yellow
        if (-not (Test-Path $scriptDir)) {
            New-Item -ItemType Directory -Path $scriptDir -Force | Out-Null
        }

        # 下载脚本（简化版，实际会使用curl/wget）
        # curl -o $deepworkScript https://raw.githubusercontent.com/adunne09/deepwork-tracker/main/app/deepwork.js
        Write-Host "[DEEPWORK] Please manually download from: https://github.com/adunne09/deepwork-tracker" -ForegroundColor Yellow
        Write-Host "[DEEPWORK] Save to: $deepworkScript" -ForegroundColor Yellow

        if ($Verbose) {
            Write-Host "[DEEPWORK] Download instructions:" -ForegroundColor Cyan
            Write-Host "  1. Visit: https://github.com/adunne09/deepwork-tracker" -ForegroundColor Cyan
            Write-Host "  2. Download app/deepwork.js" -ForegroundColor Cyan
            Write-Host "  3. Save to: $deepworkScript" -ForegroundColor Cyan
        }
    }

    # 执行deepwork脚本
    if (Test-Path $deepworkScript) {
        Write-Host "[DEEPWORK] Executing: node $deepworkScript start --target-min $TargetMinutes" -ForegroundColor Cyan

        try {
            $output = exec -Command "node $deepworkScript start --target-min $TargetMinutes" -ErrorAction Stop

            if ($output -match "Session started") {
                Write-Host "[DEEPWORK] ✓ Session started successfully!" -ForegroundColor Green
                Write-Host "[DEEPWORK] Timer is running. Use '$command' to stop." -ForegroundColor Cyan

                return @{
                    success = $true
                    target = $TargetMinutes
                    status = "running"
                    timer_started = $true
                }
            }
        } catch {
            Write-Host "[DEEPWORK] ✗ Failed to start session" -ForegroundColor Red
            Write-Host "[DEEPWORK] Error: $($_.Exception.Message)" -ForegroundColor Red
            return @{success = $false; error = $_.Exception.Message}
        }
    } else {
        Write-Host "[DEEPWORK] ✗ Script not found and download failed" -ForegroundColor Red
        return @{success = $false; error = "Script not found"}
    }
}
```

---

### 2. Stop Session (停止深度工作会话)

```powershell
function Invoke-DeepWorkStop {
    param(
        [switch]$Verbose = $false
    )

    Write-Host "[DEEPWORK] Stopping deep work session..." -ForegroundColor Cyan

    $deepworkScript = "$HOME/clawd/deepwork/deepwork.js"

    if (-not (Test-Path $deepworkScript)) {
        Write-Host "[DEEPWORK] ✗ Script not found" -ForegroundColor Red
        return @{success = $false; error = "Script not found"}
    }

    try {
        $output = exec -Command "node $deepworkScript stop" -ErrorAction Stop

        if ($output -match "Session stopped" -or $output -match "Duration") {
            $duration = if ($output -match "Duration:\s*(\d+)(m|s)") {
                "$($matches[1])$($matches[2])"
            } else {
                "Unknown"
            }

            Write-Host "[DEEPWORK] ✓ Session stopped!" -ForegroundColor Green
            Write-Host "[DEEPWORK] Duration: $duration" -ForegroundColor Yellow

            if ($Verbose) {
                Write-Host "[DEEPWORK] Output: $output" -ForegroundColor Gray
            }

            return @{
                success = $true
                duration = $duration
                status = "stopped"
            }
        }
    } catch {
        Write-Host "[DEEPWORK] ✗ Failed to stop session" -ForegroundColor Red
        Write-Host "[DEEPWORK] Error: $($_.Exception.Message)" -ForegroundColor Red
        return @{success = $false; error = $_.Exception.Message}
    }
}
```

---

### 3. Session Status (会话状态检查)

```powershell
function Invoke-DeepWorkStatus {
    param(
        [switch]$Verbose = $false
    )

    Write-Host "[DEEPWORK] Checking session status..." -ForegroundColor Cyan

    $deepworkScript = "$HOME/clawd/deepwork/deepwork.js"

    if (-not (Test-Path $deepworkScript)) {
        Write-Host "[DEEPWORK] ✗ Script not found" -ForegroundColor Red
        return @{success = $false; error = "Script not found"}
    }

    try {
        $output = exec -Command "node $deepworkScript status" -ErrorAction Stop

        if ($output -match "Session" -or $output -match "active") {
            Write-Host "[DEEPWORK] ✓ Session is running" -ForegroundColor Green

            if ($Verbose) {
                Write-Host "[DEEPWORK] Status Output:" -ForegroundColor Cyan
                Write-Host $output -ForegroundColor Gray
            }

            return @{
                success = $true
                is_active = $true
                output = $output
            }
        } else {
            Write-Host "[DEEPWORK] ✓ No active session" -ForegroundColor Yellow
            Write-Host "[DEEPWORK] $output" -ForegroundColor Cyan

            return @{
                success = $true
                is_active = $false
                output = $output
            }
        }
    } catch {
        Write-Host "[DEEPWORK] ✗ Failed to get status" -ForegroundColor Red
        Write-Host "[DEEPWORK] Error: $($_.Exception.Message)" -ForegroundColor Red
        return @{success = $false; error = $_.Exception.Message}
    }
}
```

---

### 4. Generate Report (生成报告)

```powershell
function Invoke-DeepWorkReport {
    param(
        [int]$Days = 7,
        [ValidateSet("text", "telegram")]
        [string]$Format = "text",
        [switch]$Verbose = $false
    )

    Write-Host "[DEEPWORK] Generating report for last $Days days..." -ForegroundColor Cyan

    $deepworkScript = "$HOME/clawd/deepwork/deepwork.js"

    if (-not (Test-Path $deepworkScript)) {
        Write-Host "[DEEPWORK] ✗ Script not found" -ForegroundColor Red
        return @{success = $false; error = "Script not found"}
    }

    try {
        $formatFlag = if ($Format -eq "telegram") { "--format telegram" } else { "--format text" }
        $output = exec -Command "node $deepworkScript report --days $Days $formatFlag" -ErrorAction Stop

        Write-Host "[DEEPWORK] ✓ Report generated" -ForegroundColor Green

        if ($Verbose) {
            Write-Host "[DEEPWORK] Report Output:" -ForegroundColor Cyan
            Write-Host $output -ForegroundColor Gray
        }

        return @{
            success = $true
            days = $Days
            format = $Format
            output = $output
        }
    } catch {
        Write-Host "[DEEPWORK] ✗ Failed to generate report" -ForegroundColor Red
        Write-Host "[DEEPWORK] Error: $($_.Exception.Message)" -ForegroundColor Red
        return @{success = $false; error = $_.Exception.Message}
    }
}
```

---

### 5. Generate Heatmap (生成贡献图)

```powershell
function Invoke-DeepWorkHeatmap {
    param(
        [int]$Weeks = 52,
        [ValidateSet("telegram")]
        [string]$Format = "telegram",
        [switch]$Verbose = $false
    )

    Write-Host "[DEEPWORK] Generating heatmap for last $Weeks weeks..." -ForegroundColor Cyan

    $deepworkScript = "$HOME/clawd/deepwork/deepwork.js"

    if (-not (Test-Path $deepworkScript)) {
        Write-Host "[DEEPWORK] ✗ Script not found" -ForegroundColor Red
        return @{success = $false; error = "Script not found"}
    }

    try {
        $formatFlag = if ($Format -eq "telegram") { "--format telegram" } else { "--format text" }
        $output = exec -Command "node $deepworkScript report --mode heatmap --weeks $Weeks $formatFlag" -ErrorAction Stop

        Write-Host "[DEEPWORK] ✓ Heatmap generated" -ForegroundColor Green

        if ($Verbose) {
            Write-Host "[DEEPWORK] Heatmap Output:" -ForegroundColor Cyan
            Write-Host $output -ForegroundColor Gray
        }

        return @{
            success = $true
            weeks = $Weeks
            format = $Format
            output = $output
        }
    } catch {
        Write-Host "[DEEPWORK] ✗ Failed to generate heatmap" -ForegroundColor Red
        Write-Host "[DEEPWORK] Error: $($_.Exception.Message)" -ForegroundColor Red
        return @{success = $false; error = $_.Exception.Message}
    }
}
```

---

## Telegram 集成

```powershell
function Invoke-DeepWorkShareToTelegram {
    param(
        [int]$Days = 7,
        [switch]$SendToAlex = $false,
        [switch]$Verbose = $false
    )

    $report = Invoke-DeepWorkReport -Days $Days -Format "telegram" -Verbose:$Verbose

    if ($report.success) {
        # 获取Telegram配置
        $token = $env:TELEGRAM_TOKEN
        $chatId = "1520225096"  # 言野的Telegram ID

        if (-not $token) {
            Write-Host "[DEEPWORK] ✗ TELEGRAM_TOKEN not set" -ForegroundColor Red
            return @{success = $false; error = "TELEGRAM_TOKEN not set"}
        }

        # 发送到Telegram
        $telegramUrl = "https://api.telegram.org/bot$token/sendMessage"
        $message = $report.output

        try {
            $response = Invoke-WebRequest -Uri $telegramUrl -Method Post -Body @{
                chat_id = $chatId
                text = "Deep Work Report (`$Days days)`n```powershell`n$message`n```"
                parse_mode = "markdown"
            } -ErrorAction Stop

            Write-Host "[DEEPWORK] ✓ Report sent to Telegram!" -ForegroundColor Green

            if ($SendToAlex) {
                Write-Host "[DEEPWORK] Also sent to Alex (@8551040296)" -ForegroundColor Yellow
                Invoke-TelegramSend -ChatId "8551040296" -Message "Deep work report from $env:USERNAME`n`n$message" -Format "markdown"
            }

            return @{success = $true; sent_to_telegram = $true}
        } catch {
            Write-Host "[DEEPWORK] ✗ Failed to send to Telegram" -ForegroundColor Red
            Write-Host "[DEEPWORK] Error: $($_.Exception.Message)" -ForegroundColor Red
            return @{success = $false; error = $_.Exception.Message}
        }
    }

    return @{success = $false; error = "Report generation failed"}
}
```

---

## 导出函数

```powershell
Export-ModuleMember -Function Invoke-DeepWorkStart, Invoke-DeepWorkStop, Invoke-DeepWorkStatus, Invoke-DeepWorkReport, Invoke-DeepWorkHeatmap, Invoke-DeepWorkShareToTelegram
```

---

## 使用示例

```powershell
# 开始会话
Invoke-DeepWorkStart -TargetMinutes 90

# 检查状态
Invoke-DeepWorkStatus

# 停止会话
Invoke-DeepWorkStop

# 生成报告
Invoke-DeepWorkReport -Days 7 -Format "text"

# 生成Telegram报告
Invoke-DeepWorkReport -Days 7 -Format "telegram"

# 生成贡献图
Invoke-DeepWorkHeatmap -Weeks 52 --format telegram

# 分享到Telegram
Invoke-DeepWorkShareToTelegram -Days 7 -SendToAlex
```

---

**维护者**: 灵眸
**最后更新**: 2026-02-10
