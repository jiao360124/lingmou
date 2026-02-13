<#
.SYNOPSIS
Prompt Preset Manager

.DESCRIPTION
管理提示词预设，包括预设的加载、使用、保存等功能

.NOTES
Author: OpenClaw Assistant
Date: 2026-02-13
Version: 1.0.0
#>

$modulePath = $PSScriptRoot
$presetPath = Join-Path $modulePath "data/presets.json"

# 加载预设
function Get-Presets {
    if (-not (Test-Path $presetPath)) {
        return @()
    }

    $content = Get-Content $presetPath -Raw | ConvertFrom-Json
    return $content.presets
}

# 保存预设
function Save-Preset {
    param(
        [string]$Name,
        [string]$Category,
        [hashtable]$Parameters = @{},
        [string]$Description = "",
        [switch]$CreateNew
    )

    $presets = Get-Presets

    if (-not $CreateNew -and ($presets | Where-Object { $_.name -eq $Name })) {
        throw "Preset already exists: $Name"
    }

    $preset = [PSCustomObject]@{
        name        = $Name
        category    = $Category
        description = $Description
        parameters  = $Parameters
        createdAt   = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }

    $presets += $preset

    $content = [PSCustomObject]@{
        version   = "1.0"
        createdAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        presets   = $presets
    }

    $content | ConvertTo-Json -Depth 10 | Set-Content $presetPath

    Write-Host "Preset saved: $Name" -ForegroundColor Green
}

# 删除预设
function Remove-Preset {
    param([string]$Name)

    $presets = Get-Presets
    $originalCount = $presets.Count

    $presets = $presets | Where-Object { $_.name -ne $Name }

    if ($presets.Count -eq $originalCount) {
        throw "Preset not found: $Name"
    }

    $content = [PSCustomObject]@{
        version   = "1.0"
        createdAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        presets   = $presets
    }

    $content | ConvertTo-Json -Depth 10 | Set-Content $presetPath

    Write-Host "Preset removed: $Name" -ForegroundColor Green
}

# 使用预设
function Invoke-Preset {
    param(
        [string]$Name,
        [hashtable]$Overrides = @{},
        [string]$Category = "general"
    )

    $presets = Get-Presets
    $preset = $presets | Where-Object { $_.name -eq $Name }

    if (-not $preset) {
        throw "Preset not found: $Name"
    }

    # 合并预设参数和覆盖参数
    $finalParams = @{ }
    foreach ($key in $preset.parameters.Keys) {
        if ($Overrides.ContainsKey($key)) {
            $finalParams[$key] = $Overrides[$key]
        } else {
            $finalParams[$key] = $preset.parameters[$key]
        }
    }

    return $finalParams
}

# 列出所有预设
function Show-PresetList {
    param(
        [string]$Category = "all",
        [switch]$Detailed
    )

    $presets = Get-Presets

    if ($Category -ne "all") {
        $presets = $presets | Where-Object { $_.category -eq $Category }
    }

    Write-Host "`n=== Prompt Presets ===" -ForegroundColor Cyan
    Write-Host "Total: $($presets.Count) presets" -ForegroundColor Gray

    foreach ($preset in $presets) {
        Write-Host "`n- $($preset.name) [$($preset.category)]" -ForegroundColor Yellow
        Write-Host "  Description: $($preset.description)" -ForegroundColor White
        Write-Host "  Parameters: $($preset.parameters.Keys -join ', ')" -ForegroundColor Gray

        if ($Detailed) {
            Write-Host "  Values:" -ForegroundColor Gray
            foreach ($key in $preset.parameters.Keys) {
                Write-Host "    • $($key): $($preset.parameters[$key])" -ForegroundColor White
            }
        }
    }

    Write-Host ""
}

# 创建预设模板
function New-PresetTemplate {
    param(
        [string]$Category,
        [string]$Name,
        [string]$Template,
        [hashtable]$Parameters = @{},
        [string]$Description = ""
    )

    $template = [PSCustomObject]@{
        template  = $Template
        parameters = $Parameters
    }

    return $template
}

# 批量创建预设
function New-BatchPresets {
    param(
        [hashtable[]]$Presets,
        [string]$Category = "custom"
    )

    foreach ($preset in $Presets) {
        $paramName = $preset.parameters.Name
        $paramValue = $preset.parameters.Value

        Save-Preset -Name $preset.name -Category $Category -Parameters @{
            $paramName = $paramValue
        } -Description $preset.description -CreateNew:$true
    }

    Write-Host "Created $($Presets.Count) presets" -ForegroundColor Green
}

# 导出预设
function Export-Presets {
    param(
        [string]$Category = "all",
        [string]$OutputPath
    )

    $presets = Get-Presets

    if ($Category -ne "all") {
        $presets = $presets | Where-Object { $_.category -eq $Category }
    }

    $export = @{
        version  = "1.0"
        exported = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        presets  = $presets
    }

    $export | ConvertTo-Json -Depth 10 | Set-Content $OutputPath

    Write-Host "Presets exported to: $OutputPath" -ForegroundColor Green
}

# 从模板创建预设
function New-PresetFromTemplate {
    param(
        [string]$Category,
        [string]$TemplateName,
        [hashtable]$Parameters = @{},
        [string]$Description = ""
    )

    # 这里简化处理，实际应该从模板库加载
    Write-Host "Creating preset from template: $TemplateName" -ForegroundColor Yellow

    Save-Preset -Name "$TemplateName-Preset" -Category $Category -Parameters $Parameters -Description $Description -CreateNew:$true
}

# 导入预设
function Import-Presets {
    param([string]$InputPath)

    if (-not (Test-Path $InputPath)) {
        throw "File not found: $InputPath"
    }

    $imported = Get-Content $InputPath -Raw | ConvertFrom-Json
    $presets = $imported.presets

    foreach ($preset in $presets) {
        Save-Preset -Name $preset.name -Category $preset.category -Parameters $preset.parameters -Description $preset.description -CreateNew:$true
    }

    Write-Host "Imported $($presets.Count) presets" -ForegroundColor Green
}

# 命令行接口
function Show-Usage {
    Write-Host @"
Usage:
  Show-PresetList [-Category "all"|"code"|"writing"|"analysis"|"creative"|"admin"]
  Show-PresetList -Category code -Detailed

  Invoke-Preset -Name "preset-name" [-Category "category"] [-Overrides @{key="value"}]

  Save-Preset -Name "preset-name" -Category "category" -Parameters @{key="value"} [-Description "desc"]
  Remove-Preset -Name "preset-name"

  Export-Presets -Category "all" -OutputPath presets.json
  Import-Presets -InputPath presets.json

Examples:
  Show-PresetList -Category code
  Invoke-Preset -Name "api-design" -Category code -Overrides @{language="Python"}
  Save-Preset -Name "my-preset" -Category custom -Parameters @{topic="AI"} -Description "自定义预设"
"@
}

# 默认导出到标准输出
if ($args.Count -gt 0) {
    $cmd = $args[0]

    switch ($cmd) {
        "list" {
            $category = if ($args -contains "-Category") { $args[$args.IndexOf("-Category") + 1] } else { "all" }
            $detailed = if ($args -contains "-Detailed") { $true } else { $false }
            Show-PresetList -Category $category -Detailed:$detailed
        }
        "use" {
            $name = if ($args.Count -ge 2) { $args[1] } else { throw "Missing preset name" }
            $category = if ($args -contains "-Category") { $args[$args.IndexOf("-Category") + 1] } else { "general" }
            $overrides = @{ }
            if ($args -contains "-Overrides") {
                $overridesIndex = $args.IndexOf("-Overrides") + 1
                if ($args.Count -gt $overridesIndex) {
                    $overridesJson = $args[$overridesIndex]
                    $overrides = $overridesJson | ConvertFrom-Json
                }
            }
            Invoke-Preset -Name $name -Category $category -Overrides $overrides
        }
        default {
            Show-Usage
        }
    }
}

<#
.EXAMPLE
Show-PresetList -Category code -Detailed
Invoke-Preset -Name "api-design" -Category code -Overrides @{language="Python"}
Save-Preset -Name "my-preset" -Category custom -Parameters @{topic="AI"} -Description "自定义预设"
Export-Presets -Category "all" -OutputPath presets.json
Import-Presets -InputPath presets.json
#>
