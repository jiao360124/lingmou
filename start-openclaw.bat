@echo off
echo ====================================
echo 启动 OpenClaw Gateway
echo ====================================
echo.

echo [1/2] 检查 OpenClaw 状态...
openclaw gateway status
if %ERRORLEVEL% EQU 0 (
    echo Gateway 已经在运行
) else (
    echo [2/2] 启动 Gateway...
    openclaw gateway start
    echo Gateway 启动完成
)

echo.
echo ====================================
echo 启动 Dashboard
echo ====================================
echo.

echo [3/3] 检查 Dashboard 依赖...
if exist "node_modules\express" (
    echo express 已安装
) else (
    echo 安装 express...
    call npm install express socket.io --legacy-peer-deps
)

echo.
echo [4/4] 启动 Dashboard 服务器...
start node dashboard-server.js
echo Dashboard 服务器已启动
echo 访问地址: http://localhost:3000

echo.
echo ====================================
echo 所有服务启动完成
echo ====================================
pause
