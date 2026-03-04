<#
.SYNOPSIS
记忆搜索脚本 - 搜索MEMORY.md和memory/日期文件

.DESCRIPTION
搜索内部记忆文件，返回相关内容和上下文。

.PARAMeter Query
搜索查询

.PARAMeter MaxResults
最大结果数，默认5

.EXAMPLE
.\search-memory.ps1 -Query "React hooks" -MaxResults 5
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Query,

    [Parameter(Mandatory=$false)]
    [int]$MaxResults = 5
)

function Search-Memory {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Query,

        [Parameter(Mandatory=$false)]
        [int]$MaxResults = 5
    )

    try {
        Write-Host "🧠 记忆搜索: $Query" -ForegroundColor Cyan

        $searchPaths = @(
            "C:\Users\Administrator\.openclaw\workspace\MEMORY.md",
            "C:\Users\Administrator\.openclaw\workspace\memory\2026-02-14.md"
        )

        $results = @()

        foreach ($path in $searchPaths) {
            if (Test-Path $path) {
                $content = Get-Content $path -Raw -ErrorAction SilentlyContinue
                if ($content) {
                    # 搜索关键词
                    $matches = [regex]::Matches($content, "(?i)$Query")

                    foreach ($match in $matches) {
                        # 获取上下文（前后各3行）
                        $lines = $content -split "`n"
                        $index = $match.Index
                        $start = [Math]::Max(0, $index - 500)
                        $end = [Math]::Min($content.Length, $index + 500)

                        $snippet = $content.Substring($start, $end - $start)

                        $results += [PSCustomObject]@{
                            id = [guid]::NewGuid().ToString()
                            title = "Memory Entry from $(Split-Path $path -Leaf)"
                            content = $snippet
                            source = "memory"
                            relevance = 0.7
                            search_time = Get-Date
                        }

                        # 达到最大结果数就停止
                        if ($results.Count -ge $MaxResults) {
                            break
                        }
                    }
                }
            }
        }

        Write-Host "  找到 $($results.Count) 个结果" -ForegroundColor Green

        return $results

    } catch {
        Write-Error "记忆搜索失败: $_"
        return @()
    }
}

# 主程序入口
Search-Memory -Query $Query -MaxResults $MaxResults
