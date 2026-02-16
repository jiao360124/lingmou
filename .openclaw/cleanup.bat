@echo off
chcp 65001 >nul
echo 🧹 OpenClaw 冗余文件清理工具 (Windows)
echo ========================================
echo.

:: 检查 .openclaw 目录
if not exist ".openclaw" (
    echo ❌ 错误: .openclaw 目录不存在
    pause
    exit /b 1
)

echo 📂 当前目录: %CD%
echo.

:: 1. 显示将要清理的文件
echo 📋 将要清理的文件:
echo ========================================

set LOG_COUNT=0
set BACKUP_COUNT=0
set BAK_COUNT=0
set OLD_COUNT=0
set TEMP_COUNT=0

:: 统计文件数量
for /r ".openclaw" %%f in (*.log) do set /a LOG_COUNT+=1
for /r ".openclaw" %%f in (*.backup* *.bak* *.old) do set /a BACKUP_COUNT+=1
for /r ".openclaw" %%f in (*.tmp *.temp .DS_Store Thumbs.db) do set /a TEMP_COUNT+=1

echo 📄 日志文件: %LOG_COUNT%
echo 📄 备份文件: %BACKUP_COUNT%
echo 📄 临时文件: %TEMP_COUNT%
echo.

:: 2. 询问是否继续
set /p confirm="🤔 是否继续清理？(y/n): "

if /i not "%confirm%"=="y" (
    echo ✅ 已取消清理
    pause
    exit /b 0
)

echo.
echo 🧹 开始清理...
echo ========================================

:: 3. 清理日志文件
if %LOG_COUNT% gtr 0 (
    echo 📄 清理日志文件...
    for /r ".openclaw" %%f in (*.log) do del /f /q "%%f"
    echo   ✅ 完成
)

:: 4. 清理备份文件
if %BACKUP_COUNT% gtr 0 (
    echo 📄 清理备份文件...
    for /r ".openclaw" %%f in (*.backup* *.bak* *.old) do del /f /q "%%f"
    echo   ✅ 完成
)

:: 5. 清理临时文件
if %TEMP_COUNT% gtr 0 (
    echo 📄 清理临时文件...
    for /r ".openclaw" %%f in (*.tmp *.temp .DS_Store Thumbs.db) do del /f /q "%%f"
    echo   ✅ 完成
)

:: 6. 清理构建产物（可选）
set /p clean_build="📦 是否清理构建产物？(node_modules, dist, build, coverage, .cache) (y/n): "

if /i "%clean_build%"=="y" (
    echo 📦 清理构建产物...

    :: 删除 node_modules
    if exist "node_modules" (
        rmdir /s /q "node_modules"
        echo   ✅ node_modules
    )

    :: 删除构建目录
    if exist "dist" rmdir /s /q "dist"
    if exist "build" rmdir /s /q "build"
    if exist "coverage" rmdir /s /q "coverage"
    if exist ".cache" rmdir /s /q ".cache"

    echo   ✅ 构建/缓存目录
)

echo.
echo ========================================
echo ✅ 清理完成！
echo ========================================
echo.

:: 4. 显示清理结果
echo 📊 清理结果:
echo ========================================

for /r ".openclaw" %%f in (*.log) do set /a LOG_COUNT+=1
for /r ".openclaw" %%f in (*.backup* *.bak* *.old) do set /a BACKUP_COUNT+=1
for /r ".openclaw" %%f in (*.tmp *.temp .DS_Store Thumbs.db) do set /a TEMP_COUNT+=1

echo 📄 剩余日志文件: %LOG_COUNT%
echo 📄 剩余备份文件: %BACKUP_COUNT%
echo 📄 剩余临时文件: %TEMP_COUNT%
echo.

:: 显示目录大小
for %%A in (".openclaw") do set SIZE=%%~zA
echo 📂 .openclaw 目录大小: %SIZE% 字节
echo ========================================

pause
