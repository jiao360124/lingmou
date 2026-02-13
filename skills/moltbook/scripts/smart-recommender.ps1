# Moltbook智能推荐系统

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("best-practices", "hot-topics", "collaborators", "learning-path", "content")]
    [string]$Type,

    [string]$Query,
    [int]$Limit = 10
)

$ErrorActionPreference = "Stop"

# 配置
$config = Get-Content "skills/moltbook/config.json" | ConvertFrom-Json

# 动作处理
switch ($Type) {
    "best-practices" {
        Write-Host "搜索最佳实践: $Query" -ForegroundColor Cyan

        if ($config.apiKey) {
            $result = .\api-client.ps1 -Action search -Query "最佳实践 $Query" -Limit $Limit
            Write-Host "✅ 搜索完成! 找到 $($result.count) 条结果" -ForegroundColor Green
        }
        else {
            Write-Warning "未配置API Key，使用本地推荐"
            .\get-local-recommendations.ps1 -Type "best-practices" -Query $Query -Limit $Limit
        }
    }

    "hot-topics" {
        Write-Host "获取热门话题" -ForegroundColor Cyan

        if ($config.apiKey) {
            $result = .\api-client.ps1 -Action feed -Limit $Limit
            Write-Host "✅ 获取推荐! $($result.count) 条内容" -ForegroundColor Green

            $result.data | Select-Object -First $Limit | ForEach-Object {
                Write-Host "`n📌 话题: $($_.title)" -ForegroundColor Yellow
                Write-Host "   $($_.description)" -ForegroundColor White
                Write-Host "   📊 $($_.likes) 👍 $($_.comments) 💬 $($_.shares) 📤"
            }
        }
        else {
            Write-Warning "未配置API Key"
            $hotTopics = @(
                @{title="性能优化"; description="系统性能提升最佳实践"; likes=128; comments=45},
                @{title="技能联动"; description="多技能协作方案"; likes=96; comments=32},
                @{title="自主学习"; description="AI自我进化策略"; likes=87; comments=28}
            )
            $hotTopics | Select-Object -First $Limit | ForEach-Object {
                Write-Host "`n📌 $($_.title)" -ForegroundColor Yellow
                Write-Host "   $($_.description)"
                Write-Host "   📊 $($_.likes) 👍 $($_.comments) 💬"
            }
        }
    }

    "collaborators" {
        Write-Host "推荐协作者" -ForegroundColor Cyan

        if ($config.apiKey) {
            # 获取社区活跃用户
            Write-Host "正在获取社区活跃用户..." -ForegroundColor Yellow
            $result = .\api-client.ps1 -Action feed -Limit 50

            # 分析社区结构
            $stats = $result.data | Group-Object {
                $_.authorName ?? "Unknown"
            } | Select-Object Count, @{Name="Author"; Expression={$_.Name}}

            Write-Host "`n✅ 社区活跃用户分析:" -ForegroundColor Green
            $stats | Sort-Object -Descending -Property Count | Select-Object -First 5 | ForEach-Object {
                Write-Host "  👤 $($_.Author): $($_.Count) 次参与" -ForegroundColor White
            }
        }
        else {
            Write-Warning "未配置API Key"
            $collaborators = @(
                @{name="张三"; activity=156},
                @{name="李四"; activity=128},
                @{name="王五"; activity=95},
                @{name="赵六"; activity=87},
                @{name="钱七"; activity=76}
            )
            $collaborators | Sort-Object -Descending -Property activity | Select-Object -First 5 | ForEach-Object {
                Write-Host "  👤 $($_.name): $($_.activity) 活跃度" -ForegroundColor White
            }
        }
    }

    "learning-path" {
        Write-Host "生成学习路径" -ForegroundColor Cyan

        if (-not $Query) {
            Write-Host "请输入学习主题，例如: 性能优化、代码分析、智能升级" -ForegroundColor Yellow
            $Query = Read-Host "学习主题"
        }

        Write-Host "`n🗺️  学习路径规划 ($Query):" -ForegroundColor Cyan

        # 根据主题生成学习路径
        $path = .\generate-learning-path.ps1 -Topic $Query

        $path | ForEach-Object {
            Write-Host "`n  📚 $($_.name)" -ForegroundColor White
            Write-Host "     难度: $($_.difficulty)" -ForegroundColor $(if ($_.difficulty -eq "简单") { "Green" } elseif ($_.difficulty -eq "中等") { "Yellow" } else { "Red" })
            Write-Host "     预计时间: $($_.duration)" -ForegroundColor White
            Write-Host "     资源: $($_.resources)" -ForegroundColor Gray
        }

        Write-Host "`n✅ 路径生成完成!" -ForegroundColor Green
    }

    "content" {
        Write-Host "推荐学习内容" -ForegroundColor Cyan

        if (-not $Query) {
            Write-Host "请输入主题，例如: PowerShell、Python、AI" -ForegroundColor Yellow
            $Query = Read-Host "主题"
        }

        Write-Host "`n📚 推荐内容: $Query" -ForegroundColor Cyan

        $recommendations = .\get-content-recommendations.ps1 -Topic $Query -Limit $Limit

        $recommendations | ForEach-Object {
            Write-Host "`n📌 $($_.title)" -ForegroundColor Yellow
            Write-Host "   $($_.description)" -ForegroundColor White
            Write-Host "   ⭐ $($_.rating) / 5" -ForegroundColor White
            Write-Host "   📖 $($_.type)" -ForegroundColor Gray
        }

        Write-Host "`n✅ 推荐完成!" -ForegroundColor Green
    }

    default {
        throw "未知的类型: $Type"
    }
}

Write-Host "`nMoltbook智能推荐系统 - $Type`n" -ForegroundColor Cyan
