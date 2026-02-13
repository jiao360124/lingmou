# Workflow Definitions - 协作流程定义
# 定义常用的跨技能协作流程模板

# Sequential workflows
$SequentialWorkflows = @{
    "code-analysis" = @{
        name = "代码分析工作流"
        description = "使用 Copilot 分析代码，然后用 Code Mentor 进行解释"
        type = "sequential"
        steps = @(
            @{
                skill = "copilot"
                step = "code-analysis"
                input = @{
                    code = "$InputCode"
                    mode = "comprehensive"
                }
                description = "分析代码质量和问题"
            },
            @{
                skill = "code-mentor"
                step = "code-explanation"
                input = @{
                    code = "$InputCode"
                    topic = "code-understanding"
                }
                description = "解释代码逻辑和最佳实践"
            },
            @{
                skill = "rag"
                step = "best-practices"
                input = @{
                    query = "best practices for $($Language) programming"
                    category = "guidelines"
                }
                description = "检索相关最佳实践"
            }
        )
    }

    "documentation-generation" = @{
        name = "文档生成工作流"
        description = "使用 RAG 检索文档，然后生成技术文档"
        type = "sequential"
        steps = @(
            @{
                skill = "rag"
                step = "document-retrieval"
                input = @{
                    query = "$InputTopic documentation"
                    category = "documentation"
                }
                description = "检索相关文档"
            },
            @{
                skill = "auto-gpt"
                step = "document-generation"
                input = @{
                    description = "Generate comprehensive documentation for $InputTopic"
                    goal = "Create markdown documentation with examples"
                }
                description = "生成技术文档"
            }
        )
    }

    "debugging-workflow" = @{
        name = "调试工作流"
        description = "使用多个技能协作进行代码调试"
        type = "sequential"
        steps = @(
            @{
                skill = "copilot"
                step = "bug-detection"
                input = @{
                    code = "$InputCode"
                    mode = "detailed"
                }
                description = "检测代码中的潜在问题"
            },
            @{
                skill = "auto-gpt"
                step = "bug-repair"
                input = @{
                    description = "Debug and fix the code: $InputCode"
                    goal = "Provide corrected code with explanations"
                }
                description = "提供修复方案"
            },
            @{
                skill = "code-mentor"
                step = "best-practice-guidance"
                input = @{
                    code = "$InputCode"
                    topic = "debugging"
                }
                description = "提供调试建议和最佳实践"
            }
        )
    }
}

# Parallel workflows
$ParallelWorkflows = @{
    "comprehensive-analysis" = @{
        name = "综合分析工作流"
        description = "并行分析代码的多个维度"
        type = "parallel"
        parallelCount = 3
        steps = @(
            @{
                skill = "copilot"
                step = "quality-analysis"
                input = @{
                    code = "$InputCode"
                }
                description = "代码质量分析"
            },
            @{
                skill = "code-mentor"
                step = "algorithm-analysis"
                input = @{
                    code = "$InputCode"
                }
                description = "算法复杂度分析"
            },
            @{
                skill = "rag"
                step = "best-practices"
                input = @{
                    query = "best practices for the language used"
                    category = "guidelines"
                }
                description = "最佳实践检索"
            },
            @{
                skill = "exa-web-search-free"
                step = "latest-news"
                input = @{
                    query = "latest trends in $($Language) programming"
                    category = "news"
                }
                description = "最新技术趋势"
            }
        )
    }

    "knowledge-research" = @{
        name = "知识研究工作流"
        description = "并行收集多种来源的信息"
        type = "parallel"
        parallelCount = 2
        steps = @(
            @{
                skill = "rag"
                step = "internal-knowledge"
                input = @{
                    query = "$InputTopic"
                    category = "general"
                }
                description = "从内部知识库检索"
            },
            @{
                skill = "exa-web-search-free"
                step = "external-search"
                input = @{
                    query = "$InputTopic"
                    category = "news"
                }
                description = "从外部搜索收集"
            }
        )
    }

    "task-completion" = @{
        name = "任务完成工作流"
        description = "并行执行多个子任务"
        type = "parallel"
        parallelCount = 2
        steps = @(
            @{
                skill = "auto-gpt"
                step = "task-planning"
                input = @{
                    description = "Plan how to accomplish: $InputTask"
                    goal = "Create a detailed plan"
                }
                description = "任务规划"
            },
            @{
                skill = "auto-gpt"
                step = "task-execution"
                input = @{
                    description = "Execute the following: $InputTask"
                    goal = "Complete the task"
                }
                description = "任务执行"
            }
        )
    }
}

# Conditional workflows
$ConditionalWorkflows = @{
    "smart-debugging" = @{
        name = "智能调试工作流"
        description = "根据代码状态决定执行哪些步骤"
        type = "conditional"
        steps = @(
            @{
                skill = "copilot"
                step = "code-analysis"
                input = @{
                    code = "$InputCode"
                }
                description = "分析代码"
            },
            @{
                skill = "auto-gpt"
                step = "error-detection"
                input = @{
                    code = "$InputCode"
                }
                description = "检测错误（条件：有错误）"
                condition = @{
                    result = @{ skillId = "copilot" }
                    error = "any"
                }
            },
            @{
                skill = "code-mentor"
                step = "explanation"
                input = @{
                    code = "$InputCode"
                }
                description = "解释代码（条件：无错误）"
                condition = @{
                    error = "none"
                }
            }
        )
    }

    "smart-documentation" = @{
        name = "智能文档工作流"
        description = "根据文档需求决定文档类型"
        type = "conditional"
        steps = @(
            @{
                skill = "rag"
                step = "existing-docs"
                input = @{
                    query = "$InputTopic"
                    category = "documentation"
                }
                description = "查找现有文档"
            },
            @{
                skill = "auto-gpt"
                step = "create-new-doc"
                input = @{
                    description = "Create documentation for $InputTopic"
                    goal = "Generate markdown documentation"
                }
                description = "创建新文档（条件：无现有文档）"
                condition = @{
                    result = @{ skillId = "rag" }
                }
            },
            @{
                skill = "auto-gpt"
                step = "update-existing-doc"
                input = @{
                    description = "Update documentation for $InputTopic"
                    goal = "Enhance existing documentation"
                }
                description = "更新现有文档（条件：有现有文档）"
                condition = @{
                    result = @{ skillId = "rag" }
                }
            }
        )
    }
}

# Common workflow presets
$WorkflowPresets = @{
    "analysis" = $ParallelWorkflows["comprehensive-analysis"]
    "debugging" = $SequentialWorkflows["debugging-workflow"]
    "documentation" = $SequentialWorkflows["documentation-generation"]
    "research" = $ParallelWorkflows["knowledge-research"]
    "task-completion" = $ParallelWorkflows["task-completion"]
}

# Export workflows
Export-ModuleMember -Variable "SequentialWorkflows", "ParallelWorkflows", "ConditionalWorkflows", "WorkflowPresets"

# Helper functions
function Get-Workflow {
    param(
        [string]$Name
    )

    if ($SequentialWorkflows.ContainsKey($Name)) {
        return $SequentialWorkflows[$Name]
    } elseif ($ParallelWorkflows.ContainsKey($Name)) {
        return $ParallelWorkflows[$Name]
    } elseif ($ConditionalWorkflows.ContainsKey($Name)) {
        return $ConditionalWorkflows[$Name]
    } elseif ($WorkflowPresets.ContainsKey($Name)) {
        return $WorkflowPresets[$Name]
    } else {
        Write-Host "错误: 找不到工作流 '$Name'" -ForegroundColor Red
        Write-Host "可用的工作流:" -ForegroundColor Yellow
        Write-Host "  Sequential: $($SequentialWorkflows.Keys -join ", ")"
        Write-Host "  Parallel: $($ParallelWorkflows.Keys -join ", ")"
        Write-Host "  Conditional: $($ConditionalWorkflows.Keys -join ", ")"
        Write-Host "  Presets: $($WorkflowPresets.Keys -join ", ")"
        return $null
    }
}

function List-Workflows {
    Write-Host "`n=== 顺序工作流 ===" -ForegroundColor Cyan
    $SequentialWorkflows.GetEnumerator() | ForEach-Object {
        Write-Host "`n[$($_.Key)] $($_.Value.name)" -ForegroundColor Green
        Write-Host "  描述: $($_.Value.description)" -ForegroundColor Gray
        Write-Host "  步骤: $($_.Value.steps.Count)" -ForegroundColor Gray
    }

    Write-Host "`n=== 并行工作流 ===" -ForegroundColor Cyan
    $ParallelWorkflows.GetEnumerator() | ForEach-Object {
        Write-Host "`n[$($_.Key)] $($_.Value.name)" -ForegroundColor Green
        Write-Host "  描述: $($_.Value.description)" -ForegroundColor Gray
        Write-Host "  步骤: $($_.Value.steps.Count)" -ForegroundColor Gray
        Write-Host "  并行数: $($_.Value.parallelCount)" -ForegroundColor Gray
    }

    Write-Host "`n=== 条件工作流 ===" -ForegroundColor Cyan
    $ConditionalWorkflows.GetEnumerator() | ForEach-Object {
        Write-Host "`n[$($_.Key)] $($_.Value.name)" -ForegroundColor Green
        Write-Host "  描述: $($_.Value.description)" -ForegroundColor Gray
    }

    Write-Host "`n=== 预设工作流 ===" -ForegroundColor Cyan
    $WorkflowPresets.GetEnumerator() | ForEach-Object {
        Write-Host "`n[$($_.Key)] $($_.Value.name)" -ForegroundColor Green
        Write-Host "  描述: $($_.Value.description)" -ForegroundColor Gray
    }
}

# Register helper functions
Export-ModuleMember -Function "Get-Workflow", "List-Workflows"
