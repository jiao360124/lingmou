@echo off
chcp 65001 >nul
echo ====================================
echo Dashboard 依赖安装和启动
echo ====================================
echo.

echo [1/2] 安装依赖...
call npm install express socket.io --legacy-peer-deps
if %ERRORLEVEL% NEQ 0 (
    echo ❌ 依赖安装失败！
    pause
    exit /b 1
)
echo ✅ 依赖安装成功！
echo.

echo [2/2] 启动 Dashboard 服务器...
node dashboard-server.js
pause
