# Test OpenClaw Service Connections
Write-Host "=== OpenClaw 服务连接测试 ===" -ForegroundColor Cyan
$port = 18789

# 1. 测试 Gateway WebSocket 连接
Write-Host "`n[1/4] 测试 Gateway WebSocket 连接..." -ForegroundColor Yellow
try {
    $ws = New-Object System.Net.WebSockets.ClientWebSocket
    $uri = "ws://127.0.0.1:$port/"
    $task = $ws.ConnectAsync($uri, [System.Threading.CancellationToken]::Default)
    $task.Wait(5000)

    if ($ws.State -eq "Open") {
        Write-Host "  OK Gateway WebSocket 连接成功" -ForegroundColor Green
        Write-Host "  端口: $port"
        Write-Host "  URI: ws://127.0.0.1:$port/"
        $ws.Close()
    } else {
        Write-Host "  FAIL Gateway WebSocket 连接失败" -ForegroundColor Red
    }
} catch {
    Write-Host "  FAIL Gateway WebSocket 连接错误: $($_.Exception.Message)" -ForegroundColor Red
}

# 2. 测试 Canvas 服务连接
Write-Host "`n[2/4] 测试 Canvas 服务连接..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://127.0.0.1:$port/" -Method Get -TimeoutSec 5 -ErrorAction Stop
    if ($response.StatusCode -eq 200) {
        Write-Host "  OK Canvas 服务连接成功" -ForegroundColor Green
        Write-Host "  端口: $port"
        Write-Host "  URL: http://127.0.0.1:$port/"
    } else {
        Write-Host "  WARN Canvas 服务返回状态码: $($response.StatusCode)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  FAIL Canvas 服务连接失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 3. 测试端口监听状态
Write-Host "`n[3/4] 测试端口监听状态..." -ForegroundColor Yellow
$netstatOutput = netstat -ano | Select-String ":$port"
if ($netstatOutput) {
    Write-Host "  OK 端口 $port 正在监听" -ForegroundColor Green
    $netstatOutput | ForEach-Object { Write-Host "    $_" -ForegroundColor Gray }
} else {
    Write-Host "  FAIL 端口 $port 未监听" -ForegroundColor Red
}

# 4. 测试环境变量加载
Write-Host "`n[4/4] 测试环境变量配置..." -ForegroundColor Yellow
$envFile = ".ports.env"
if (Test-Path $envFile) {
    Write-Host "  OK 配置文件存在: $envFile" -ForegroundColor Green

    Get-Content $envFile | Select-String -Pattern '^[A-Z_]+' | ForEach-Object {
        $line = $_.ToString()
        if ($line -match '^([A-Z_]+)=(.+)$') {
            $var = $matches[1]
            $value = $matches[2]
            Write-Host "    $var = $value" -ForegroundColor Cyan
        }
    }
} else {
    Write-Host "  FAIL 配置文件不存在: $envFile" -ForegroundColor Red
}

Write-Host "`n=== 测试完成 ===" -ForegroundColor Green
