<#
.SYNOPSIS
Skills API Routes

.DESCRIPTION
技能相关API端点实现

.NOTES
Author: OpenClaw Assistant
Date: 2026-02-16
Version: 1.0.0
#>

# 获取技能列表
function Get-SkillsList {
    param(
        [int]$Limit = 20,
        [string]$Category = "all",
        [string]$Search = ""
    )

    # 从技能注册表获取技能
    $skills = Get-AllSkills

    # 应用过滤
    if ($Category -ne "all") {
        $skills = $skills | Where-Object { $_.category -eq $Category }
    }

    if ($Search) {
        $skills = $skills | Where-Object {
            $_.name -like "*$Search*" -or
            $_.displayName -like "*$Search*" -or
            $_.description -like "*$Search*"
        }
    }

    # 分页
    $total = $skills.Count
    $skills = $skills | Select-Object -First $Limit

    return @{
        success = $true
        data = @{
            skills = $skills
            total = $total
            limit = $Limit
            offset = 0
        }
    }
}

# 获取技能详情
function Get-SkillDetail {
    param([string]$SkillId)

    $skill = Get-Skill -Name $SkillId

    if (-not $skill) {
        return @{
            success = $false
            error = "Skill not found: $SkillId"
        }
    }

    return @{
        success = $true
        data = $skill
    }
}

# 创建技能
function New-Skill {
    param(
        [string]$Name,
        [string]$DisplayName,
        [string]$Description,
        [string]$Module,
        [string[]]$Capabilities = @()
    )

    # 注册技能
    $result = Register-Skill -Name $Name `
                            -DisplayName $DisplayName `
                            -Description $Description `
                            -Module $Module `
                            -Capabilities $Capabilities

    return @{
        success = $result
        message = "Skill registered successfully"
        skill = Get-Skill -Name $Name
    }
}

# 更新技能
function Update-Skill {
    param(
        [string]$SkillId,
        [hashtable]$UpdateData
    )

    $skill = Get-Skill -Name $SkillId

    if (-not $skill) {
        return @{
            success = $false
            error = "Skill not found: $SkillId"
        }
    }

    # 更新技能信息
    foreach ($key in $UpdateData.Keys) {
        if ($skill.PSObject.Properties.Name -contains $key) {
            $skill.$key = $UpdateData[$key]
        }
    }

    # 保存更新
    Save-SkillRegistration -Skill $skill

    return @{
        success = $true
        message = "Skill updated successfully"
        skill = $skill
    }
}

# 删除技能
function Remove-Skill {
    param([string]$SkillId)

    $skill = Get-Skill -Name $SkillId

    if (-not $skill) {
        return @{
            success = $false
            error = "Skill not found: $SkillId"
        }
    }

    # 删除技能注册
    Remove-SkillRegistration -Skill $skill

    return @{
        success = $true
        message = "Skill deleted successfully"
    }
}

# 获取技能统计
function Get-SkillsStats {
    $skills = Get-AllSkills

    $stats = @{
        total = $skills.Count
        categories = @{}
        capabilities = @{}
        enabled = ($skills | Where-Object { $_.enabled }).Count
        disabled = ($skills | Where-Object { -not $_.enabled }).Count
    }

    # 按分类统计
    foreach ($skill in $skills) {
        $cat = $skill.category
        if (-not $stats.categories.ContainsKey($cat)) {
            $stats.categories[$cat] = 0
        }
        $stats.categories[$cat]++

        # 按能力统计
        foreach ($cap in $skill.capabilities) {
            if (-not $stats.capabilities.ContainsKey($cap)) {
                $stats.capabilities[$cap] = 0
            }
            $stats.capabilities[$cap]++
        }
    }

    return @{
        success = $true
        data = $stats
    }
}

# 批量创建技能
function New-BatchSkills {
    param([hashtable[]]$Skills)

    $results = @()

    foreach ($skill in $Skills) {
        $result = New-Skill -Name $skill.name `
                           -DisplayName $skill.displayName `
                           -Description $skill.description `
                           -Module $skill.module `
                           -Capabilities $skill.capabilities

        $results += $result
    }

    return @{
        success = $true
        total = $Skills.Count
        results = $results
    }
}
