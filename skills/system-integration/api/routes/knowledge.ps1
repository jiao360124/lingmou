<#
.SYNOPSIS
Knowledge API Routes

.DESCRIPTION
知识库相关API端点实现

.NOTES
Author: OpenClaw Assistant
Date: 2026-02-16
Version: 1.0.0
#>

# 搜索知识
function Search-Knowledge {
    param(
        [string]$Query,
        [int]$Limit = 10,
        [string]$Category = "all",
        [string[]]$Tags = @()
    )

    # 使用RAG检索引擎
    $results = Get-Knowledge -Query $Query -Category $Category -Limit $Limit -Tags $Tags

    return @{
        success = $true
        data = @{
            query = $Query
            results = $results
            total = $results.Count
            limit = $Limit
        }
    }
}

# 获取知识详情
function Get-KnowledgeDetail {
    param(
        [string]$Id,
        [string]$Category = "all"
    )

    if ($Category -eq "all") {
        # 从知识库索引中查找
        $knowledge = Get-KnowledgeBase

        foreach ($cat in $knowledge.categories.PSObject.Properties) {
            $doc = $cat.Value.files | Where-Object { $_.path -like "*$Id*" }
            if ($doc) {
                $content = Get-Content $doc.path -Raw
                return @{
                    success = $true
                    data = @{
                        category = $cat.Name
                        path = $doc.path
                        content = $content
                        tags = $doc.tags
                        addedAt = $doc.addedAt
                    }
                }
            }
        }
    }
    else {
        # 从指定分类查找
        $knowledge = Get-KnowledgeBase
        $docs = $knowledge.categories.$Category.files

        foreach ($doc in $docs) {
            if ($doc.path -like "*$Id*") {
                $content = Get-Content $doc.path -Raw
                return @{
                    success = $true
                    data = @{
                        category = $Category
                        path = $doc.path
                        content = $content
                        tags = $doc.tags
                        addedAt = $doc.addedAt
                    }
                }
            }
        }
    }

    return @{
        success = $false
        error = "Knowledge not found"
    }
}

# 添加知识
function Add-Knowledge {
    param(
        [string]$Path,
        [string]$Category,
        [string[]]$Tags = @(),
        [string]$Description = ""
    )

    try {
        # 索引文档
        Index-Document -Path $Path -Category $Category -Tags $Tags -Description $Description

        return @{
            success = $true
            message = "Knowledge added successfully"
            data = @{
                path = $Path
                category = $Category
            }
        }
    }
    catch {
        return @{
            success = $false
            error = $_.Exception.Message
        }
    }
}

# 批量添加知识
function New-BatchKnowledge {
    param([hashtable[]]$Knowledge)

    $results = @()

    foreach ($item in $Knowledge) {
        $result = Add-Knowledge -Path $item.path `
                               -Category $item.category `
                               -Tags $item.tags
        $results += $result
    }

    return @{
        success = $true
        total = $Knowledge.Count
        results = $results
    }
}

# 更新知识索引
function Update-KnowledgeIndex {
    try {
        Update-KnowledgeIndex -Rebuild

        return @{
            success = $true
            message = "Knowledge index updated"
        }
    }
    catch {
        return @{
            success = $false
            error = $_.Exception.Message
        }
    }
}

# 获取知识统计
function Get-KnowledgeStats {
    $knowledge = Get-KnowledgeBase

    $stats = @{
        totalCategories = $knowledge.categories.PSObject.Properties.Count
        totalDocuments = ($knowledge.categories.PSObject.Properties |
            Measure-Object -Property Count -Sum).Sum
        externalSources = $knowledge.externalSources.Count
    }

    return @{
        success = $true
        data = $stats
    }
}

# 获取知识库列表
function Get-KnowledgeList {
    param(
        [int]$Limit = 20,
        [string]$Category = "all",
        [string]$Search = ""
    )

    $knowledge = Get-KnowledgeBase

    $files = @()

    if ($Category -eq "all") {
        foreach ($cat in $knowledge.categories.PSObject.Properties) {
            foreach ($doc in $cat.Value.files) {
                if ($Search -and $doc.path -notlike "*$Search*") {
                    continue
                }

                $files += [PSCustomObject]@{
                    category = $cat.Name
                    path = $doc.path
                    tags = $doc.tags
                    size = $doc.size
                    addedAt = $doc.addedAt
                }
            }
        }
    }
    else {
        if ($knowledge.categories.PSObject.Properties.Name -contains $Category) {
            foreach ($doc in $knowledge.categories.$Category.files) {
                if ($Search -and $doc.path -notlike "*$Search*") {
                    continue
                }

                $files += [PSCustomObject]@{
                    category = $Category
                    path = $doc.path
                    tags = $doc.tags
                    size = $doc.size
                    addedAt = $doc.addedAt
                }
            }
        }
    }

    $files = $files | Sort-Object -Property addedAt -Descending |
             Select-Object -First $Limit

    return @{
        success = $true
        data = @{
            files = $files
            total = $files.Count
            limit = $Limit
        }
    }
}
