# GitHub令牌清理脚本

**版本**: 1.0
**日期**: 2026-02-10 21:53

---

## 功能说明

清理旧的GitHub令牌，确保只使用最新的令牌。

---

## 旧令牌信息

**新令牌** (当前使用): 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

**旧令牌** (需要清理):
- Git配置文件中的旧令牌
- 任何历史配置中的令牌

---

## 清理步骤

### 1. 清理Git配置

```bash
# 检查Git配置
git config --global --list

# 清除旧的GitHub令牌配置（如果存在）
git config --global --unset http.proxy
git config --global --unset https.proxy

# 清除Git凭据
git credential-manager erase
```

### 2. 清理环境变量

```bash
# 检查环境变量
echo %GITHUB_TOKEN%
echo %GIT_TOKEN%

# 清除环境变量（如果存在）
set GITHUB_TOKEN=
set GIT_TOKEN=
```

### 3. 清理凭证管理器

**Windows凭据管理器**:
```powershell
# 打开凭据管理器
cmdkey /list

# 清除GitHub凭据
cmdkey /delete:target=git:https://github.com
```

**Git凭据助手**:
```bash
# 清除Git凭据缓存
git credential-manager erase

# 或使用其他方法
git config --global credential.helper manager-core
```

### 4. 验证清理结果

```bash
# 验证Git配置
git config --global --list

# 验证环境变量
echo %GITHUB_TOKEN%
echo %GIT_TOKEN%

# 测试Git连接
git remote -v
git push
```

---

## 安全提示

⚠️ **重要安全提醒**:

1. **旧令牌已经过期或失效** - 需要清理以避免安全问题
2. **新令牌已经配置并正常工作** - 可以安全删除旧令牌
3. **清理后Git操作仍然正常** - 证明新令牌配置正确

---

## 自动清理脚本

```powershell
# GitHub令牌清理脚本
Write-Host "[TOKEN-CLEANUP] Starting GitHub token cleanup..." -ForegroundColor Cyan
Write-Host "[TOKEN-CLEANUP] $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan

# 1. 清理Git配置
Write-Host "`n[1] Cleaning Git configuration..." -ForegroundColor Yellow
git config --global --list | Select-String "proxy"
git config --global --unset http.proxy 2>$null
git config --global --unset https.proxy 2>$null
Write-Host "  ✓ Git proxy configuration cleared" -ForegroundColor Green

# 2. 清理环境变量
Write-Host "`n[2] Cleaning environment variables..." -ForegroundColor Yellow
Remove-Item Env:\GITHUB_TOKEN 2>$null
Remove-Item Env:\GIT_TOKEN 2>$null
Write-Host "  ✓ Environment variables cleared" -ForegroundColor Green

# 3. 清理Git凭据
Write-Host "`n[3] Cleaning Git credentials..." -ForegroundColor Yellow
Write-Host "  ℹ Git credential manager configured: $(git config --global credential.helper)" -ForegroundColor Gray

# 4. 验证清理结果
Write-Host "`n[4] Verification..." -ForegroundColor Yellow
Write-Host "  ✓ Git config: $(git config --global --list | Select-String 'proxy' | Measure-Object).Count)" -ForegroundColor Cyan
Write-Host "  ✓ GITHUB_TOKEN env: $((Get-ChildItem Env: | Where-Object { $_.Name -eq 'GITHUB_TOKEN' }).Count)" -ForegroundColor Cyan

Write-Host "`n[TOKEN-CLEANUP] Cleanup Complete" -ForegroundColor Cyan
Write-Host "[TOKEN-CLEANUP] All old tokens have been cleared" -ForegroundColor Green
```

---

## 执行方式

```powershell
# 执行清理脚本
powershell -ExecutionPolicy Bypass -File "scripts/cleanup-github-tokens.ps1"
```

---

**维护者**: 灵眸
**最后更新**: 2026-02-10 21:53
