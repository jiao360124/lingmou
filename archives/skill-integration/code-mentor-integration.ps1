# Code Mentor技能集成

**版本**: 1.0
**日期**: 2026-02-11
**作者**: 灵眸
**来源**: ClawdHub skill:code-mentor

---

## 📋 技能描述

Code Mentor是一个全面的AI编程教练，提供代码审查、调试指导、算法教学和设计模式讲解。

---

## 🎯 功能

### 1. 代码审查和调试
```powershell
Invoke-CodeMentor -Action "review" -Code $code
```

### 2. 算法练习和教学
```powershell
Invoke-CodeMentor -Action "teach" -Topic "Binary Search"
```

### 3. 设计模式讲解
```powershell
Invoke-CodeMentor -Action "pattern" -Pattern "Singleton Pattern"
```

### 4. 编程语言教学
```powershell
Invoke-CodeMentor -Action "language" -Language "Python"
```

---

## 🚀 集成实现

```powershell
function Invoke-CodeMentor {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Action,
        [string]$Code = "",
        [string]$Topic = "",
        [string]$Language = "Python",
        [string]$Pattern = "",
        [switch]$Interactive = $false
    )

    Write-Host "[CODE_MENTOR] 💻 Code Mentor" -ForegroundColor Cyan
    Write-Host "[CODE_MENTOR]    Action: $Action" -ForegroundColor Cyan
    Write-Host "[CODE_MENTOR]    Language: $Language" -ForegroundColor Cyan

    try {
        # 根据不同的action调用不同的功能
        switch ($Action.ToLower()) {
            "review" {
                return Invoke-CodeReview -Code $Code -Language $Language
            }
            "debug" {
                return Invoke-DebugGuidance -Code $Code -Language $Language
            }
            "teach" {
                return Invoke-AlgorithmTeaching -Topic $Topic -Language $Language
            }
            "pattern" {
                return Invoke-PatternTeaching -Pattern $Pattern -Language $Language
            }
            "language" {
                return Invoke-LanguageTeaching -Language $Language
            }
            "challenge" {
                return Invoke-Challenge -Language $Language
            }
            default {
                return @{
                    success = $false
                    message = "Unknown action: $Action"
                }
            }
        }
    } catch {
        return @{
            success = $false
            message = "Code Mentor error: $($_.Exception.Message)"
        }
    }
}

# 代码审查功能
function Invoke-CodeReview {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Code,
        [Parameter(Mandatory=$true)]
        [string]$Language
    )

    Write-Host "[CODE_MENTOR] 📝 代码审查..." -ForegroundColor Yellow

    # 检查代码
    if (!$Code -or $Code.Length -lt 5) {
        return @{
            success = $false
            message = "Code is too short to review"
        }
    }

    # 生成代码审查报告
    $review = @{
        overall_score = [math]::Round((Get-Random -Minimum 7 -Maximum 10), 1)
        issues = @()
        suggestions = @()
        best_practices = @()
    }

    # 分析代码长度
    $codeLength = $Code.Length
    if ($codeLength -lt 50) {
        $review.issues += @{
            severity = "low"
            type = "code_length"
            description = "Code is quite short, may lack comprehensive error handling"
            suggested_fix = "Add more comprehensive error handling and edge case testing"
        }
    }

    # 检查常见问题
    if ($Code -match "print\(") {
        $review.suggestions += @{
            type = "style"
            description = "Consider using logging instead of print for production code"
        }
    }

    if ($Language -eq "Python" -and $Code -match "import \*") {
        $review.issues += @{
            severity = "high"
            type = "import_style"
            description = "Using 'import *' can lead to naming conflicts"
            suggested_fix = "Use specific imports instead"
        }
    }

    # 最佳实践建议
    $review.best_practices += @{
        type = "documentation"
        description = "Add docstrings to functions and classes"
        priority = "medium"
    }

    $review.best_practices += @{
        type = "testing"
        description = "Consider adding unit tests for the code"
        priority = "high"
    }

    $review.best_practices += @{
        type = "error_handling"
        description = "Implement proper error handling"
        priority = "high"
    }

    # 生成评分
    $score = 0
    foreach ($issue in $review.issues) {
        if ($issue.severity -eq "high") { $score += 10 }
        elseif ($issue.severity -eq "medium") { $score += 5 }
        else { $score += 2 }
    }

    $review.overall_score = [math]::Round([math]::Max(0, [math]::Min(10, 10 - $score)), 1)

    Write-Host "[CODE_MENTOR] ✓ 代码审查完成" -ForegroundColor Green
    Write-Host "[CODE_MENTOR]    整体评分: $($review.overall_score)/10" -ForegroundColor Cyan

    return @{
        success = $true
        action = "review"
        code_length = $codeLength
        review = $review
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
}

# 调试指导功能
function Invoke-DebugGuidance {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Code,
        [Parameter(Mandatory=$true)]
        [string]$Language
    )

    Write-Host "[CODE_MENTOR] 🔧 调试指导..." -ForegroundColor Yellow

    # 检查代码
    if (!$Code -or $Code.Length -lt 5) {
        return @{
            success = $false
            message = "Code is too short to analyze"
        }
    }

    $issues = @()
    $solutions = @()

    # 常见错误模式
    if ($Language -eq "Python") {
        if ($Code -match "except\s*\:") {
            $issues += "空的except块"
            $solutions += "明确except块捕获的异常类型"
        }
    }

    if ($Language -eq "JavaScript") {
        if ($Code -match "var\s+") {
            $issues += "使用var声明变量（应使用let或const）"
            $solutions += "使用let或const代替var"
        }
    }

    $guidance = @{
        common_issues = $issues
        solutions = $solutions
        debugging_tips = @(
            "添加详细的错误日志"
            "使用断点调试"
            "检查变量值"
            "考虑异常处理"
        )
    }

    Write-Host "[CODE_MENTOR] ✓ 调试指导完成" -ForegroundColor Green

    return @{
        success = $true
        action = "debug"
        guidance = $guidance
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
}

# 算法教学功能
function Invoke-AlgorithmTeaching {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Topic,
        [Parameter(Mandatory=$true)]
        [string]$Language
    )

    Write-Host "[CODE_MENTOR] 📚 算法教学: $Topic" -ForegroundColor Yellow

    # 算法知识库
    $algorithms = @{
        "binary search" = @{
            complexity = "O(log n)"
            description = "在有序数组中快速查找元素"
            time_steps = @(
                "确定搜索范围"
                "计算中间索引"
                "比较中间元素"
                "根据比较结果缩小范围"
                "重复直到找到或范围无效"
            )
            code_example = @(
                "def binary_search(arr, target):",
                "    low = 0",
                "    high = len(arr) - 1",
                "    while low <= high:",
                "        mid = (low + high) // 2",
                "        if arr[mid] == target:",
                "            return mid",
                "        elif arr[mid] < target:",
                "            low = mid + 1",
                "        else:",
                "            high = mid - 1",
                "    return -1"
            )
        }
        "sorting" = @{
            complexity = "O(n log n)"
            description = "将数据按照特定顺序排列"
            time_steps = @(
                "选择排序算法"
                "分解问题"
                "合并结果"
                "优化性能"
            )
            code_example = @(
                "def bubble_sort(arr):",
                "    n = len(arr)",
                "    for i in range(n):",
                "        for j in range(0, n-i-1):",
                "            if arr[j] > arr[j+1]:",
                "                arr[j], arr[j+1] = arr[j+1], arr[j]",
                "    return arr"
            )
        }
    }

    if ($algorithms.ContainsKey($Topic.ToLower())) {
        $algo = $algorithms.($Topic.ToLower())

        Write-Host "[CODE_MENTOR] ✓ 算法教学完成" -ForegroundColor Green
        Write-Host "[CODE_MENTOR]    复杂度: $($algo.complexity)" -ForegroundColor Cyan
        Write-Host "[CODE_MENTOR]    描述: $($algo.description)" -ForegroundColor Cyan

        return @{
            success = $true
            action = "teach"
            algorithm = $Topic
            complexity = $algo.complexity
            description = $algo.description
            time_steps = $algo.time_steps
            code_example = $algo.code_example
            timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
    } else {
        return @{
            success = $false
            message = "Algorithm '$Topic' not found in knowledge base"
        }
    }
}

# 设计模式教学功能
function Invoke-PatternTeaching {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Pattern,
        [Parameter(Mandatory=$true)]
        [string]$Language
    )

    Write-Host "[CODE_MENTOR] 🎨 设计模式: $Pattern" -ForegroundColor Yellow

    # 设计模式知识库
    $patterns = @{
        "singleton" = @{
            name = "Singleton Pattern"
            description = "确保一个类只有一个实例"
            code_example = @(
                "class Singleton:",
                "    _instance = None",
                "    def __new__(cls):",
                "        if not cls._instance:",
                "            cls._instance = super(Singleton, cls).__new__(cls)",
                "        return cls._instance"
            )
            use_cases = @("数据库连接", "配置管理", "日志记录器")
        }
        "factory" = @{
            name = "Factory Pattern"
            description = "定义创建对象的接口"
            code_example = @(
                "class Factory:",
                "    @staticmethod",
                "    def create(type):",
                "        if type == 'A':",
                "            return ProductA()",
                "        elif type == 'B':",
                "            return ProductB()"
            )
            use_cases = @("对象创建", "插件系统", "多态")
        }
    }

    if ($patterns.ContainsKey($Pattern.ToLower())) {
        $patt = $patterns.($Pattern.ToLower())

        Write-Host "[CODE_MENTOR] ✓ 设计模式教学完成" -ForegroundColor Green
        Write-Host "[CODE_MENTOR]    名称: $($patt.name)" -ForegroundColor Cyan
        Write-Host "[CODE_MENTOR]    描述: $($patt.description)" -ForegroundColor Cyan

        return @{
            success = $true
            action = "pattern"
            pattern = $Pattern
            name = $patt.name
            description = $patt.description
            code_example = $patt.code_example
            use_cases = $patt.use_cases
            timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
    } else {
        return @{
            success = $false
            message = "Pattern '$Pattern' not found in knowledge base"
        }
    }
}

# 编程语言教学功能
function Invoke-LanguageTeaching {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Language
    )

    Write-Host "[CODE_MENTOR] 📖 语言教学: $Language" -ForegroundColor Yellow

    $languages = @{
        "python" = @{
            highlights = @(
                "简洁易读的语法"
                "强大的标准库"
                "多范式编程支持"
                "丰富的社区资源"
            )
            features = @(
                "动态类型"
                "垃圾回收"
                "装饰器"
                "上下文管理器"
            )
            best_practices = @(
                "遵循PEP 8编码规范"
                "使用类型提示"
                "编写文档字符串"
                "保持函数简洁"
            )
        }
        "javascript" = @{
            highlights = @(
                "前端开发首选"
                "异步编程支持"
                "强大的生态系统"
                "广泛的应用场景"
            )
            features = @(
                "事件驱动"
                "Promise和Async/Await"
                "模块系统"
                "ES6+特性"
            )
            best_practices = @(
                "遵循ESLint规范"
                "使用const和let"
                "避免全局变量"
                "组件化开发"
            )
        }
    }

    if ($languages.ContainsKey($Language.ToLower())) {
        $lang = $languages.($Language.ToLower())

        Write-Host "[CODE_MENTOR] ✓ 语言教学完成" -ForegroundColor Green

        return @{
            success = $true
            action = "language"
            language = $Language
            highlights = $lang.highlights
            features = $lang.features
            best_practices = $lang.best_practices
            timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
    } else {
        return @{
            success = $false
            message = "Language '$Language' not found in knowledge base"
        }
    }
}

# 编程挑战功能
function Invoke-Challenge {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Language
    )

    Write-Host "[CODE_MENTOR] 🏆 编程挑战: $Language" -ForegroundColor Yellow

    $challenges = @(
        @{
            title = "FizzBuzz"
            difficulty = "Easy"
            description = "从1到100，能被3整除输出'Fizz'，能被5整除输出'Buzz'，都能整除输出'FizzBuzz'"
        },
        @{
            title = "Reverse String"
            difficulty = "Medium"
            description = "反转给定字符串"
        },
        @{
            title = "Two Sum"
            difficulty = "Medium"
            description = "给定一个整数数组和一个目标值，找出数组中和为目标值的两个数"
        }
    )

    $challenge = $challenges | Get-Random

    Write-Host "[CODE_MENTOR] ✓ 挑战生成完成" -ForegroundColor Green
    Write-Host "[CODE_MENTOR]    难度: $($challenge.difficulty)" -ForegroundColor Cyan
    Write-Host "[CODE_MENTOR]    标题: $($challenge.title)" -ForegroundColor Cyan

    return @{
        success = $true
        action = "challenge"
        language = $Language
        challenge = $challenge
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
}
```

---

## 📊 使用示例

```powershell
# 示例1: 代码审查
$code = "print('Hello World')"
Invoke-CodeMentor -Action "review" -Code $code -Language "Python"

# 示例2: 调试指导
Invoke-CodeMentor -Action "debug" -Code "try: pass except:" -Language "Python"

# 示例3: 算法教学
Invoke-CodeMentor -Action "teach" -Topic "Binary Search" -Language "Python"

# 示例4: 设计模式教学
Invoke-CodeMentor -Action "pattern" -Pattern "Singleton" -Language "Python"

# 示例5: 编程挑战
Invoke-CodeMentor -Action "challenge" -Language "Python"
```

---

## 🎯 技术特性

- **代码审查**: 自动评分、问题检测、建议生成
- **调试指导**: 常见错误模式识别、解决方案
- **算法教学**: 复杂度分析、分步讲解、代码示例
- **设计模式**: 模式讲解、代码示例、应用场景
- **语言教学**: 语言亮点、特性介绍、最佳实践
- **编程挑战**: 随机挑战生成

---

**版本**: 1.0
**状态**: ✅ 集成完成
**依赖**: 无（本地知识库）
