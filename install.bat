@echo off
echo 🚀 开始安装 Dashboard 依赖...
echo.

call npm install express socket.io --legacy-peer-deps

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ✅ 依赖安装成功！
    echo.
    echo 🎉 现在可以运行以下命令启动 Dashboard：
    echo    node dashboard-server.js
    echo.
) else (
    echo.
    echo ❌ 依赖安装失败，请检查错误信息。
    echo.
)
pause
