# Exa Web Search Skill Module
# AI Search for Code, News, and Business Research

param(
    [Parameter(Mandatory=$true)]
    [hashtable]$Parameters,

    [Parameter(Mandatory=$false)]
    [switch]$Debug = $false
)

# Configuration
$RegistryPath = Join-Path $PSScriptRoot ".." "skill-registry.json"
$CachePath = Join-Path $PSScriptRoot ".." "skill-cache" "exa-search"

# Ensure cache directory exists
if (-not (Test-Path $CachePath)) {
    New-Item -ItemType Directory -Path $CachePath -Force | Out-Null
}

function Invoke-ExaSearch {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false)]
        [switch]$Debug = $false
    )

    $StartTime = Get-Date
    $Query = $Parameters.query
    $Type = $Parameters.type
    $Limit = $Parameters.limit
    $ForceRefresh = $Parameters.force_refresh -eq $true

    if ($Debug) {
        Write-Log -Level "Debug" "ExaSearch invoked with query: $Query"
        Write-Log -Level "Debug" "Type: $Type, Limit: $Limit"
    }

    # Validate required parameters
    if (-not $Query) {
        return @{
            success = $false
            error = "Missing required parameter: query"
        }
    }

    try {
        $Result = $null

        # Route to appropriate function based on type
        switch ($Type) {
            "Code" {
                $Result = Search-ExaCode -Query $Query -Limit $Limit -ForceRefresh:$ForceRefresh
            }
            "News" {
                $Result = Search-ExaNews -Query $Query -Limit $Limit -ForceRefresh:$ForceRefresh
            }
            "Business" {
                $Result = Search-ExaBusiness -Query $Query -Limit $Limit -ForceRefresh:$ForceRefresh
            }
            "Docs" {
                $Result = Search-ExaDocs -Query $Query -Limit $Limit -ForceRefresh:$ForceRefresh
            }
            "DeepResearcher" {
                $Result = Use-ExaDeepResearcher -Query $Query -ForceRefresh:$ForceRefresh
            }
            Default {
                $Result = Search-ExaCode -Query $Query -Limit $Limit -ForceRefresh:$ForceRefresh
            }
        }

        # Check for errors
        if (-not $Result.success) {
            throw $Result.error
        }

        # Calculate duration
        $Duration = (Get-Date) - $StartTime

        # Return standard result format
        return @{
            success = $true
            data = $Result.data
            metadata = @{
                skill = "exa-search"
                query = $Query
                type = $Type
                duration = "$($Duration.TotalMilliseconds)ms"
                timestamp = (Get-Date -Format "o")
                version = "1.0.0"
            }
        }

    } catch {
        return @{
            success = $false
            error = $_.Exception.Message
            skill = "exa-search"
            query = $Query
            type = $Type
            timestamp = (Get-Date -Format "o")
        }
    }
}

function Search-ExaCode {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Query,

        [Parameter(Mandatory=$false)]
        [int]$Limit = 10,

        [Parameter(Mandatory=$false)]
        [switch]$ForceRefresh
    )

    Write-Log -Level "Info" "Searching code for: $Query"

    try {
        # Try to get cached result
        if (-not $ForceRefresh) {
            $CacheKey = "code-$Query-$Limit"
            $CachedData = Get-ExaCache -Key $CacheKey

            if ($CachedData) {
                Write-Log -Level "Debug" "Cache hit for: $CacheKey"
                return @{
                    success = $true
                    data = $CachedData
                    cached = $true
                }
            }
        }

        # Search for code examples using Exa API
        $SearchUrl = "https://api.exa.ai/v1/search"
        $APIKey = $Env:EXA_API_KEY

        if (-not $APIKey) {
            return @{
                success = $false
                error = "EXA_API_KEY environment variable not set"
            }
        }

        $Response = Invoke-RestMethod -Uri $SearchUrl -Method Post -Headers @{
            "x-api-key" = $APIKey
            "Content-Type" = "application/json"
        } -Body @{
            query = $Query
            type = "code"
            numResults = $Limit
        }

        # Format results
        $FormattedResults = @()

        foreach ($Item in $Response.results) {
            $FormattedResults += [PSCustomObject]@{
                url = $Item.url
                title = $Item.title
                description = $Item.description
                author = $Item.author
                publishedDate = $Item.publishedDate
                score = $Item.score
                content = $Item.content
            }
        }

        $FormattedCode = [PSCustomObject]@{
            query = $Query
            count = $FormattedResults.Count
            results = $FormattedResults
        }

        # Cache the result
        Set-ExaCache -Key "code-$Query-$Limit" -Data $FormattedCode

        return @{
            success = $true
            data = $FormattedCode
            cached = $false
        }

    } catch {
        Write-Log -Level "Error" "Error searching code: $($_.Exception.Message)"
        return @{
            success = $false
            error = $_.Exception.Message
        }
    }
}

function Search-ExaNews {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Query,

        [Parameter(Mandatory=$false)]
        [int]$Limit = 10,

        [Parameter(Mandatory=$false)]
        [switch]$ForceRefresh
    )

    Write-Log -Level "Info" "Searching news for: $Query"

    try {
        # Try to get cached result
        if (-not $ForceRefresh) {
            $CacheKey = "news-$Query-$Limit"
            $CachedData = Get-ExaCache -Key $CacheKey

            if ($CachedData) {
                Write-Log -Level "Debug" "Cache hit for: $CacheKey"
                return @{
                    success = $true
                    data = $CachedData
                    cached = $true
                }
            }
        }

        # Search for news using Exa API
        $SearchUrl = "https://api.exa.ai/v1/search"
        $APIKey = $Env:EXA_API_KEY

        $Response = Invoke-RestMethod -Uri $SearchUrl -Method Post -Headers @{
            "x-api-key" = $APIKey
            "Content-Type" = "application/json"
        } -Body @{
            query = $Query
            type = "news"
            numResults = $Limit
        }

        # Format results
        $FormattedResults = @()

        foreach ($Item in $Response.results) {
            $FormattedResults += [PSCustomObject]@{
                url = $Item.url
                title = $Item.title
                author = $Item.author
                publishedDate = $Item.publishedDate
                score = $Item.score
                content = $Item.content
                sitePublished = $Item.sitePublished
            }
        }

        $FormattedNews = [PSCustomObject]@{
            query = $Query
            count = $FormattedResults.Count
            results = $FormattedResults
        }

        # Cache the result
        Set-ExaCache -Key "news-$Query-$Limit" -Data $FormattedNews

        return @{
            success = $true
            data = $FormattedNews
            cached = $false
        }

    } catch {
        Write-Log -Level "Error" "Error searching news: $($_.Exception.Message)"
        return @{
            success = $false
            error = $_.Exception.Message
        }
    }
}

function Search-ExaBusiness {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Query,

        [Parameter(Mandatory=$false)]
        [int]$Limit = 10,

        [Parameter(Mandatory=$false)]
        [switch]$ForceRefresh
    )

    Write-Log -Level "Info" "Performing business research for: $Query"

    try {
        # Try to get cached result
        if (-not $ForceRefresh) {
            $CacheKey = "business-$Query-$Limit"
            $CachedData = Get-ExaCache -Key $CacheKey

            if ($CachedData) {
                Write-Log -Level "Debug" "Cache hit for: $CacheKey"
                return @{
                    success = $true
                    data = $CachedData
                    cached = $true
                }
            }
        }

        # Search for business information using Exa API
        $SearchUrl = "https://api.exa.ai/v1/search"
        $APIKey = $Env:EXA_API_KEY

        $Response = Invoke-RestMethod -Uri $SearchUrl -Method Post -Headers @{
            "x-api-key" = $APIKey
            "Content-Type" = "application/json"
        } -Body @{
            query = $Query
            type = "auto"
            numResults = $Limit
        }

        # Format results
        $FormattedResults = @()

        foreach ($Item in $Response.results) {
            $FormattedResults += [PSCustomObject]@{
                url = $Item.url
                title = $Item.title
                author = $Item.author
                publishedDate = $Item.publishedDate
                score = $Item.score
                content = $Item.content
            }
        }

        $FormattedBusiness = [PSCustomObject]@{
            query = $Query
            count = $FormattedResults.Count
            results = $FormattedResults
        }

        # Cache the result
        Set-ExaCache -Key "business-$Query-$Limit" -Data $FormattedBusiness

        return @{
            success = $true
            data = $FormattedBusiness
            cached = $false
        }

    } catch {
        Write-Log -Level "Error" "Error performing business research: $($_.Exception.Message)"
        return @{
            success = $false
            error = $_.Exception.Message
        }
    }
}

function Search-ExaDocs {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Query,

        [Parameter(Mandatory=$false)]
        [int]$Limit = 10,

        [Parameter(Mandatory=$false)]
        [switch]$ForceRefresh
    )

    Write-Log -Level "Info" "Searching documents for: $Query"

    try {
        # Try to get cached result
        if (-not $ForceRefresh) {
            $CacheKey = "docs-$Query-$Limit"
            $CachedData = Get-ExaCache -Key $CacheKey

            if ($CachedData) {
                Write-Log -Level "Debug" "Cache hit for: $CacheKey"
                return @{
                    success = $true
                    data = $CachedData
                    cached = $true
                }
            }
        }

        # Search for documents using Exa API
        $SearchUrl = "https://api.exa.ai/v1/search"
        $APIKey = $Env:EXA_API_KEY

        $Response = Invoke-RestMethod -Uri $SearchUrl -Method Post -Headers @{
            "x-api-key" = $APIKey
            "Content-Type" = "application/json"
        } -Body @{
            query = $Query
            type = "auto"
            numResults = $Limit
        }

        # Format results
        $FormattedResults = @()

        foreach ($Item in $Response.results) {
            $FormattedResults += [PSCustomObject]@{
                url = $Item.url
                title = $Item.title
                author = $Item.author
                publishedDate = $Item.publishedDate
                score = $Item.score
                content = $Item.content
            }
        }

        $FormattedDocs = [PSCustomObject]@{
            query = $Query
            count = $FormattedResults.Count
            results = $FormattedResults
        }

        # Cache the result
        Set-ExaCache -Key "docs-$Query-$Limit" -Data $FormattedDocs

        return @{
            success = $true
            data = $FormattedDocs
            cached = $false
        }

    } catch {
        Write-Log -Level "Error" "Error searching documents: $($_.Exception.Message)"
        return @{
            success = $false
            error = $_.Exception.Message
        }
    }
}

function Use-ExaDeepResearcher {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Query,

        [Parameter(Mandatory=$false)]
        [switch]$ForceRefresh
    )

    Write-Log -Level "Info" "Starting Deep Researcher for: $Query"

    try {
        # Try to get cached result
        if (-not $ForceRefresh) {
            $CacheKey = "deepresearch-$Query"
            $CachedData = Get-ExaCache -Key $CacheKey

            if ($CachedData) {
                Write-Log -Level "Debug" "Cache hit for: $CacheKey"
                return @{
                    success = $true
                    data = $CachedData
                    cached = $true
                }
            }
        }

        # Exa Deep Researcher requires API call
        $SearchUrl = "https://api.exa.ai/v1/search"
        $APIKey = $Env:EXA_API_KEY

        $Response = Invoke-RestMethod -Uri $SearchUrl -Method Post -Headers @{
            "x-api-key" = $APIKey
            "Content-Type" = "application/json"
        } -Body @{
            query = $Query
            type = "auto"
            numResults = 20
        }

        # Build comprehensive answer
        $ComprehensiveAnswer = [PSCustomObject]@{
            question = $Query
            sources = @()
            summary = ""
            key_points = @()
            references = @()
        }

        foreach ($Item in $Response.results) {
            $ComprehensiveAnswer.sources += [PSCustomObject]@{
                url = $Item.url
                title = $Item.title
                author = $Item.author
                publishedDate = $Item.publishedDate
                score = $Item.score
            }

            # Extract key points
            if ($Item.content) {
                $ComprehensiveAnswer.key_points += $Item.content
            }
        }

        # Build summary (first 3 sources)
        $ComprehensiveAnswer.summary = $ComprehensiveAnswer.sources[0..2] | ForEach-Object {
            "$($_.title): $($_.url)"
        } -join " | "

        # Add references
        $ComprehensiveAnswer.references = $Response.results

        # Cache the result
        Set-ExaCache -Key "deepresearch-$Query" -Data $ComprehensiveAnswer

        return @{
            success = $true
            data = $ComprehensiveAnswer
            cached = $false
        }

    } catch {
        Write-Log -Level "Error" "Error using Deep Researcher: $($_.Exception.Message)"
        return @{
            success = $false
            error = $_.Exception.Message
        }
    }
}

function Get-ExaCache {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Key
    )

    $CacheFile = Join-Path $CachePath "$Key.json"

    if (Test-Path $CacheFile) {
        $CacheData = Get-Content $CacheFile | ConvertFrom-Json
        return $CacheData
    }

    return $null
}

function Set-ExaCache {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Key,

        [Parameter(Mandatory=$true)]
        $Data
    )

    $CacheFile = Join-Path $CachePath "$Key.json"
    $Data | ConvertTo-Json -Depth 10 | Out-File $CacheFile
}

# Main entry point
$Result = Invoke-ExaSearch -Parameters $Parameters -Debug:$Debug

# Export function
Export-ModuleMember -Function Invoke-ExaSearch

Write-Log -Level "Info" "Exa Search skill module loaded"
