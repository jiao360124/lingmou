<#
.SYNOPSIS
本地文件搜索脚本 - 基于file-search（fd + ripgrep）

.DESCRIPTION
搜索本地文件系统，返回匹配的文件和内容。

.PARAMeter Query
搜索查询

.PARAMeter MaxResults
最大结果数，默认10

.EXAMPLE
.\search-local.ps1 -Query "React hooks" -MaxResults 10
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Query,

    [Parameter(Mandatory=$false)]
    [int]$MaxResults = 10
)

function Search-Local {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Query,

        [Parameter(Mandatory=$false)]
        [int]$MaxResults = 10
    )

    try {
        Write-Host "📁 本地文件搜索: $Query" -ForegroundColor Cyan

        $workspace = "C:\Users\Administrator\.openclaw\workspace"

        # 使用fd查找匹配的文件
        $files = & fd -t f -H -J "$Query" $workspace 2>$null | Select-Object -First $MaxResults

        $results = @()

        foreach ($file in $files) {
            if (Test-Path $file) {
                # 使用rg搜索文件内容
                $content = & rg -C 3 -i --heading "$Query" $file 2>$null

                $results += [PSCustomObject]@{
                    id = [guid]::NewGuid().ToString()
                    title = Split-Path $file -Leaf
                    file_path = $file
                    content = $content
                    source = "local"
                    relevance = 0.6
                    search_time = Get-Date
                }
            }
        }

        Write-Host "  找到 $($results.Count) 个结果" -ForegroundColor Green

        return $results

    } catch {
        Write-Error "本地文件搜索失败: $_"
        return @()
    }
}

# 主程序入口
Search-Local -Query $Query -MaxResults $MaxResults
