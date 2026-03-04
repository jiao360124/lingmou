# Copilot Performance Analyzer - 性能优化建议模块

<#
.SYNOPSIS
    性能优化建议模块，检测代码性能问题并提供建议

.DESCRIPTION
    从算法复杂度、内存使用、API调用、循环优化、缓存策略五个维度分析代码性能

.PARAMeter Code
    代码片段

.PARAMeter Language
    代码语言

.OUTPUTS
    性能优化建议对象数组
#>

function Analyze-Performance {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Code,

        [Parameter(Mandatory=$false)]
        [string]$Language = "javascript"
    )

    $suggestions = [System.Collections.ArrayList]::new()

    # 1. 算法复杂度检测
    $complexityIssues = Analyze-Complexity -Code $Code -Language $Language
    $suggestions.AddRange($complexityIssues)

    # 2. 内存使用检测
    $memoryIssues = Analyze-Memory -Code $Code -Language $Language
    $suggestions.AddRange($memoryIssues)

    # 3. API调用检测
    $apiIssues = Analyze-API -Code $Code -Language $Language
    $suggestions.AddRange($apiIssues)

    # 4. 循环优化检测
    $loopIssues = Analyze-Loops -Code $Code -Language $Language
    $suggestions.AddRange($loopIssues)

    # 5. 缓存策略检测
    $cacheIssues = Analyze-Caching -Code $Code -Language $Language
    $suggestions.AddRange($cacheIssues)

    return $suggestions
}

<#
.SYNOPSIS
    分析算法复杂度

.DESCRIPTION
    检测时间复杂度和空间复杂度问题

.PARAMeter Code
    代码片段

.PARAMeter Language
    代码语言

.OUTPUTS
    复杂度问题建议数组
#>

function Analyze-Complexity {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Code,

        [Parameter(Mandatory=$false)]
        [string]$Language = "javascript"
    )

    $issues = [System.Collections.ArrayList]::new()

    # 检测嵌套循环（O(n^2)复杂度）
    if ($Code -match '\bfor\s*\([^)]*\)\s*\{[^}]*for\s*\(.*?\)\s*\{') {
        $suggestion = [PSCustomObject]@{
            Issue = "嵌套循环导致O(n²)时间复杂度"
            Severity = "Medium"
            Recommendation = "使用哈希表或Map优化嵌套循环，或使用生成器"
            Impact = "在大数据量时性能显著下降"
            Before = "for (let i = 0; i < arr.length; i++) { for (let j = 0; j < arr.length; j++) { ... } }"
            After = "const set = new Set(arr); for (let i = 0; i < arr.length; i++) { if (set.has(arr[i])) { ... } }"
            PerformanceGain = "30-50%"
        }
        [void]$issues.Add($suggestion)
    }

    # 检测线性搜索（O(n)）
    if ($Code -match '\.find\(' -and -not $Code -match '\.indexOf\(|\.includes\(|\.some\(|\.every\(') {
        $suggestion = [PSCustomObject]@{
            Issue = "使用find进行线性搜索，复杂度O(n)"
            Severity = "Low"
            Recommendation = "如果需要多次查找，考虑使用Map或对象索引"
            Impact = "在小数据量时影响不大，大数据量时性能下降"
            Before = "const result = arr.find(x => x.id === targetId);"
            After = "const index = arr.findIndex(x => x.id === targetId); const result = arr[index];"
            PerformanceGain = "避免重复查找可提升效率"
        }
        [void]$issues.Add($suggestion)
    }

    # 检测字符串拼接循环（O(n²)）
    if ($Code -match '\.join\(\)') {
        $suggestion = [PSCustomObject]@{
            Issue = "使用join拼接字符串"
            Severity = "Low"
            Recommendation = "join内部已优化，性能良好"
            Impact = "性能影响小"
            Before = "let str = ''; arr.forEach(x => str += x); return str;"
            After = "return arr.join('');"
            PerformanceGain = "10-20%"
        }
        [void]$issues.Add($suggestion)
    }

    return $issues
}

<#
.SYNOPSIS
    分析内存使用

.DESCRIPTION
    检测潜在的内存泄漏和冗余存储

.PARAMeter Code
    代码片段

.PARAMeter Language
    代码语言

.OUTPUTS
    内存问题建议数组
#>

function Analyze-Memory {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Code,

        [Parameter(Mandatory=$false)]
        [string]$Language = "javascript"
    )

    $issues = [System.Collections.ArrayList]::new()

    # 检测重复创建对象
    if ($Code -match 'new\s+\w+\s*\(\)' -and -not $Code -match 'const\s+\w+\s*=\s*new') {
        $suggestion = [PSCustomObject]@{
            Issue = "重复创建对象，建议缓存"
            Severity = "Low"
            Recommendation = "将对象创建提取到循环外部或使用单例模式"
            Impact = "在小规模时影响小，大规模时内存占用增加"
            Before = "for (let i = 0; i < 1000; i++) { const obj = new MyClass(); ... }"
            After = "const obj = new MyClass(); for (let i = 0; i < 1000; i++) { obj.reset(); ... }"
            PerformanceGain = "减少对象创建开销"
        }
        [void]$issues.Add($suggestion)
    }

    # 检测数组过度扩展
    if ($Code -match '\.push\(') {
        $count = ($Code -split '\.push\(').Count - 1
        if ($count -gt 100) {
            $suggestion = [PSCustomObject]@{
                Issue = "数组在循环中频繁扩展"
                Severity = "Medium"
                Recommendation = "预估大小后初始化数组，或使用StringBuilder"
                Impact = "内存分配频繁，影响性能"
                Before = "const arr = []; for (let i = 0; i < 1000; i++) { arr.push(item); }"
                After = "const arr = new Array(1000); for (let i = 0; i < 1000; i++) { arr[i] = item; }"
                PerformanceGain = "减少内存分配次数"
            }
            [void]$issues.Add($suggestion)
        }
    }

    # 检测大对象缓存
    if ($Code -match 'sessionStorage|localStorage|Cache\s*\(') {
        $suggestion = [PSCustomObject]@{
            Issue = "使用sessionStorage/localStorage缓存大对象"
            Severity = "Low"
            Recommendation = "注意localStorage容量限制（5MB）和读取速度"
            Impact = "数据量过大可能导致存储失败或性能下降"
            Before = "localStorage.setItem('bigData', JSON.stringify(largeData));"
            After = "// 考虑IndexedDB或服务端缓存"
            PerformanceGain = "减少数据加载时间"
        }
        [void]$issues.Add($suggestion)
    }

    return $issues
}

<#
.SYNOPSIS
    分析API调用

.DESCRIPTION
    检测过多的API调用和不必要的请求

.PARAMeter Code
    代码片段

.PARAMeter Language
    代码语言

.OUTPUTS
    API问题建议数组
#>

function Analyze-API {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Code,

        [Parameter(Mandatory=$false)]
        [string]$Language = "javascript"
    )

    $issues = [System.Collections.ArrayList]::new()

    # 检测循环中的API调用
    if ($Code -match '\.forEach\(|\.map\(|\.for.*each\(' -and $Code -match 'fetch\(|axios\.|\.get\(|\.post\(') {
        $suggestion = [PSCustomObject]@{
            Issue = "循环中调用API，可能导致N+1问题"
            Severity = "High"
            Recommendation = "使用Promise.all或batch API合并请求"
            Impact = "大量请求导致性能问题、超时和服务器压力"
            Before = "for (const user of users) { const data = await fetch(`/api/user/${user.id}`); }"
            After = "const promises = users.map(u => fetch(`/api/user/${u.id}`)); const results = await Promise.all(promises);"
            PerformanceGain = "减少网络往返，提升20-50%性能"
        }
        [void]$issues.Add($suggestion)
    }

    # 检测频繁的HTTP请求
    if ($Code -match '\.get\(|\.post\(' -and ($Code -split '\.get\(|\.post\(').Count -gt 5) {
        $count = ($Code -split '\.get\(|\.post\(').Count - 1
        $suggestion = [PSCustomObject]@{
            Issue = "检测到多次HTTP请求，建议合并"
            Severity = "Medium"
            Recommendation = "使用批量API或GraphQL减少请求数"
            Impact = "增加网络开销和服务器负载"
            Before = "await fetch('/api/user'); await fetch('/api/posts'); await fetch('/api/comments');"
            After = "await fetch('/api/batch', { body: JSON.stringify({ user, posts, comments }) });"
            PerformanceGain = "减少50%的网络请求"
        }
        [void]$issues.Add($suggestion)
    }

    # 检测缺少错误处理
    if ($Code -match 'fetch\(|axios\.|\.get\(|\.post\(' -and -not $Code -match 'catch|try\s*\{') {
        $suggestion = [PSCustomObject]@{
            Issue = "API调用缺少错误处理"
            Severity = "Medium"
            Recommendation = "添加try-catch处理错误，提供降级方案"
            Impact = "API失败时应用可能崩溃"
            Before = "const data = await fetch('/api/data');"
            After = "try { const response = await fetch('/api/data'); const data = await response.json(); } catch (error) { console.error(error); return null; }"
            PerformanceGain = "提高系统稳定性"
        }
        [void]$issues.Add($suggestion)
    }

    return $issues
}

<#
.SYNOPSIS
    分析循环优化

.DESCRIPTION
    检测循环性能问题

.PARAMeter Code
    代码片段

.PARAMeter Language
    代码语言

.OUTPUTS
    循环问题建议数组
#>

function Analyze-Loops {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Code,

        [Parameter(Mandatory=$false)]
        [string]$Language = "javascript"
    )

    $issues = [System.Collections.ArrayList]::new()

    # 检测在循环中访问DOM
    if ($Code -match '\.forEach\(|\.map\(|\.for.*each\(' -and $Code -match '\.getElementById\(|\.querySelector\(|\.querySelectorAll\(') {
        $suggestion = [PSCustomObject]@{
            Issue = "在循环中访问DOM元素，导致重排重绘"
            Severity = "High"
            Recommendation = "缓存DOM引用，批量更新"
            Impact = "大量重排重绘导致性能严重下降"
            Before = "items.forEach(item => { document.getElementById('container').appendChild(item); });"
            After = "const container = document.getElementById('container'); items.forEach(item => container.appendChild(item));"
            PerformanceGain = "减少80%的DOM操作开销"
        }
        [void]$issues.Add($suggestion)
    }

    # 检测在循环中进行字符串拼接
    if ($Code -match '\.forEach\(|\.map\(' -and $Code -match '\+=\s*[^\+]=') {
        $suggestion = [PSCustomObject]@{
            Issue = "循环中字符串拼接导致O(n²)复杂度"
            Severity = "Medium"
            Recommendation = "使用数组join或模板字符串"
            Impact = "字符串拼接在循环中性能很差"
            Before = "let str = ''; items.forEach(i => str += i);"
            After = "const str = items.join('');"
            PerformanceGain = "提升50-70%性能"
        }
        [void]$issues.Add($suggestion)
    }

    # 检测重复计算
    if ($Code -match '\bfor\s*\(' -and $Code -match '\bfor\s*\(' -and ($Code -split '\bfor\s*\(').Count -gt 2) {
        $suggestion = [PSCustomObject]@{
            Issue = "多重循环且重复计算"
            Severity = "Low"
            Recommendation = "提前计算不变量，使用缓存"
            Impact = "增加不必要的计算开销"
            Before = "for (let i = 0; i < n; i++) { for (let j = 0; j < n; j++) { Math.sqrt(x) } }"
            After = "const sqrtX = Math.sqrt(x); for (let i = 0; i < n; i++) { for (let j = 0; j < n; j++) { sqrtX } }"
            PerformanceGain = "减少重复计算"
        }
        [void]$issues.Add($suggestion)
    }

    return $issues
}

<#
.SYNOPSIS
    分析缓存策略

.DESCRIPTION
    检测可缓存但未缓存的代码

.PARAMeter Code
    代码片段

.PARAMeter Language
    代码语言

.OUTPUTS
    缓存问题建议数组
#>

function Analyze-Caching {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Code,

        [Parameter(Mandatory=$false)]
        [string]$Language = "javascript"
    )

    $issues = [System.Collections.ArrayList]::new()

    # 检测重复API调用
    if ($Code -match 'fetch\(|axios\.|\.get\(' -and ($Code -split 'fetch\(|axios\.|\.get\(').Count -gt 2) {
        $suggestion = [PSCustomObject]@{
            Issue = "检测到重复的API调用"
            Severity = "Medium"
            Recommendation = "添加缓存机制，避免重复请求"
            Impact = "增加网络开销和响应时间"
            Before = "const data1 = await fetch('/api/data'); const data2 = await fetch('/api/data');"
            After = "const cache = await getCachedData('/api/data'); if (cache) { return cache; } const data = await fetch('/api/data'); await cacheData('/api/data', data);"
            PerformanceGain = "减少50-80%的重复请求时间"
        }
        [void]$issues.Add($suggestion)
    }

    # 检测重复计算
    if ($Code -match '\bfor\s*\(' -and ($Code -split '\bfor\s*\(').Count -gt 2) {
        $suggestion = [PSCustomObject]@{
            Issue = "循环中重复计算相同表达式"
            Severity = "Low"
            Recommendation = "提前计算并缓存不变量"
            Impact = "不必要的计算开销"
            Before = "for (let i = 0; i < arr.length; i++) { Math.max(arr[i], arr[i+1]) }"
            After = "const max = Math.max(...arr); for (let i = 0; i < arr.length; i++) { max }"
            PerformanceGain = "减少10-30%计算量"
        }
        [void]$issues.Add($suggestion)
    }

    # 检测读取大量文件
    if ($Code -match 'fs\.readFile\(|\.read\(' -and ($Code -split 'fs\.readFile\(|\.read\(').Count -gt 2) {
        $suggestion = [PSCustomObject]@{
            Issue = "频繁读取文件"
            Severity = "Low"
            Recommendation = "批量读取或使用文件流"
            Impact = "I/O操作可能成为性能瓶颈"
            Before = "files.forEach(f => fs.readFile(f, (err, data) => ...));"
            After = "fs.readFile(files, (err, data) => ...);"
            PerformanceGain = "减少I/O等待时间"
        }
        [void]$issues.Add($suggestion)
    }

    return $issues
}

<#
.SYNOPSIS
    获取性能标签

.DESCRIPTION
    根据严重程度返回性能标签

.PARAMeter Severity
    严重程度

.OUTPUTS
    标签字符串
#>

function Get-PerformanceLabel {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Severity
    )

    switch ($Severity) {
        'High' { return '🔴 High' }
        'Medium' { return '🟡 Medium' }
        'Low' { return '🟢 Low' }
        default { return '⚪ Unknown' }
    }
}

<#
.SYNOPSIS
    生成性能优化报告

.DESCRIPTION
    将所有优化建议生成格式化报告

.PARAMeter Suggestions
    优化建议数组

.OUTPUTS
    格式化报告字符串
#>

function Format-PerformanceReport {
    param(
        [Parameter(Mandatory=$true)]
        $Suggestions
    )

    if ($Suggestions.Count -eq 0) {
        return "✅ 没有检测到性能问题"
    }

    $report = "## 性能优化建议（$($Suggestions.Count)个问题）`n`n"

    foreach ($suggestion in $Suggestions) {
        $report += "### $($suggestion.Issue)`n"
        $report += "**标签**：$(Get-PerformanceLabel -Severity $suggestion.Severity)`n"
        $report += "**建议**：$($suggestion.Recommendation)`n"
        $report += "**影响**：$($suggestion.Impact)`n"

        if ($suggestion.Before -and $suggestion.After) {
            $report += "**优化示例**：`n"
            $report += "```javascript`n"
            $report += "// 优化前：$($suggestion.Before)`n"
            $report += "// 优化后：$($suggestion.After)`n"
            $report += "````n"
        }

        if ($suggestion.PerformanceGain) {
            $report += "**性能提升**：$($suggestion.PerformanceGain)`n"
        }

        $report += "`n"
    }

    return $report
}

# 导出函数
Export-ModuleMember -Function @(
    'Analyze-Performance',
    'Analyze-Complexity',
    'Analyze-Memory',
    'Analyze-API',
    'Analyze-Loops',
    'Analyze-Caching',
    'Get-PerformanceLabel',
    'Format-PerformanceReport'
)
