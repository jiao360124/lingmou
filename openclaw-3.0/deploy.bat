@echo off
REM OpenClaw 3.0 一键部署脚本（Windows）

echo 🚀 OpenClaw 3.0 一键部署
echo ==========================

REM 检查 Docker
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Docker 未安装
    echo 请先安装 Docker: https://docs.docker.com/get-docker/
    pause
    exit /b 1
)

REM 检查 Docker Compose
docker-compose --version >nul 2>&1
if %errorlevel% neq 0 (
    docker compose --version >nul 2>&1
    if %errorlevel% neq 0 (
        echo ❌ Docker Compose 未安装
        pause
        exit /b 1
    )
    set COMPOSE_CMD=docker compose
) else (
    set COMPOSE_CMD=docker-compose
)

REM 检查配置文件
if not exist config.json (
    echo ⚠️  config.json 不存在，创建默认配置
    if exist config.json.example (
        copy config.json.example config.json
    ) else (
        echo ⚠️  config.json.example 不存在，跳过
    )
)

REM 检查 .env 文件
if not exist .env (
    echo ⚠️  .env 不存在，创建示例文件
    if exist .env.example (
        copy .env.example .env
        echo 💡 请编辑 .env 文件配置 API 密钥等参数
    ) else (
        echo ⚠️  .env.example 不存在，跳过
    )
)

REM 构建镜像
echo.
echo 📦 构建镜像...
%COMPOSE_CMD% build

REM 启动服务
echo.
echo 🚀 启动服务...
%COMPOSE_CMD% up -d

REM 等待服务启动
echo.
echo ⏳ 等待服务启动...
timeout /t 5 /nobreak >nul

REM 检查服务状态
echo.
echo 📋 检查服务状态...
%COMPOSE_CMD% ps

REM 显示日志
echo.
echo 📊 查看日志:
echo 运行命令: %COMPOSE_CMD% logs -f

REM 测试 API
echo.
echo 🧪 测试 API...
timeout /t 3 /nobreak >nul
curl -s http://localhost:18789/api/status >nul 2>&1
if %errorlevel% equ 0 (
    echo API 测试成功
) else (
    echo ⚠️  API 测试失败，请检查服务状态
)

echo.
echo ✅ 部署完成！
echo.
echo 访问地址:
echo   Dashboard API: http://localhost:18789
echo   Dashboard UI: http://localhost:3000
echo.
echo 常用命令:
echo   查看日志: %COMPOSE_CMD% logs -f
echo   停止服务: %COMPOSE_CMD% stop
echo   重启服务: %COMPOSE_CMD% restart
echo   查看状态: %COMPOSE_CMD% ps
echo   删除服务: %COMPOSE_CMD% down

pause
