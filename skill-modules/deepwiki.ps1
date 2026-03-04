# DeepWiki Skill Module
# GitHub Repository Documentation Query and QA

param(
    [Parameter(Mandatory=$true)]
    [hashtable]$Parameters,

    [Parameter(Mandatory=$false)]
    [switch]$Debug = $false
)

# Configuration
$RegistryPath = Join-Path $PSScriptRoot ".." "skill-registry.json"
$CachePath = Join-Path $PSScriptRoot ".." "skill-cache" "deepwiki"

# Ensure cache directory exists
if (-not (Test-Path $CachePath)) {
    New-Item -ItemType Directory -Path $CachePath -Force | Out-Null
}

function Invoke-DeepWiki {
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
        Write-Log -Level "Debug" "DeepWiki invoked with query: $Query"
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
            "Repository" {
                $Result = Get-DeepWikiRepositories -Query $Query -Limit $Limit -ForceRefresh:$ForceRefresh
            }
            "Readme" {
                $Result = Get-DeepWikiReadme -Query $Query -ForceRefresh:$ForceRefresh
            }
            "Q&A" {
                $Result = Query-DeepWikiQA -Question $Query -ForceRefresh:$ForceRefresh
            }
            "Code" {
                $Result = Search-DeepWikiCode -Query $Query -ForceRefresh:$ForceRefresh
            }
            "Wiki" {
                $Result = Get-DeepWikiWiki -Query $Query -ForceRefresh:$ForceRefresh
            }
            Default {
                $Result = Get-DeepWikiRepositories -Query $Query -Limit $Limit -ForceRefresh:$ForceRefresh
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
                skill = "deepwiki"
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
            skill = "deepwiki"
            query = $Query
            type = $Type
            timestamp = (Get-Date -Format "o")
        }
    }
}

function Get-DeepWikiRepositories {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Query,

        [Parameter(Mandatory=$false)]
        [int]$Limit = 10,

        [Parameter(Mandatory=$false)]
        [switch]$ForceRefresh
    )

    Write-Log -Level "Info" "Searching repositories for: $Query"

    try {
        # Try to get cached result
        if (-not $ForceRefresh) {
            $CacheKey = "repo-$Query-$Limit"
            $CachedData = Get-DeepWikiCache -Key $CacheKey

            if ($CachedData) {
                Write-Log -Level "Debug" "Cache hit for: $CacheKey"
                return @{
                    success = $true
                    data = $CachedData
                    cached = $true
                }
            }
        }

        # Since DeepWiki is a real service, we'll use web search to find repositories
        Write-Log -Level "Info" "Performing web search for repositories..."

        $SearchResults = Invoke-ExaSearch -Type Code -Query "$Query repository" -Limit $Limit

        # Format results
        $FormattedResults = @()

        foreach ($Item in $SearchResults.data) {
            $FormattedResults += [PSCustomObject]@{
                url = $Item.url
                title = $Item.title
                description = $Item.description
                language = $Item.language
                stars = $Item.stars
                created = $Item.created_at
            }
        }

        $FormattedRepositories = [PSCustomObject]@{
            query = $Query
            count = $FormattedResults.Count
            results = $FormattedResults
        }

        # Cache the result
        Set-DeepWikiCache -Key "repo-$Query-$Limit" -Data $FormattedRepositories

        return @{
            success = $true
            data = $FormattedRepositories
            cached = $false
        }

    } catch {
        Write-Log -Level "Error" "Error searching repositories: $($_.Exception.Message)"
        return @{
            success = $false
            error = $_.Exception.Message
        }
    }
}

function Get-DeepWikiReadme {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Query,

        [Parameter(Mandatory=$false)]
        [switch]$ForceRefresh
    )

    Write-Log -Level "Info" "Fetching README for: $Query"

    try {
        # Try to get cached result
        if (-not $ForceRefresh) {
            $CacheKey = "readme-$Query"
            $CachedData = Get-DeepWikiCache -Key $CacheKey

            if ($CachedData) {
                Write-Log -Level "Debug" "Cache hit for: $CacheKey"
                return @{
                    success = $true
                    data = $CachedData
                    cached = $true
                }
            }
        }

        # Search for repository
        $RepoSearch = Invoke-ExaSearch -Type Code -Query "$Query repository" -Limit 1

        if ($RepoSearch.success -and $RepoSearch.data.Count -gt 0) {
            $Repo = $RepoSearch.data[0]

            # Fetch README from the repository
            $ReadmeContent = Get-GitHubReadme -Url $Repo.url -ForceRefresh:$ForceRefresh

            if ($ReadmeContent.success) {
                # Cache the result
                Set-DeepWikiCache -Key "readme-$Query" -Data $ReadmeContent.data

                return @{
                    success = $true
                    data = $ReadmeContent.data
                    cached = $false
                }
            }
        }

        return @{
            success = $false
            error = "Repository not found or README not available"
        }

    } catch {
        Write-Log -Level "Error" "Error fetching README: $($_.Exception.Message)"
        return @{
            success = $false
            error = $_.Exception.Message
        }
    }
}

function Query-DeepWikiQA {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Question,

        [Parameter(Mandatory=$false)]
        [switch]$ForceRefresh
    )

    Write-Log -Level "Info" "Querying DeepWiki for: $Question"

    try {
        # Try to get cached result
        if (-not $ForceRefresh) {
            $CacheKey = "qa-$Question"
            $CachedData = Get-DeepWikiCache -Key $CacheKey

            if ($CachedData) {
                Write-Log -Level "Debug" "Cache hit for: $CacheKey"
                return @{
                    success = $true
                    data = $CachedData
                    cached = $true
                }
            }
        }

        # Search for information about the question
        $SearchResults = Invoke-ExaSearch -Type News -Query $Question -Limit 5

        # Build answer from search results
        $Answer = [PSCustomObject]@{
            question = $Question
            sources = @()
            answer = ""
        }

        foreach ($Item in $SearchResults.data) {
            $Answer.sources += [PSCustomObject]@{
                title = $Item.title
                url = $Item.url
                snippet = $Item.snippet
                published = $Item.published
            }

            # Build answer from snippets
            $Answer.answer += "$($Item.snippet) "
        }

        # Cache the result
        Set-DeepWikiCache -Key "qa-$Question" -Data $Answer

        return @{
            success = $true
            data = $Answer
            cached = $false
        }

    } catch {
        Write-Log -Level "Error" "Error querying DeepWiki: $($_.Exception.Message)"
        return @{
            success = $false
            error = $_.Exception.Message
        }
    }
}

function Search-DeepWikiCode {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Query,

        [Parameter(Mandatory=$false)]
        [switch]$ForceRefresh
    )

    Write-Log -Level "Info" "Searching code in DeepWiki for: $Query"

    try {
        # Try to get cached result
        if (-not $ForceRefresh) {
            $CacheKey = "code-$Query"
            $CachedData = Get-DeepWikiCache -Key $CacheKey

            if ($CachedData) {
                Write-Log -Level "Debug" "Cache hit for: $CacheKey"
                return @{
                    success = $true
                    data = $CachedData
                    cached = $true
                }
            }
        }

        # Search for code examples
        $SearchResults = Invoke-ExaSearch -Type Code -Query $Query -Limit 10

        # Format results
        $FormattedResults = @()

        foreach ($Item in $SearchResults.data) {
            $FormattedResults += [PSCustomObject]@{
                url = $Item.url
                title = $Item.title
                description = $Item.description
                language = $Item.language
                code_snippet = $Item.code_snippet
            }
        }

        $FormattedCode = [PSCustomObject]@{
            query = $Query
            count = $FormattedResults.Count
            results = $FormattedResults
        }

        # Cache the result
        Set-DeepWikiCache -Key "code-$Query" -Data $FormattedCode

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

function Get-DeepWikiWiki {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Query,

        [Parameter(Mandatory=$false)]
        [switch]$ForceRefresh
    )

    Write-Log -Level "Info" "Fetching Wiki for: $Query"

    try {
        # Try to get cached result
        if (-not $ForceRefresh) {
            $CacheKey = "wiki-$Query"
            $CachedData = Get-DeepWikiCache -Key $CacheKey

            if ($CachedData) {
                Write-Log -Level "Debug" "Cache hit for: $CacheKey"
                return @{
                    success = $true
                    data = $CachedData
                    cached = $true
                }
            }
        }

        # Search for wiki information
        $SearchResults = Invoke-ExaSearch -Type Docs -Query "$Query wiki" -Limit 5

        # Format results
        $FormattedResults = @()

        foreach ($Item in $SearchResults.data) {
            $FormattedResults += [PSCustomObject]@{
                url = $Item.url
                title = $Item.title
                description = $Item.description
                content = $Item.content
            }
        }

        $FormattedWiki = [PSCustomObject]@{
            query = $Query
            count = $FormattedResults.Count
            results = $FormattedResults
        }

        # Cache the result
        Set-DeepWikiCache -Key "wiki-$Query" -Data $FormattedWiki

        return @{
            success = $true
            data = $FormattedWiki
            cached = $false
        }

    } catch {
        Write-Log -Level "Error" "Error fetching wiki: $($_.Exception.Message)"
        return @{
            success = $false
            error = $_.Exception.Message
        }
    }
}

function Get-DeepWikiCache {
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

function Set-DeepWikiCache {
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
$Result = Invoke-DeepWiki -Parameters $Parameters -Debug:$Debug

# Export function
Export-ModuleMember -Function Invoke-DeepWiki

Write-Log -Level "Info" "DeepWiki skill module loaded"
