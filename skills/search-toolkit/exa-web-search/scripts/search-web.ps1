<#
.SYNOPSIS
Web搜索脚本 - 基于exa-web-search-free进行网络搜索

.DESCRIPTION
调用exa-web-search-free MCP服务器进行网络搜索，返回高质量结果。

.PARAMETER Query
搜索查询

.PARAMeter Results
结果数量，默认5

.EXAMPLE
.\search-web.ps1 -Query "React hooks最佳实践" -Results 5
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Query,

    [Parameter(Mandatory=$false)]
    [int]$Results = 5
)

function Search-Web {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Query,

        [Parameter(Mandatory=$false)]
        [int]$Results = 5
    )

    try {
        Write-Host "🌐 Web搜索: $Query" -ForegroundColor Cyan

        # 检查mcporter是否可用
        $output = & mcporter list 2>&1 | Select-String "exa"
        if (-not $output) {
            Write-Warning "exa MCP服务器未配置"
            Write-Host "请运行: mcporter config add exa https://mcp.exa.ai/mcp" -ForegroundColor Yellow
            return @()
        }

        # 执行搜索
        $searchResult = & mcporter call "exa.web_search_exa(query: '$Query', numResults: $Results)" 2>&1

        # 解析结果
        $results = @()

        if ($searchResult -match '\[.*\]') {
            $jsonString = $searchResult -match '\[(.*?)\]' | Out-Null
            $jsonContent = $Matches[1]

            $jsonItems = $jsonContent -split '\],\[' | ForEach-Object {
                $_ -replace '^\[', '' -replace '\]$', ''
            }

            foreach ($item in $jsonItems) {
                try {
                    $result = $item | ConvertFrom-Json

                    $results += [PSCustomObject]@{
                        id = [guid]::NewGuid().ToString()
                        title = $result.title
                        url = $result.url
                        snippet = $result.snippet
                        source = "web"
                        relevance = 0.5
                        search_time = Get-Date
                    }
                } catch {
                    # 跳过无效JSON
                    continue
                }
            }
        }

        Write-Host "  找到 $($results.Count) 个结果" -ForegroundColor Green

        return $results

    } catch {
        Write-Error "Web搜索失败: $_"
        return @()
    }
}

# 主程序入口
Search-Web -Query $Query -Results $Results
