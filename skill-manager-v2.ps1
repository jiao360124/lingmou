# 技能管理器 v2.0
# Unified Skill Management System

param(
    [Parameter(Mandatory=$false)]
    [switch]$ListSkills,

    [Parameter(Mandatory=$false)]
    [switch]$EnableSkill,

    [Parameter(Mandatory=$false)]
    [switch]$DisableSkill,

    [Parameter(Mandatory=$false)]
    [string]$SkillName,

    [Parameter(Mandatory=$false)]
    [switch]$Status
)

# Configuration
$RegistryPath = "$PSScriptRoot/skill-registry.json"
$ModulesPath = "$PSScriptRoot/skill-modules"

# Initialize Skills Registry
function Initialize-SkillRegistry {
    param(
        [Parameter(Mandatory=$false)]
        [string]$Path = $RegistryPath
    )

    if (-not (Test-Path $Path)) {
        Write-Log -Level "Warn" "Registry file not found: $Path"
        return $null
    }

    try {
        $Registry = Get-Content $Path | ConvertFrom-Json
        Write-Log -Level "Info" "Skill registry loaded successfully"
        return $Registry
    } catch {
        Write-Log -Level "Error" "Failed to load skill registry: $($_.Exception.Message)"
        return $null
    }
}

# Register a new skill
function Register-Skill {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$SkillInfo,

        [Parameter(Mandatory=$false)]
        [string]$RegistryPath = $RegistryPath
    )

    try {
        $Registry = Get-Content $RegistryPath | ConvertFrom-Json

        # Check if skill already exists
        if ($Registry.skills.PSObject.Properties.Name -contains $SkillInfo.name) {
            Write-Log -Level "Warn" "Skill already exists: $($SkillInfo.name)"
            return $false
        }

        # Add new skill
        $Registry.skills | Add-Member -MemberType NoteProperty -Name $SkillInfo.name -Value $SkillInfo

        # Update metadata
        $Registry.metadata.total_skills++
        $Registry.metadata.last_updated = (Get-Date -Format "o")

        # Save registry
        $Registry | ConvertTo-Json -Depth 10 | Out-File $RegistryPath

        Write-Log -Level "Info" "Skill registered: $($SkillInfo.name)"
        return $true
    } catch {
        Write-Log -Level "Error" "Failed to register skill: $($_.Exception.Message)"
        return $false
    }
}

# Load a skill module
function Load-SkillModule {
    param(
        [Parameter(Mandatory=$true)]
        [string]$SkillName,

        [Parameter(Mandatory=$false)]
        [string]$ModulesPath = $ModulesPath
    )

    $ModulePath = Join-Path $ModulesPath "$SkillName.ps1"

    if (-not (Test-Path $ModulePath)) {
        Write-Log -Level "Error" "Skill module not found: $ModulePath"
        return $false
    }

    try {
        # Load module
        . $ModulePath

        Write-Log -Level "Info" "Skill module loaded: $SkillName"
        return $true
    } catch {
        Write-Log -Level "Error" "Failed to load skill module: $($_.Exception.Message)"
        return $false
    }
}

# Enable a skill
function Enable-Skill {
    param(
        [Parameter(Mandatory=$true)]
        [string]$SkillName,

        [Parameter(Mandatory=$false)]
        [string]$RegistryPath = $RegistryPath
    )

    try {
        $Registry = Get-Content $RegistryPath | ConvertFrom-Json

        if (-not ($Registry.skills.PSObject.Properties.Name -contains $SkillName)) {
            Write-Log -Level "Error" "Skill not found: $SkillName"
            return $false
        }

        $Registry.skills.$SkillName.config.enabled = $true
        $Registry.metadata.enabled_skills++

        $Registry | ConvertTo-Json -Depth 10 | Out-File $RegistryPath

        Write-Log -Level "Info" "Skill enabled: $SkillName"
        return $true
    } catch {
        Write-Log -Level "Error" "Failed to enable skill: $($_.Exception.Message)"
        return $false
    }
}

# Disable a skill
function Disable-Skill {
    param(
        [Parameter(Mandatory=$true)]
        [string]$SkillName,

        [Parameter(Mandatory=$false)]
        [string]$RegistryPath = $RegistryPath
    )

    try {
        $Registry = Get-Content $RegistryPath | ConvertFrom-Json

        if (-not ($Registry.skills.PSObject.Properties.Name -contains $SkillName)) {
            Write-Log -Level "Error" "Skill not found: $SkillName"
            return $false
        }

        $Registry.skills.$SkillName.config.enabled = $false
        $Registry.metadata.enabled_skills--

        $Registry | ConvertTo-Json -Depth 10 | Out-File $RegistryPath

        Write-Log -Level "Info" "Skill disabled: $SkillName"
        return $true
    } catch {
        Write-Log -Level "Error" "Failed to disable skill: $($_.Exception.Message)"
        return $false
    }
}

# Invoke a skill
function Invoke-Skill {
    param(
        [Parameter(Mandatory=$true)]
        [string]$SkillName,

        [Parameter(Mandatory=$true)]
        [hashtable]$Parameters,

        [Parameter(Mandatory=$false)]
        [string]$RegistryPath = $RegistryPath
    )

    try {
        $Registry = Get-Content $RegistryPath | ConvertFrom-Json

        if (-not ($Registry.skills.PSObject.Properties.Name -contains $SkillName)) {
            throw "Skill not found: $SkillName"
        }

        # Check if skill is enabled
        if (-not $Registry.skills.$SkillName.config.enabled) {
            throw "Skill is disabled: $SkillName"
        }

        # Load skill module
        $ModulePath = Join-Path $ModulesPath "$SkillName.ps1"
        if (-not (Test-Path $ModulePath)) {
            throw "Skill module not found: $ModulePath"
        }

        . $ModulePath

        # Check if skill function exists
        $SkillFunctionName = "Invoke-$SkillName"
        if (-not (Get-Command $SkillFunctionName -ErrorAction SilentlyContinue)) {
            throw "Skill function not found: $SkillFunctionName"
        }

        # Invoke skill
        $StartTime = Get-Date
        $Result = & $SkillFunctionName @Parameters
        $Duration = (Get-Date) - $StartTime

        # Return result with metadata
        return @{
            success = $true
            data = $Result
            metadata = @{
                skill = $SkillName
                duration = "$($Duration.TotalMilliseconds)ms"
                timestamp = (Get-Date -Format "o")
                version = $Registry.skills.$SkillName.version
            }
        }

    } catch {
        return @{
            success = $false
            error = $_.Exception.Message
            skill = $SkillName
            timestamp = (Get-Date -Format "o")
        }
    }
}

# List all skills
function Get-SkillList {
    param(
        [Parameter(Mandatory=$false)]
        [string]$RegistryPath = $RegistryPath
    )

    try {
        $Registry = Get-Content $RegistryPath | ConvertFrom-Json

        $Skills = foreach ($SkillName in $Registry.skills.PSObject.Properties.Name) {
            $Skill = $Registry.skills.$SkillName
            [PSCustomObject]@{
                Name = $Skill.name
                Description = $Skill.description
                Version = $Skill.version
                Status = if ($Skill.config.enabled) { "Enabled" } else { "Disabled" }
                Priority = $Skill.priority
                RiskLevel = $Skill.risk_level
            }
        }

        return $Skills
    } catch {
        Write-Log -Level "Error" "Failed to list skills: $($_.Exception.Message)"
        return $null
    }
}

# Get skill status
function Get-SkillStatus {
    param(
        [Parameter(Mandatory=$true)]
        [string]$SkillName,

        [Parameter(Mandatory=$false)]
        [string]$RegistryPath = $RegistryPath
    )

    try {
        $Registry = Get-Content $RegistryPath | ConvertFrom-Json

        if (-not ($Registry.skills.PSObject.Properties.Name -contains $SkillName)) {
            Write-Log -Level "Error" "Skill not found: $SkillName"
            return $null
        }

        $Skill = $Registry.skills.$SkillName

        return [PSCustomObject]@{
            Name = $Skill.name
            Description = $Skill.description
            Version = $Skill.version
            Author = $Skill.author
            Repository = $Skill.repository
            Documentation = $Skill.documentation
            Status = if ($Skill.config.enabled) { "Enabled" } else { "Disabled" }
            Priority = $Skill.priority
            RiskLevel = $Skill.risk_level
            EstimatedDays = $Skill.estimated_days
            Features = $Skill.features -join ", "
            Config = $Skill.config | ConvertTo-Json -Compress
        }

    } catch {
        Write-Log -Level "Error" "Failed to get skill status: $($_.Exception.Message)"
        return $null
    }
}

# List all enabled skills
function Get-EnabledSkills {
    param(
        [Parameter(Mandatory=$false)]
        [string]$RegistryPath = $RegistryPath
    )

    try {
        $Registry = Get-Content $RegistryPath | ConvertFrom-Json

        $EnabledSkills = foreach ($SkillName in $Registry.skills.PSObject.Properties.Name) {
            $Skill = $Registry.skills.$SkillName
            if ($Skill.config.enabled) {
                [PSCustomObject]@{
                    Name = $Skill.name
                    Version = $Skill.version
                    Priority = $Skill.priority
                }
            }
        }

        return $EnabledSkills
    } catch {
        Write-Log -Level "Error" "Failed to list enabled skills: $($_.Exception.Message)"
        return $null
    }
}

# Clear skill cache
function Clear-SkillCache {
    param(
        [Parameter(Mandatory=$false)]
        [string]$SkillName = "*",

        [Parameter(Mandatory=$false)]
        [string]$RegistryPath = $RegistryPath
    )

    try {
        $Registry = Get-Content $RegistryPath | ConvertFrom-Json

        if ($SkillName -eq "*") {
            foreach ($SkillName in $Registry.skills.PSObject.Properties.Name) {
                if ($Registry.skills.$SkillName.config.cache_enabled) {
                    Clear-SkillCacheInternal -SkillName $SkillName
                }
            }
            Write-Log -Level "Info" "All skill caches cleared"
        } else {
            if ($Registry.skills.PSObject.Properties.Name -contains $SkillName) {
                if ($Registry.skills.$SkillName.config.cache_enabled) {
                    Clear-SkillCacheInternal -SkillName $SkillName
                    Write-Log -Level "Info" "Skill cache cleared: $SkillName"
                }
            }
        }

        return $true
    } catch {
        Write-Log -Level "Error" "Failed to clear skill cache: $($_.Exception.Message)"
        return $false
    }
}

function Clear-SkillCacheInternal {
    param(
        [Parameter(Mandatory=$true)]
        [string]$SkillName
    )

    try {
        # Clear skill-specific cache
        $CachePath = Join-Path $PSScriptRoot "cache\$SkillName"
        if (Test-Path $CachePath) {
            Remove-Item $CachePath -Recurse -Force
        }
        Write-Log -Level "Debug" "Cache cleared for skill: $SkillName"
    } catch {
        Write-Log -Level "Debug" "Failed to clear cache for skill: $SkillName"
    }
}

# Export module functions
Export-ModuleMember -Function `
    Initialize-SkillRegistry,
    Register-Skill,
    Load-SkillModule,
    Enable-Skill,
    Disable-Skill,
    Invoke-Skill,
    Get-SkillList,
    Get-SkillStatus,
    Get-EnabledSkills,
    Clear-SkillCache

Write-Log -Level "Info" "Skill Manager v2.0 initialized"
