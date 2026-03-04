@echo off
chcp 65001 > nul
echo.
echo ═════════════════════════════════════════════════════════════════
echo        OpenClaw 3.0 - 快速启动脚本
echo ═════════════════════════════════════════════════════════════════
echo.

cd /d "%~dp0"

REM 检查Node.js
where node > nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ 错误: 未检测到Node.js
    echo 请先安装Node.js 18+: https://nodejs.org/
    pause
    exit /b 1
)

REM 检查npm
where npm > nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ 错误: 未检测到npm
    pause
    exit /b 1
)

echo ✅ 检测到Node.js: %node_version%
echo ✅ 当前目录: %cd%
echo.

REM 检查package.json
if not exist "package.json" (
    echo ❌ 错误: 未找到package.json
    echo 请先运行: npm install
    pause
    exit /b 1
)

echo 🚀 正在启动OpenClaw 3.0...
echo.

REM 启动服务
node index.js

REM 如果出错，暂停
if %errorlevel% neq 0 (
    echo.
    echo ❌ 服务启动失败
    echo.
    echo 请查看日志: logs/openclaw-3.0.log
    pause
)
