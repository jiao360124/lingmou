# Git Essentials 技能集成

**版本**: 1.0
**日期**: 2026-02-10

---

## 功能模块

### 1. Git Status Analysis (状态分析)

```powershell
function Invoke-GitStatusAnalysis {
    param(
        [switch]$Detailed = $false
    )

    Write-Host "[GIT-ESSENTIALS] Analyzing Git status..." -ForegroundColor Cyan

    # 获取Git状态
    $status = git status --porcelain

    if (-not $status) {
        Write-Host "[GIT-ESSENTIALS] Working directory is clean" -ForegroundColor Green
        return @{clean = $true; changes = @()}
    }

    # 解析状态
    $changes = @()
    foreach ($line in $status) {
        $statusChar = $line[0]
        $file = $line.Substring(2)

        $changeType = switch ($statusChar) {
            "M" { "modified" }
            "A" { "added" }
            "D" { "deleted" }
            "R" { "renamed" }
            "C" { "copied" }
            "U" { "unmerged" }
            default { "unknown" }
        }

        $changes += @{
            type = $changeType
            file = $file
            status = $statusChar
        }
    }

    # 生成建议
    $suggestions = Generate-CommitSuggestions $changes

    # 显示结果
    Display-StatusAnalysis $changes $suggestions $Detailed

    return @{
        clean = $false
        changes = $changes
        suggestions = $suggestions
    }
}

function Display-StatusAnalysis {
    param(
        $Changes,
        $Suggestions,
        [switch]$Detailed
    )

    Write-Host "`n[GIT-ESSENTIALS] Status Analysis" -ForegroundColor Cyan
    Write-Host "==================================" -ForegroundColor Cyan
    Write-Host "Changes Detected: $($Changes.Count)" -ForegroundColor $(if ($Changes.Count -gt 0) { "Yellow" } else { "Green" })

    if ($Detailed) {
        Write-Host "`nDetailed Changes:" -ForegroundColor Yellow
        foreach ($change in $Changes) {
            $symbol = switch ($change.status) {
                "M" { "M" }
                "A" { "A" }
                "D" { "D" }
                default { "?" }
            }
            Write-Host "  [$symbol] $($change.file)" -ForegroundColor $(switch ($change.status) {
                "M" { "Yellow" }
                "A" { "Green" }
                "D" { "Red" }
                default { "Gray" }
            })
        }
    }

    if ($Suggestions.Count -gt 0) {
        Write-Host "`nSuggestions:" -ForegroundColor Green
        foreach ($suggestion in $Suggestions) {
            Write-Host "  - $($suggestion)" -ForegroundColor Cyan
        }
    }
}
```

---

### 2. Commit Suggestions (提交建议)

```powershell
function Invoke-GitCommitSuggestion {
    param(
        [switch]$StatusOnly = $false,
        [string]$Category = "all"
    )

    Write-Host "[GIT-ESSENTIALS] Generating commit suggestions..." -ForegroundColor Cyan

    # 获取Git状态
    if (-not $StatusOnly) {
        $status = git status --porcelain
        if (-not $status) {
            Write-Host "[GIT-ESSENTIALS] Nothing to commit" -ForegroundColor Yellow
            return
        }

        $changes = @()
        foreach ($line in $status) {
            $file = $line.Substring(2)
            $changes += $file
        }

        # 生成提交消息
        $commitMessage = Generate-CommitMessage $changes $Category
        $branch = git branch --show-current

        Write-Host "`n[GIT-ESSENTIALS] Commit Suggestion" -ForegroundColor Cyan
        Write-Host "=================================" -ForegroundColor Cyan
        Write-Host "Branch: $branch" -ForegroundColor Yellow
        Write-Host "Changes: $($changes.Count) files" -ForegroundColor Cyan
        Write-Host "`nSuggested Message:" -ForegroundColor Yellow
        Write-Host "$commitMessage" -ForegroundColor Green

        # 提供选项
        $options = @(
            { "Apply this commit immediately" },
            { "View changes before committing" },
            { "Modify the commit message" },
            { "Generate a different category" }
        )

        Write-Host "`nOptions:" -ForegroundColor Cyan
        for ($i = 0; $i -lt $options.Count; $i++) {
            Write-Host "  $($i + 1). $(Invoke-Command $options[$i])" -ForegroundColor Cyan
        }
    }

    return @{
        branch = git branch --show-current
        changes = git status --short
        suggested_message = if (-not $StatusOnly) { Generate-CommitMessage (git status --short) $Category } else { "" }
    }
}

function Generate-CommitMessage {
    param(
        $Changes,
        [string]$Category
    )

    # 简化的消息生成逻辑
    if ($Changes.Count -gt 0) {
        $firstChange = $Changes[0].Trim()

        if ($Category -eq "feature") {
            return "feat: Add new feature"
        } elseif ($Category -eq "bug") {
            return "fix: Resolve reported issue"
        } elseif ($Category -eq "refactor") {
            return "refactor: Improve code structure"
        } else {
            # 自动分类
            if ($firstChange -match "error|bug|fix|resolve") {
                return "fix: $($firstChange)"
            } elseif ($firstChange -match "add|create|implement") {
                return "feat: $($firstChange)"
            } else {
                return "update: Process $($Changes.Count) files"
            }
        }
    }

    return "Update working files"
}
```

---

### 3. Branch Optimization (分支优化)

```powershell
function Invoke-GitBranchOptimization {
    Write-Host "[GIT-ESSENTIALS] Branch optimization analysis..." -ForegroundColor Cyan

    # 获取当前分支
    $currentBranch = git branch --show-current

    # 获取所有分支
    $allBranches = git branch --format="%(refname:short)" | ForEach-Object { $_.Trim() }

    # 获取远程分支
    $remoteBranches = git branch -r --format="%(refname:short)" | ForEach-Object { $_.Trim() }

    # 分析分支健康度
    $branchInfo = @{}

    foreach ($branch in $allBranches) {
        $commits = git rev-list --count $branch
        $commitsAgo = git log -1 --pretty=%ci $branch

        $branchInfo[$branch] = @{
            commits = $commits
            last_commit = $commitsAgo
            is_local = $true
        }
    }

    foreach ($branch in $remoteBranches) {
        $localBranch = $branch -replace "^origin/" ""
        if (-not $branchInfo.ContainsKey($localBranch)) {
            $branchInfo[$localBranch] = @{
                commits = 0
                last_commit = "N/A"
                is_local = $false
            }
        }
    }

    # 显示分支信息
    Display-BranchAnalysis $branchInfo $currentBranch
}

function Display-BranchAnalysis {
    param(
        $BranchInfo,
        $CurrentBranch
    )

    Write-Host "`n[GIT-ESSENTIALS] Branch Analysis" -ForegroundColor Cyan
    Write-Host "================================" -ForegroundColor Cyan
    Write-Host "Current Branch: $CurrentBranch" -ForegroundColor Yellow

    Write-Host "`nBranch Health:" -ForegroundColor Yellow
    foreach ($branch in $BranchInfo.Keys) {
        $info = $BranchInfo[$branch]
        $currentMark = if ($branch -eq $CurrentBranch) { " *" } else { "  " }
        $status = if ($info.commits -gt 10) { "OK" } else { "Stale" }

        Write-Host "  $currentMark $branch - $info.commits commits" -ForegroundColor $(switch ($status) {
            "OK" { "Green" }
            "Stale" { "Yellow" }
            default { "Gray" }
        })
        Write-Host "       Last: $info.last_commit" -ForegroundColor Gray
    }

    # 优化建议
    $suggestions = @()
    foreach ($branch in $BranchInfo.Keys) {
        $info = $BranchInfo[$branch]

        if ($info.commits -lt 3 -and $branch -ne $CurrentBranch) {
            $suggestions += "Consider merging or cleaning up stale branch: $branch"
        }

        if (-not $info.is_local -and $info.commits -eq 0) {
            $suggestions += "Consider removing stale remote tracking: origin/$branch"
        }
    }

    if ($suggestions.Count -gt 0) {
        Write-Host "`nOptimization Suggestions:" -ForegroundColor Green
        foreach ($suggestion in $suggestions) {
            Write-Host "  - $suggestion" -ForegroundColor Cyan
        }
    }
}
```

---

### 4. Conflict Resolution (冲突解决)

```powershell
function Invoke-GitConflictResolution {
    param(
        [string]$FilePath = ""
    )

    Write-Host "[GIT-ESSENTIALS] Conflict resolution assistance..." -ForegroundColor Cyan

    # 查找冲突文件
    $conflicts = git diff --name-only --diff-filter=U

    if (-not $conflicts) {
        Write-Host "[GIT-ESSENTIALS] No conflicts detected" -ForegroundColor Green
        return @{conflicts = @(); resolved = $true}
    }

    Write-Host "[GIT-ESSENTIALS] Conflicts Found:" -ForegroundColor Red
    foreach ($file in $conflicts) {
        Write-Host "  - $file" -ForegroundColor Yellow
    }

    # 如果指定了文件，分析该文件
    if ($FilePath -and $conflicts -contains $FilePath) {
        Display-ConflictDetails $FilePath
    }

    # 提供解决步骤
    Display-ResolutionSteps

    return @{
        conflicts = $conflicts
        resolved = $false
    }
}

function Display-ConflictDetails {
    param(
        $FilePath
    )

    Write-Host "`n[GIT-ESSENTIALS] Conflict Details for: $FilePath" -ForegroundColor Cyan
    Write-Host "=========================================" -ForegroundColor Cyan

    # 读取文件内容
    if (Test-Path $FilePath) {
        $content = Get-Content $FilePath -Raw
        $conflictMarkers = $content -split "(?=<)\s*(\d+)\s*(?<=[<>])\s*"

        Write-Host "Conflict markers detected in file" -ForegroundColor Yellow
    }
}

function Display-ResolutionSteps {
    Write-Host "`n[GIT-ESSENTIALS] Resolution Steps:" -ForegroundColor Green
    Write-Host "  1. Open the conflicted file in a text editor" -ForegroundColor Cyan
    Write-Host "  2. Look for conflict markers (<<<<<<<, =======, >>>>>>>)" -ForegroundColor Cyan
    Write-Host "  3. Decide which version to keep or combine both" -ForegroundColor Cyan
    Write-Host "  4. Remove the conflict markers" -ForegroundColor Cyan
    Write-Host "  5. Save the file" -ForegroundColor Cyan
    Write-Host "  6. Mark as resolved: git add <file>" -ForegroundColor Cyan
    Write-Host "  7. Complete the merge: git commit" -ForegroundColor Cyan
}
```

---

## 导出函数

```powershell
Export-ModuleMember -Function Invoke-GitStatusAnalysis, Invoke-GitCommitSuggestion, Invoke-GitBranchOptimization, Invoke-GitConflictResolution
```

---

## 使用示例

```powershell
# 状态分析
Invoke-GitStatusAnalysis -Detailed

# 提交建议
Invoke-GitCommitSuggestion -Category "feature"

# 分支优化
Invoke-GitBranchOptimization

# 冲突解决
Invoke-GitConflictResolution -FilePath "scripts/example.ps1"
```

---

**维护者**: 灵眸
**最后更新**: 2026-02-10
