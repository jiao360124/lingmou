# Test OpenClaw Service Connections
# 测试各服务连接状态

Write-Host "=== OpenClaw 服务连接测试 ===" -ForegroundColor Cyan
Write-Host ""

$port = 18789

# 1. 测试 Gateway WebSocket 连接
Write-Host "[1/4] 测试 Gateway WebSocket 连接..." -ForegroundColor Yellow
try {
    $ws = New-Object System.Net.WebSockets.ClientWebSocket
    $uri = "ws://127.0.0.1:$port/"
    $task = $ws.ConnectAsync($uri, [System.Threading.CancellationToken]::Default)
    $task.Wait(5000)  # 5秒超时

    if ($ws.State -eq "Open") {
        Write-Host "  ✅ Gateway WebSocket 连接成功" -ForegroundColor Green
        Write-Host "  端口: $port" -ForegroundColor Gray
        Write-Host "  URI: ws://127.0.0.1:$port/" -ForegroundColor Gray
        $ws.Close()
    } else {
        Write-Host "  ❌ Gateway WebSocket 连接失败" -ForegroundColor Red
    }
} catch {
    Write-Host "  ❌ Gateway WebSocket 连接错误: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# 2. 测试 Canvas 服务连接
Write-Host "[2/4] 测试 Canvas 服务连接..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://127.0.0.1:$port/" -Method Get -TimeoutSec 5 -ErrorAction Stop
    if ($response.StatusCode -eq 200) {
        Write-Host "  ✅ Canvas 服务连接成功" -ForegroundColor Green
        Write-Host "  端口: $port" -ForegroundColor Gray
        Write-Host "  URL: http://127.0.0.1:$port/" -ForegroundColor Gray
    } else {
        Write-Host "  ⚠️  Canvas 服务返回状态码: $($response.StatusCode)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  ❌ Canvas 服务连接失败: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# 3. 测试端口监听状态
Write-Host "[3/4] 测试端口监听状态..." -ForegroundColor Yellow
$netstatOutput = netstat -ano | Select-String ":$port"
if ($netstatOutput) {
    Write-Host "  ✅ 端口 $port 正在监听" -ForegroundColor Green
    $netstatOutput | ForEach-Object {
        Write-Host "    $_" -ForegroundColor Gray
    }
} else {
    Write-Host "  ❌ 端口 $port 未监听" -ForegroundColor Red
}

Write-Host ""

# 4. 测试环境变量加载
Write-Host "[4/4] 测试环境变量配置..." -ForegroundColor Yellow
$envFile = ".ports.env"
if (Test-Path $envFile) {
    Write-Host "  ✅ 配置文件存在: $envFile" -ForegroundColor Green

    Get-Content $envFile | Select-String -Pattern '^[A-Z_]+' | ForEach-Object {
        $line = $_.ToString()
        if ($line -match '^([A-Z_]+)=(.+)$') {
            $var = $matches[1]
            $value = $matches[2]
            Write-Host "    $var = $value" -ForegroundColor Cyan
        }
    }
} else {
    Write-Host "  ❌ 配置文件不存在: $envFile" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== 测试完成 ===" -ForegroundColor Green
