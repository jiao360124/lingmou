<#
.SYNOPSIS
智能去重引擎 - 基于关键词相似度合并重复结果

.DESCRIPTION
使用余弦相似度算法对搜索结果进行去重和聚类，智能识别相似内容。

.PARAMETER Results
所有搜索结果的数组

.PARAMETER Query
原始搜索查询

.PARAMeter SimilarityThreshold
相似度阈值（0-1），默认0.85

.EXAMPLE
$results = @(
    @{id="1"; title="React Hooks"; content="..."; source="local"},
    @{id="2"; title="React Hooks指南"; content="..."; source="web"}
)
Deduplicate-Results -Results $results -Query "React Hooks" -SimilarityThreshold 0.85
#>

param(
    [Parameter(Mandatory=$true)]
    $Results,

    [Parameter(Mandatory=$true)]
    $Query,

    [Parameter(Mandatory=$false)]
    [double]$SimilarityThreshold = 0.85
)

function Calculate-TFIDF {
    param([string]$Text, [string[]]$Documents)

    # 分词
    $tokens = $Text -split '\s+' | Where-Object { $_ -match '[a-zA-Z0-9_\-]' } | ForEach-Object { $_.ToLower() }

    # 计算词频
    $tf = @{}
    $tokens | ForEach-Object { $tf[$_] = ($tf.ContainsKey($_) ? $tf[$_] : 0) + 1 }

    # 计算IDF
    $idf = @{}
    $documents | ForEach-Object {
        $docTokens = $_ -split '\s+' | Where-Object { $_ -match '[a-zA-Z0-9_\-]' } | ForEach-Object { $_.ToLower() }
        $uniqueTokens = $docTokens | Select-Object -Unique
        $uniqueTokens | ForEach-Object {
            $count = ($documents | ForEach-Object { $_ -split '\s+' | Where-Object { $_ -eq $_ } } | Where-Object { $_ -eq $_ }).Count
            $idf[$_] = [Math]::Log(1 + $count)
        }
    }

    # 返回TF-IDF向量
    return $tokens | Where-Object { $tf[$_] -gt 0 } | ForEach-Object {
        @{
            term = $_
            tfidf = $tf[$_] * $idf[$_] / ($tokens.Count)
        }
    }
}

function Calculate-Similarity {
    param(
        [PSCustomObject]$Text1,
        [PSCustomObject]$Text2
    )

    $doc1 = $Text1.content
    $doc2 = $Text2.content

    # 合并所有文档用于IDF计算
    $allDocs = @($doc1, $doc2)

    # 计算TF-IDF
    $vec1 = Calculate-TFIDF -Text $doc1 -Documents $allDocs
    $vec2 = Calculate-TFIDF -Text $doc2 -Documents $allDocs

    # 计算余弦相似度
    $dotProduct = ($vec1.term, $vec2.term | ForEach-Object {
        $tfidf1 = $vec1 | Where-Object { $_.term -eq $_ } | Select-Object -ExpandProperty tfidf
        $tfidf2 = $vec2 | Where-Object { $_.term -eq $_ } | Select-Object -ExpandProperty tfidf
        return ($tfidf1 -eq $null ? 0 : $tfidf1) * ($tfidf2 -eq $null ? 0 : $tfidf2)
    }) | Measure-Object -Sum

    $norm1 = ($vec1 | Measure-Object -Property tfidf -Sum).Sum
    $norm2 = ($vec2 | Measure-Object -Property tfidf -Sum).Sum

    if ($norm1 -eq 0 -or $norm2 -eq 0) {
        return 0.0
    }

    return $dotProduct.Sum / ($norm1 * $norm2)
}

function Cluster-Results {
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject[]]$Results,

        [Parameter(Mandatory=$false)]
        [double]$SimilarityThreshold = 0.85
    )

    $clustered = @()
    $processed = @()

    foreach ($result in $Results) {
        if ($processed -contains $result.id) {
            continue
        }

        $cluster = [System.Collections.Generic.List[PSCustomObject]]::new()
        $cluster.Add($result)
        $processed += $result.id

        foreach ($other in $Results) {
            if ($processed -contains $other.id -or $result.id -eq $other.id) {
                continue
            }

            $similarity = Calculate-Similarity -Text1 $result -Text2 $other
            if ($similarity -ge $SimilarityThreshold) {
                $cluster.Add($other)
                $processed += $other.id
            }
        }

        $clustered.Add($PSCustomObject @{
            cluster_id = $cluster.Count
            members = $cluster
            max_similarity = ($cluster | ForEach-Object { Calculate-Similarity -Text1 $result -Text2 $_ }) | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum
        })
    }

    return $clustered
}

function Get-UniqueResult {
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject[]]$ClusteredResults
    )

    $uniqueResults = @()

    foreach ($cluster in $ClusteredResults) {
        # 选择相似度最高的结果作为代表
        $representative = $cluster.members | Sort-Object {
            $similarity = Calculate-Similarity -Text1 $cluster.members[0] -Text2 $_
            $similarity
        } -Descending | Select-Object -First 1

        # 附加元数据
        $representative.PSObject.Properties.Remove('id')
        $representative | Add-Member -NotePropertyName 'cluster_id' -NotePropertyValue $cluster.cluster_id
        $representative | Add-Member -NotePropertyName 'similar_count' -NotePropertyValue ($cluster.members.Count - 1)
        $representative | Add-Member -NotePropertyName 'deduplicated' -NotePropertyValue $true

        $uniqueResults += $representative
    }

    return $uniqueResults
}

function Deduplicate-Results {
    param(
        [Parameter(Mandatory=$true)]
        [array]$Results,

        [Parameter(Mandatory=$true)]
        [string]$Query,

        [Parameter(Mandatory=$false)]
        [double]$SimilarityThreshold = 0.85
    )

    Write-Host "🔍 智能去重引擎" -ForegroundColor Cyan
    Write-Host "  查询: $Query" -ForegroundColor Yellow
    Write-Host "  原始结果数: $($Results.Count)" -ForegroundColor Gray
    Write-Host "  相似度阈值: $SimilarityThreshold" -ForegroundColor Gray

    # 聚类相似结果
    $clustered = Cluster-Results -Results $Results -SimilarityThreshold $SimilarityThreshold
    Write-Host "  聚类结果: $($clustered.Count) 个簇" -ForegroundColor Gray

    # 提取唯一结果
    $uniqueResults = Get-UniqueResult -ClusteredResults $clustered

    # 计算相关性评分
    foreach ($result in $uniqueResults) {
        $similarity = Calculate-Similarity -Text1 $result -Text2 @{
            content = $Query
            title = $Query
        }
        $result | Add-Member -NotePropertyName 'relevance' -NotePropertyValue $similarity
    }

    # 按相关性排序
    $sorted = $uniqueResults | Sort-Object { $_.relevance } -Descending

    Write-Host "  去重后结果: $($sorted.Count)" -ForegroundColor Green
    Write-Host "  减少: $($Results.Count - $sorted.Count) 个重复结果" -ForegroundColor Green

    return $sorted
}

# 主程序入口
if ($Results.Count -gt 0) {
    Deduplicate-Results -Results $Results -Query $Query -SimilarityThreshold $SimilarityThreshold
} else {
    Write-Warning "没有搜索结果可去重"
}
