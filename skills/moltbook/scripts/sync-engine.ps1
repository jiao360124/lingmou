# Moltbook数据同步引擎

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("upload", "download", "sync-knowledge", "sync-history", "full-sync")]
    [string]$Action,

    [string]$SourcePath = "skills",
    [int]$BatchSize = 10
)

$ErrorActionPreference = "Stop"

# 配置
$config = Get-Content "skills/moltbook/config.json" | ConvertFrom-Json

# 动作处理
switch ($Action) {
    "upload" {
        Write-Host "上传本地知识到Moltbook" -ForegroundColor Cyan

        if (-not $config.apiKey) {
            Write-Error "❌ 未配置API Key" -ForegroundColor Red
            Write-Host "请先运行: .\api-client.ps1 -Action register" -ForegroundColor Yellow
            return
        }

        # 扫描本地知识库
        $knowledgeFiles = Get-ChildItem -Path $SourcePath -Recurse -Include "*.md" | Select-Object -First $BatchSize

        Write-Host "`n找到 $($knowledgeFiles.Count) 个知识文件" -ForegroundColor White
        Write-Host "将上传到Moltbook..." -ForegroundColor Yellow

        $uploaded = 0
        $failed = 0

        foreach ($file in $knowledgeFiles) {
            try {
                Write-Host "`n📖 $file.Name" -ForegroundColor White

                $content = Get-Content $file.FullName -Raw
                $fileName = Split-Path $file.FullName -Leaf

                # 发布到Moltbook
                $result = .\api-client.ps1 -Action post -Content @"
# $fileName

$(content)

---
*上传于: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")*
*来源: $SourcePath*
"@

                Write-Host "✅ 上传成功! ID: $($result.id)" -ForegroundColor Green
                $uploaded++
            }
            catch {
                Write-Host "❌ 上传失败: $_" -ForegroundColor Red
                $failed++
            }
        }

        Write-Host "`n📊 上传完成!" -ForegroundColor Green
        Write-Host "成功: $uploaded" -ForegroundColor Green
        Write-Host "失败: $failed" -ForegroundColor Red
    }

    "download" {
        Write-Host "从Moltbook下载内容" -ForegroundColor Cyan

        if (-not $config.apiKey) {
            Write-Error "❌ 未配置API Key" -ForegroundColor Red
            return
        }

        Write-Host "正在获取Moltbook内容..." -ForegroundColor Yellow

        $result = .\api-client.ps1 -Action feed -Limit $BatchSize

        Write-Host "`n✅ 获取到 $($result.count) 条内容" -ForegroundColor Green

        $result.data | ForEach-Object {
            Write-Host "`n📌 $($_.title)" -ForegroundColor Yellow
            Write-Host "   $($_.content)" -ForegroundColor White
            Write-Host "   👍 $($_.likes) 💬 $($_.comments) 📅 $($_.createdAt)"
        }

        # 保存到本地
        $savePath = "$SourcePath/moltbook-import"
        New-Item -ItemType Directory -Force -Path $savePath | Out-Null

        $result.data | ForEach-Object {
            $file = Join-Path $savePath "$($_.title).md"
            $_.content | Set-Content -Path $file
            Write-Host "💾 保存到: $file" -ForegroundColor Gray
        }

        Write-Host "`n✅ 下载完成!" -ForegroundColor Green
    }

    "sync-knowledge" {
        Write-Host "同步知识库" -ForegroundColor Cyan

        if (-not $config.apiKey) {
            Write-Warning "未配置API Key，仅本地同步"
        }

        Write-Host "`n📚 本地知识库扫描..." -ForegroundColor Yellow

        # 扫描技能目录
        $skills = Get-ChildItem -Path $SourcePath -Directory | Select-Object -First 10
        $total = 0
        $synced = 0

        foreach ($skill in $skills) {
            Write-Host "`n📂 $skill.Name" -ForegroundColor Cyan

            $files = Get-ChildItem -Path $skill.FullName -Recurse -Include "*.md"
            $total += $files.Count

            foreach ($file in $files) {
                $content = Get-Content $file.FullName -Raw
                $fileName = Split-Path $file.FullName -Leaf

                # 记录同步
                $syncRecord = @{
                    file = $file.FullName
                    skill = $skill.Name
                    syncedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                }

                $recordFile = "$($skill.Name).sync.json"
                if (Test-Path $recordFile) {
                    $records = Get-Content $recordFile | ConvertFrom-Json
                }
                else {
                    $records = @()
                }

                $records += $syncRecord
                $records | ConvertTo-Json -Depth 10 | Set-Content $recordFile

                $synced++
            }

            Write-Host "  ✅ 同步了 $($files.Count) 个文件" -ForegroundColor Green
        }

        Write-Host "`n📊 知识库同步完成!" -ForegroundColor Green
        Write-Host "扫描: $total 个文件" -ForegroundColor White
        Write-Host "同步: $synced 个文件" -ForegroundColor Green
    }

    "sync-history" {
        Write-Host "同步学习历史" -ForegroundColor Cyan

        Write-Host "读取本地学习记录..." -ForegroundColor Yellow

        # 假设本地有学习记录文件
        $historyFile = "$SourcePath/learning-history.json"

        if (Test-Path $historyFile) {
            $history = Get-Content $historyFile | ConvertFrom-Json

            Write-Host "`n📖 学习历史记录:" -ForegroundColor Cyan
            $history | ForEach-Object {
                Write-Host "`n  📅 $($_.date)" -ForegroundColor White
                Write-Host "  📚 $($_.topic)" -ForegroundColor Yellow
                Write-Host "  ⏱️  $($_.duration) 分钟" -ForegroundColor White
                Write-Host "  📊 成果: $($_.achievement)" -ForegroundColor Gray
            }

            Write-Host "`n✅ 学习历史读取完成!" -ForegroundColor Green
        }
        else {
            Write-Warning "未找到学习历史文件"
            Write-Host "请先创建学习记录: $historyFile" -ForegroundColor Yellow
        }
    }

    "full-sync" {
        Write-Host "执行完整同步" -ForegroundColor Cyan

        $confirm = Read-Host "开始完整同步? (y/N)"

        if ($confirm -eq "y" -or $confirm -eq "Y") {
            Write-Host "`n🔄 同步步骤:" -ForegroundColor Cyan
            Write-Host "  1. 扫描本地知识库" -ForegroundColor White
            Write-Host "  2. 同步知识到Moltbook" -ForegroundColor White
            Write-Host "  3. 从Moltbook下载新内容" -ForegroundColor White
            Write-Host "  4. 更新学习历史" -ForegroundColor White

            Write-Host "`n开始同步..." -ForegroundColor Yellow

            .\sync-engine.ps1 -Action sync-knowledge
            .\sync-engine.ps1 -Action upload
            .\sync-engine.ps1 -Action download

            Write-Host "`n✅ 完整同步完成!" -ForegroundColor Green
        }
        else {
            Write-Host "❌ 已取消" -ForegroundColor Red
        }
    }

    default {
        throw "未知的动作: $Action"
    }
}

Write-Host "`nMoltbook数据同步引擎 - $Action`n" -ForegroundColor Cyan
