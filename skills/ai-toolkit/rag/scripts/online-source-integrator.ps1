<#
.SYNOPSIS
Online Knowledge Source Integrator

.DESCRIPTION
集成和检索在线知识源（GitHub、Stack Overflow、官方文档等）

.NOTES
Author: OpenClaw Assistant
Date: 2026-02-14
Version: 1.0.0
#>

$modulePath = $PSScriptRoot

# 在线源配置
$externalSources = @{
    "github" = @{
        "enabled" = $true
        "apiEndpoint" = "https://api.github.com"
        "rateLimit" = 60
        "rateLimitWindow" = 60000
    }
    "stackoverflow" = @{
        "enabled" = $true
        "apiEndpoint" = "https://api.stackexchange.com"
        "rateLimit" = 30
        "rateLimitWindow" = 60000
    }
    "official-docs" = @{
        "enabled" = $true
        "apiEndpoint" = ""
        "rateLimit" = 60
        "rateLimitWindow" = 60000
    }
}

# 检查源是否启用
function Test-SourcesEnabled {
    param([string[]]$Sources = @("all"))

    $enabled = @()
    foreach ($source in $Sources) {
        if ($source -eq "all") {
            $enabled += $externalSources.Values
        } elseif ($externalSources.ContainsKey($source) -and $externalSources[$source].enabled) {
            $enabled += $externalSources[$source]
        }
    }

    return $enabled
}

# 搜索GitHub
function Search-GitHub {
    param(
        [string]$Query,
        [int]$Limit = 5,
        [string]$Language = "all"
    )

    if (-not $externalSources["github"].enabled) {
        return @()
    }

    Write-Host "Searching GitHub for: $Query" -ForegroundColor Yellow

    # 使用web_fetch获取GitHub搜索结果
    try {
        $encodedQuery = [System.Web.HttpUtility]::UrlEncode("$Query language:$Language")
        $url = "https://api.github.com/search/code?q=$encodedQuery&per_page=$Limit"

        $headers = @{
            "Accept" = "application/vnd.github.v3+json"
        }

        $response = Invoke-WebRequest -Uri $url -Headers $headers -Method Get

        $data = $response.Content | ConvertFrom-Json

        $results = @()
        foreach ($item in $data.items) {
            $results += [PSCustomObject]@{
                Source      = "GitHub"
                Repository  = $item.repository.name
                FileName    = $item.name
                Language    = $item.repository.language
                Stars       = $item.repository.stargazers_count
                URL         = $item.html_url
                Relevance   = $item.score
                DownloadURL = $item.git_url
            }
        }

        return $results
    }
    catch {
        Write-Host "GitHub search failed: $_" -ForegroundColor Red
        return @()
    }
}

# 搜索Stack Overflow
function Search-StackOverflow {
    param(
        [string]$Query,
        [int]$Limit = 5
    )

    if (-not $externalSources["stackoverflow"].enabled) {
        return @()
    }

    Write-Host "Searching Stack Overflow for: $Query" -ForegroundColor Yellow

    try {
        $encodedQuery = [System.Web.HttpUtility]::UrlEncode($Query)
        $url = "https://api.stackexchange.com/2.3/search/advanced?order=desc&sort=activity&q=$encodedQuery&pagesize=$Limit&site=stackoverflow"

        $response = Invoke-WebRequest -Uri $url -Method Get

        $data = $response.Content | ConvertFrom-Json

        $results = @()
        foreach ($item in $data.items) {
            $results += [PSCustomObject]@{
                Source          = "Stack Overflow"
                QuestionTitle   = $item.title
                QuestionID      = $item.question_id
                AnswerCount     = $item.answer_count
                ViewCount       = $item.view_count
                URL             = $item.link
                Relevance       = $item.score
                AcceptedAnswer  = $item.is_accepted
            }
        }

        return $results
    }
    catch {
        Write-Host "Stack Overflow search failed: $_" -ForegroundColor Red
        return @()
    }
}

# 获取官方文档
function Get-OfficialDocs {
    param(
        [string]$Topic,
        [string]$Provider = "all"
    )

    if (-not $externalSources["official-docs"].enabled) {
        return @()
    }

    Write-Host "Fetching official docs for: $Topic" -ForegroundColor Yellow

    # 这里简化处理，实际应用中应连接到官方文档API
    $results = @(
        [PSCustomObject]@{
            Source      = "Official Docs"
            Topic       = $Topic
            Provider    = "Generic"
            URL         = "https://docs.example.com"
            Relevance   = 0.8
        }
    )

    return $results
}

# 检索在线源
function Get-OnlineKnowledge {
    param(
        [string]$Query,
        [string[]]$Sources = @("github", "stackoverflow"),
        [int]$Limit = 10
    )

    $enabledSources = Test-SourcesEnabled -Sources $Sources
    $results = @()

    foreach ($source in $enabledSources) {
        switch ($source.Source) {
            "GitHub" {
                $githubResults = Search-GitHub -Query $Query -Limit ($Limit / 2)
                $results += $githubResults
            }
            "Stack Overflow" {
                $soResults = Search-StackOverflow -Query $Query -Limit ($Limit / 2)
                $results += $soResults
            }
        }
    }

    # 限制结果数量
    $results = $results | Sort-Object -Property Relevance -Descending |
        Select-Object -First $Limit

    return $results
}

# 获取源状态
function Get-SourceStatus {
    param([switch]$Detailed)

    $status = [PSCustomObject]@{
        Sources = @()
    }

    foreach ($name in $externalSources.Keys) {
        $source = $externalSources[$name]

        $sourceStatus = [PSCustomObject]@{
            Name        = $name
            Enabled     = $source.enabled
            APIEndpoint = $source.apiEndpoint
            RateLimit   = $source.rateLimit
            RateLimitWindow = $source.rateLimitWindow
        }

        $status.Sources += $sourceStatus
    }

    if ($Detailed) {
        Write-Host "`n=== Source Status ===" -ForegroundColor Cyan
        foreach ($s in $status.Sources) {
            Write-Host "`n[$($s.Name)]" -ForegroundColor Yellow
            Write-Host "Enabled: $($s.Enabled)" -ForegroundColor $(if ($s.Enabled) { "Green" } else { "Red" })
            Write-Host "API Endpoint: $($s.APIEndpoint)" -ForegroundColor White
            Write-Host "Rate Limit: $($s.RateLimit) requests" -ForegroundColor Gray
        }
    }

    return $status
}

# 更新源配置
function Update-SourceConfig {
    param(
        [string]$Name,
        [bool]$Enabled = $true
    )

    if ($externalSources.ContainsKey($Name)) {
        $externalSources[$Name].enabled = $Enabled
        Write-Host "Source '$Name' $Enabled" -ForegroundColor Green
    }
    else {
        Write-Host "Source '$Name' not found" -ForegroundColor Red
    }
}

# 聚合多源结果
function Aggregate-MultiSourceResults {
    param(
        [hashtable[]]$Results,
        [int]$Limit = 5
    )

    # 合并所有结果
    $allResults = @()
    foreach ($result in $Results) {
        foreach ($item in $result) {
            $allResults += $item
        }
    }

    # 去重
    $uniqueResults = @()
    $seen = @()
    foreach ($item in $allResults) {
        if (-not $seen.Contains($item.URL)) {
            $seen += $item.URL
            $uniqueResults += $item
        }
    }

    # 按相关性排序
    $uniqueResults = $uniqueResults | Sort-Object -Property Relevance -Descending |
        Select-Object -First $Limit

    return $uniqueResults
}

# 检查速率限制
function Check-RateLimit {
    param([string]$Source = "all")

    $results = @()

    if ($Source -eq "all") {
        foreach ($name in $externalSources.Keys) {
            $source = $externalSources[$name]
            $results += [PSCustomObject]@{
                Source    = $name
                Remaining = $source.rateLimit
                Reset     = (Get-Date).AddMilliseconds($source.rateLimitWindow)
            }
        }
    }
    elseif ($externalSources.ContainsKey($Source)) {
        $source = $externalSources[$Source]
        $results += [PSCustomObject]@{
            Source    = $Source
            Remaining = $source.rateLimit
            Reset     = (Get-Date).AddMilliseconds($source.rateLimitWindow)
        }
    }

    return $results
}

# 命令行接口
function Show-Usage {
    Write-Host @"
Usage:
  Search-GitHub -Query "API client" -Language JavaScript
  Search-StackOverflow -Query "async function"
  Get-OfficialDocs -Topic "authentication"

  Get-OnlineKnowledge -Query "API best practices" -Sources @("github", "stackoverflow")

  Get-SourceStatus
  Get-SourceStatus -Detailed

  Update-SourceConfig -Name "github" -Enabled $true
  Update-SourceConfig -Name "stackoverflow" -Enabled $true

  Check-RateLimit

Examples:
  Search-GitHub -Query "async await" -Language JavaScript
  Get-OnlineKnowledge -Query "database connection" -Sources @("github", "stackoverflow")
"@
}

# 默认执行
if ($args.Count -gt 0) {
    $cmd = $args[0]

    switch ($cmd) {
        "github" {
            $query = if ($args.Count -ge 2) { $args[1] } else { throw "Missing query" }
            $lang = if ($args -contains "-Language") { $args[$args.IndexOf("-Language") + 1] } else { "all" }
            $limit = if ($args -contains "-Limit") { [int]$args[$args.IndexOf("-Limit") + 1] } else { 5 }

            $results = Search-GitHub -Query $query -Language $lang -Limit $limit

            Write-Host "`n=== GitHub Results ===" -ForegroundColor Cyan
            foreach ($result in $results) {
                Write-Host "$($result.Repository)/$($result.FileName)" -ForegroundColor Yellow
                Write-Host "Stars: $($result.Stars)" -ForegroundColor Gray
                Write-Host "URL: $($result.URL)" -ForegroundColor White
                Write-Host ""
            }
        }
        "stackoverflow" {
            $query = if ($args.Count -ge 2) { $args[1] } else { throw "Missing query" }
            $limit = if ($args -contains "-Limit") { [int]$args[$args.IndexOf("-Limit") + 1] } else { 5 }

            $results = Search-StackOverflow -Query $query -Limit $limit

            Write-Host "`n=== Stack Overflow Results ===" -ForegroundColor Cyan
            foreach ($result in $results) {
                Write-Host "$($result.QuestionTitle)" -ForegroundColor Yellow
                Write-Host "Answers: $($result.AnswerCount) | Views: $($result.ViewCount)" -ForegroundColor Gray
                Write-Host "URL: $($result.URL)" -ForegroundColor White
                Write-Host ""
            }
        }
        "status" {
            $detailed = if ($args -contains "-Detailed") { $true } else { $false }
            Get-SourceStatus -Detailed:$detailed
        }
        "knowledge" {
            $query = if ($args.Count -ge 2) { $args[1] } else { throw "Missing query" }
            $sources = if ($args -contains "-Sources") {
                @($args[$args.IndexOf("-Sources") + 1 .. ($args.Count - 1)])
            } else {
                @("github", "stackoverflow")
            }
            $limit = if ($args -contains "-Limit") { [int]$args[$args.IndexOf("-Limit") + 1] } else { 10 }

            $results = Get-OnlineKnowledge -Query $query -Sources $sources -Limit $limit

            Write-Host "`n=== Online Knowledge Results ===" -ForegroundColor Cyan
            foreach ($result in $results) {
                Write-Host "[$($result.Source)] $($result.Relevance.ToString('0.00'))" -ForegroundColor Yellow
                Write-Host "$($result)" -ForegroundColor White
                Write-Host ""
            }
        }
        default {
            Show-Usage
        }
    }
}

<#
.EXAMPLE
Search-GitHub -Query "async await" -Language JavaScript
Search-StackOverflow -Query "database connection"
Get-OnlineKnowledge -Query "API best practices" -Sources @("github", "stackoverflow")
Get-SourceStatus -Detailed
#>
