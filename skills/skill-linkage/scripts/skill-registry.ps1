# Skill Registry - 技能注册中心
# 让技能能够声明自己的能力和接口

param(
    [Parameter(Mandatory=$false)]
    [string]$Action = "list"
)

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$dataPath = Join-Path $scriptPath "..\data"
if (-not (Test-Path $dataPath)) {
    New-Item -ItemType Directory -Path $dataPath -Force | Out-Null
}

$metaFile = Join-Path $dataPath "skill-meta.json"

# 技能元数据结构
$SkillMetadata = @{
    skills = @(
        @{
            id = "copilot"
            name = "Copilot 智能代码助手"
            version = "1.0"
            description = "提供代码补全、重构建议、错误诊断"
            capabilities = @("code-completion", "refactoring", "debugging", "analysis")
            inputFormat = @{
                type = "code"
                languages = @("javascript", "python", "powershell", "bash")
                requiredFields = @("code", "language")
            }
            outputFormat = @{
                type = "analysis"
                fields = @("suggestions", "quality-score", "issues")
            }
            parameters = @(
                @{
                    name = "code"
                    type = "string"
                    required = $true
                    description = "要分析的代码"
                },
                @{
                    name = "language"
                    type = "string"
                    required = $false
                    default = "auto"
                    description = "编程语言"
                },
                @{
                    name = "mode"
                    type = "string"
                    required = $false
                    default = "comprehensive"
                    description = "分析模式：basic, comprehensive, detailed"
                }
            )
            dependencies = @()
            rateLimit = "1/min"
            executionTime = "5-30 seconds"
        },
        @{
            id = "auto-gpt"
            name = "Auto-GPT 自动化引擎"
            version = "2.0"
            description = "支持复杂任务自动化和跨工具协作"
            capabilities = @("task-execution", "multi-tool", "error-recovery", "automation")
            inputFormat = @{
                type = "task"
                requiredFields = @("description", "goal")
            }
            outputFormat = @{
                type = "execution-report"
                fields = @("status", "steps", "logs", "results")
            }
            parameters = @(
                @{
                    name = "description"
                    type = "string"
                    required = $true
                    description = "任务描述"
                },
                @{
                    name = "goal"
                    type = "string"
                    required = $true
                    description = "期望目标"
                },
                @{
                    name = "tools"
                    type = "array"
                    required = $false
                    default = @()
                    description = "可用的工具列表"
                },
                @{
                    name = "timeout"
                    type = "int"
                    required = $false
                    default = 300
                    description = "超时时间（秒）"
                }
            )
            dependencies = @()
            rateLimit = "5/min"
            executionTime = "1 min - 2 hours"
        },
        @{
            id = "prompt-engineering"
            name = "Prompt Engineering 专家"
            version = "1.0"
            description = "提示优化和质量检查"
            capabilities = @("template", "quality-check", "optimization")
            inputFormat = @{
                type = "text"
                requiredFields = @("prompt")
            }
            outputFormat = @{
                type = "analysis"
                fields = @("score", "issues", "improvements")
            }
            parameters = @(
                @{
                    name = "prompt"
                    type = "string"
                    required = $true
                    description = "要优化的提示"
                },
                @{
                    name = "category"
                    type = "string"
                    required = $false
                    default = "general"
                    description = "提示类别"
                }
            )
            dependencies = @()
            rateLimit = "10/min"
            executionTime = "5-20 seconds"
        },
        @{
            id = "rag"
            name = "RAG 知识库"
            version = "1.0"
            description = "检索增强生成系统"
            capabilities = @("retrieval", "indexing", "faq")
            inputFormat = @{
                type = "query"
                requiredFields = @("query")
            }
            outputFormat = @{
                type = "answers"
                fields = @("sources", "content", "relevance")
            }
            parameters = @(
                @{
                    name = "query"
                    type = "string"
                    required = $true
                    description = "要查询的问题"
                },
                @{
                    name = "category"
                    type = "string"
                    required = $false
                    default = "general"
                    description = "知识类别"
                },
                @{
                    name = "limit"
                    type = "int"
                    required = $false
                    default = 5
                    description = "返回结果数量"
                }
            )
            dependencies = @()
            rateLimit = "2/min"
            executionTime = "3-15 seconds"
        },
        @{
            id = "weather"
            name = "Weather 天气助手"
            version = "1.0"
            description = "提供天气和预报"
            capabilities = @("current", "forecast")
            inputFormat = @{
                type = "location"
                requiredFields = @("location")
            }
            outputFormat = @{
                type = "weather-data"
                fields = @("temperature", "condition", "forecast")
            }
            parameters = @(
                @{
                    name = "location"
                    type = "string"
                    required = $true
                    description = "城市名称"
                },
                {
                    name = "days"
                    type = "int"
                    required = $false
                    default = 1
                    description = "预报天数"
                }
            )
            dependencies = @()
            rateLimit = "1/min"
            executionTime = "2-10 seconds"
        },
        @{
            id = "code-mentor"
            name = "Code Mentor 编程导师"
            version = "1.0"
            description = "编程教学和代码辅导"
            capabilities = @("teaching", "debugging", "explanation", "practice")
            inputFormat = @{
                type = "code"
                requiredFields = @("code")
            }
            outputFormat = @{
                type = "lesson"
                fields = @("explanation", "tips", "examples")
            }
            parameters = @(
                @{
                    name = "code"
                    type = "string"
                    required = $true
                    description = "要学习的代码"
                },
                @{
                    name = "topic"
                    type = "string"
                    required = $false
                    default = "general"
                    description = "学习主题"
                }
            )
            dependencies = @()
            rateLimit = "3/min"
            executionTime = "10-30 seconds"
        },
        @{
            id = "database"
            name = "Database 数据库管理"
            version = "1.0"
            description = "SQL 和 NoSQL 数据库操作"
            capabilities = @("query", "schema", "migration")
            inputFormat = @{
                type = "query"
                requiredFields = @("database", "query")
            }
            outputFormat = @{
                type = "results"
                fields = @("rows", "columns", "statistics")
            }
            parameters = @(
                @{
                    name = "database"
                    type = "string"
                    required = $true
                    description = "数据库类型（sqlite/postgresql/mysql）"
                },
                @{
                    name = "query"
                    type = "string"
                    required = $true
                    description = "SQL查询语句"
                },
                @{
                    name = "params"
                    type = "array"
                    required = $false
                    default = @()
                    description = "查询参数"
                }
            )
            dependencies = @()
            rateLimit = "5/min"
            executionTime = "1-10 seconds"
        },
        @{
            id = "exa-web-search-free"
            name = "Exa Web Search"
            version = "1.0"
            description = "AI 驱动的网络搜索"
            capabilities = @("search", "news", "docs")
            inputFormat = @{
                type = "query"
                requiredFields = @("query")
            }
            outputFormat = @{
                type = "results"
                fields = @("titles", "urls", "snippets")
            }
            parameters = @(
                @{
                    name = "query"
                    type = "string"
                    required = $true
                    description = "搜索查询"
                },
                @{
                    name = "count"
                    type = "int"
                    required = $false
                    default = 5
                    description = "结果数量"
                },
                @{
                    name = "category"
                    type = "string"
                    required = $false
                    default = "general"
                    description = "搜索类别"
                }
            )
            dependencies = @()
            rateLimit = "10/min"
            executionTime = "3-20 seconds"
        }
    )
}

# Export function
function Export-SkillMetadata {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path
    )
    $SkillMetadata | ConvertTo-Json -Depth 10 | Out-File -FilePath $Path -Encoding utf8
}

function Import-SkillMetadata {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path
    )
    $content = Get-Content -Path $Path -Raw -Encoding utf8
    $metadata = $content | ConvertFrom-Json
    return $metadata
}

# Action handlers
switch ($Action) {
    "list" {
        Write-Host "=== 可用技能列表 ===" -ForegroundColor Cyan
        foreach ($skill in $SkillMetadata.skills) {
            Write-Host "`n[{$($skill.id)}] $($skill.name)" -ForegroundColor Green
            Write-Host "  描述: $($skill.description)" -ForegroundColor Gray
            Write-Host "  能力: $($skill.capabilities -join ", ")"
            Write-Host "  输入格式: $($skill.inputFormat.type)"
            Write-Host "  执行时间: $($skill.executionTime)"
            Write-Host "  速率限制: $($skill.rateLimit)"
        }
    }

    "get" {
        param(
            [Parameter(Mandatory=$true)]
            [string]$SkillId
        )

        $skill = $SkillMetadata.skills | Where-Object { $_.id -eq $SkillId }
        if (-not $skill) {
            Write-Host "错误: 找不到技能 '$SkillId'" -ForegroundColor Red
            return
        }

        Write-Host "=== $($skill.name) ===" -ForegroundColor Cyan
        Write-Host "描述: $($skill.description)" -ForegroundColor White
        Write-Host "版本: $($skill.version)" -ForegroundColor Yellow
        Write-Host "`n能力:" -ForegroundColor White
        $skill.capabilities | ForEach-Object { Write-Host "  - $_" -ForegroundColor Gray }
        Write-Host "`n参数:" -ForegroundColor White
        $skill.parameters | ForEach-Object {
            $req = if ($_.required) { "[必需]" } else { "[可选]" }
            Write-Host "  - $($_.name) ($($_.type)) $req" -ForegroundColor Gray
            Write-Host "    描述: $($_.description)" -ForegroundColor DarkGray
        }
        Write-Host "`n输出格式: $($skill.outputFormat.type)" -ForegroundColor Yellow
    }

    "register" {
        param(
            [Parameter(Mandatory=$false)]
            [string]$Add = "false"
        )

        if ($Add -eq "true") {
            Write-Host "技能元数据已保存到: $metaFile" -ForegroundColor Green
            Export-SkillMetadata -Path $metaFile
        } else {
            # 显示注册状态
            $existing = Import-SkillMetadata -Path $metaFile
            $registered = $existing.skills.id
            $total = $SkillMetadata.skills.id

            Write-Host "=== 注册状态 ===" -ForegroundColor Cyan
            Write-Host "已注册技能数量: $($registered.Count) / $($total.Count)" -ForegroundColor Yellow
            Write-Host "`n已注册技能:"
            $registered | ForEach-Object { Write-Host "  - $_" -ForegroundColor Green }
        }
    }

    "export" {
        param(
            [Parameter(Mandatory=$false)]
            [string]$Path = $metaFile
        )

        Export-SkillMetadata -Path $Path
        Write-Host "技能元数据已导出到: $Path" -ForegroundColor Green
    }

    "default" {
        Write-Host "使用方法: skill-registry.ps1 -Action <action> [参数]" -ForegroundColor Yellow
        Write-Host "`n可用操作:" -ForegroundColor Cyan
        Write-Host "  list - 列出所有技能"
        Write-Host "  get -id <id> - 获取特定技能详情"
        Write-Host "  register - 查看注册状态"
        Write-Host "  export - 导出元数据"
    }
}

# Export main functions
Export-ModuleMember -Function "Export-SkillMetadata", "Import-SkillMetadata"
