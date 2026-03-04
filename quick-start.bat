@echo off
echo ====================================
echo 快速启动 Dashboard
echo ====================================
echo.

echo 检查文件是否存在...
if exist "dashboard-server.js" (
    echo [OK] dashboard-server.js 存在
) else (
    echo [ERROR] dashboard-server.js 不存在
    exit /b 1
)

if exist "dashboard.html" (
    echo [OK] dashboard.html 存在
) else (
    echo [ERROR] dashboard.html 不存在
    exit /b 1
)

if exist "package.json" (
    echo [OK] package.json 存在
) else (
    echo [ERROR] package.json 不存在
    exit /b 1
)

echo.
echo 检查 node_modules...
if exist "node_modules\express" (
    echo [OK] express 已安装
) else (
    echo [INFO] express 未安装，正在安装...
    call npm install express socket.io --legacy-peer-deps --silent
    if %ERRORLEVEL% NEQ 0 (
        echo [ERROR] 安装失败，请检查网络或手动安装
        exit /b 1
    )
    echo [OK] 依赖安装完成
)

echo.
echo ====================================
echo 启动 Dashboard 服务器...
echo ====================================
echo.
node dashboard-server.js
pause
