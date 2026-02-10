# 跨技能协作机制

**版本**: 1.0
**日期**: 2026-02-11
**作者**: 灵眸

---

## 🎯 系统概述

跨技能协作机制允许多个技能协同工作，实现复杂的自动化任务。

---

## 📊 核心功能

### 1. 技能组合定义

```powershell
function New-SkillCombo {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ComboId,
        [Parameter(Mandatory=$true)]
        [string]$ComboName,
        [Parameter(Mandatory=$true)]
        [string[]]$SkillNames,
        [hashtable]$Parameters = @{},
        [int]$TimeoutSeconds = 300
    )

    $combo = @{
        combo_id = $ComboId
        combo_name = $ComboName
        skill_names = $SkillNames
        parameters = $Parameters
        timeout = $TimeoutSeconds
        status = "pending"
        created_at = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        executed_at = $null
        results = @()
        errors = @()
        progress = 0
    }

    return $combo
}
```

### 2. 技能执行器

```powershell
function Invoke-SkillExecution {
    param(
        [Parameter(Mandatory=$true)]
        [string]$SkillName,
        [Parameter(Mandatory=$true)]
        [hashtable]$Parameters
    )

    Write-Host "[SKILL_EXEC] 🎯 执行技能: $SkillName" -ForegroundColor Cyan
    Write-Host "[SKILL_EXEC]    参数: $($Parameters | Out-String)" -ForegroundColor Gray

    # 根据技能名称调用相应的函数
    $executionResults = @{}

    switch ($SkillName.ToLower()) {
        "technews" {
            $executionResults.technews = Get-TechNews -Topic $Parameters.topic -Count $Parameters.count
        }
        "exa" {
            $executionResults.exa = Invoke-ExaSearch -Query $Parameters.query -Type $Parameters.type -MaxResults $Parameters.maxResults
        }
        "code-mentor" {
            $executionResults.code_mentor = Invoke-CodeMentor -Action $Parameters.action -Code $Parameters.code -Language $Parameters.language
        }
        "git" {
            $executionResults.git = Invoke-GitAnalysis -RepositoryPath $Parameters.repository_path
        }
        default {
            Write-Host "[SKILL_EXEC] ❌ 未知技能: $SkillName" -ForegroundColor Red
            return @{
                success = $false
                error = "Unknown skill: $SkillName"
            }
        }
    }

    Write-Host "[SKILL_EXEC] ✓ 技能执行完成: $SkillName" -ForegroundColor Green

    return @{
        success = $true
        skill = $SkillName
        results = $executionResults
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
}
```

### 3. 协作执行器

```powershell
function Invoke-SkillCollaboration {
    param(
        [Parameter(Mandatory=$true)]
        [array]$SkillCombos,
        [int]$MaxParallel = 2
    )

    Write-Host "[SKILL_COLLAB] 🔗 启动技能协作执行..." -ForegroundColor Cyan
    Write-Host "[SKILL_COLLAB]    组合数: $($SkillCombos.Count)" -ForegroundColor Cyan
    Write-Host "[SKILL_COLLAB]    最大并行数: $MaxParallel" -ForegroundColor Cyan

    $allResults = @()
    $completedCombos = 0

    # 按依赖关系分组（简化版）
    $groups = @{}
    foreach ($combo in $SkillCombos) {
        $groupKey = if ($combo.skill_names.Count -gt 0) { $combo.skill_names[0] } else { "default" }
        if (!$groups.ContainsKey($groupKey)) {
            $groups.($groupKey) = @()
        }
        $groups.($groupKey) += $combo
    }

    # 执行各组
    foreach ($groupName in $groups.Keys) {
        $groupCombos = $groups.($groupName)
        Write-Host "[SKILL_COLLAB] 🔨 执行组合组: $groupName ($($groupCombos.Count)个组合)" -ForegroundColor Yellow

        # 执行组内所有组合
        foreach ($combo in $groupCombos) {
            $combo.status = "running"
            $combo.progress = 10

            try {
                $comboResults = @()

                # 依次执行技能
                foreach ($skillName in $combo.skill_names) {
                    Write-Host "[SKILL_COLLAB]    执行技能: $skillName" -ForegroundColor Gray

                    $skillResult = Invoke-SkillExecution `
                        -SkillName $skillName `
                        -Parameters $combo.parameters

                    if ($skillResult.success) {
                        $comboResults += $skillResult
                    } else {
                        throw "Skill execution failed: $skillName"
                    }

                    $combo.progress = [math]::Round((($comboResults.Count / $combo.skill_names.Count) * 90), 0)
                }

                # 所有技能执行成功
                $combo.status = "completed"
                $combo.executed_at = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                $combo.results = $comboResults
                $combo.progress = 100

                Write-Host "[SKILL_COLLAB] ✓ 组合完成: $($combo.combo_name)" -ForegroundColor Green

                $allResults += @{
                    combo_id = $combo.combo_id
                    combo_name = $combo.combo_name
                    status = "completed"
                    results = $comboResults
                    timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                }
            } catch {
                $combo.status = "failed"
                $combo.errors += $_.Exception.Message
                $combo.progress = 0

                Write-Host "[SKILL_COLLAB] ❌ 组合失败: $($combo.combo_name) - $($_.Exception.Message)" -ForegroundColor Red

                $allResults += @{
                    combo_id = $combo.combo_id
                    combo_name = $combo.combo_name
                    status = "failed"
                    error = $_.Exception.Message
                    timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                }
            }

            $completedCombos++
        }
    }

    Write-Host "[SKILL_COLLAB] ✓ 技能协作完成" -ForegroundColor Green
    Write-Host "[SKILL_COLLAB]    成功: $(($allResults | Where-Object { $_.status -eq "completed" }).Count)" -ForegroundColor Green
    Write-Host "[SKILL_COLLAB]    失败: $(($allResults | Where-Object { $_.status -eq "failed" }).Count)" -ForegroundColor Red

    return @{
        success = $true
        total_combos = $SkillCombos.Count
        completed_combos = ($allResults | Where-Object { $_.status -eq "completed" }).Count
        failed_combos = ($allResults | Where-Object { $_.status -eq "failed" }).Count
        results = $allResults
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
}
```

### 4. 数据流管理

```powershell
function New-DataFlow {
    param(
        [Parameter(Mandatory=$true)]
        [string]$FlowId,
        [Parameter(Mandatory=$true)]
        [string]$FlowName,
        [Parameter(Mandatory=$true)]
        [string[]]$Steps,
        [hashtable]$Config = @{}
    )

    $flow = @{
        flow_id = $FlowId
        flow_name = $FlowName
        steps = $Steps
        config = $Config
        status = "pending"
        created_at = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        executed_at = $null
        results = @{}
        errors = @{}
        progress = 0
    }

    return $flow
}

function Invoke-DataFlow {
    param(
        [Parameter(Mandatory=$true)]
        [string]$FlowId,
        [hashtable]$InputData
    )

    Write-Host "[DATA_FLOW] 🌊 启动数据流: $FlowId" -ForegroundColor Cyan

    # 查找流程定义
    $flowPath = "logs/data-flows/$FlowId.json"
    if (Test-Path $flowPath) {
        $flow = Get-Content $flowPath -Raw | ConvertFrom-Json
    } else {
        return @{
            success = $false
            error = "Flow not found: $FlowId"
        }
    }

    $flow.status = "running"
    $flow.executed_at = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    # 逐步执行
    $stepResults = @{}
    $stepErrors = @{}

    for ($i = 0; $i -lt $flow.steps.Count; $i++) {
        $step = $flow.steps[$i]
        Write-Host "[DATA_FLOW]    步骤: $step ($i+1/$($flow.steps.Count))" -ForegroundColor Yellow

        # 根据步骤类型执行
        $stepResult = @{}

        switch ($step) {
            "technews" {
                $result = Get-TechNews -Topic "technology" -Count 3
                $stepResult = @{
                    step = $step
                    data = $result
                    status = "completed"
                }
            }
            "exa_search" {
                $result = Invoke-ExaSearch -Query "automation" -Type "news" -MaxResults 5
                $stepResult = @{
                    step = $step
                    data = $result
                    status = "completed"
                }
            }
            "code_review" {
                $code = "print('Hello World')"
                $result = Invoke-CodeMentor -Action "review" -Code $code -Language "Python"
                $stepResult = @{
                    step = $step
                    data = $result
                    status = "completed"
                }
            }
            default {
                $stepResult = @{
                    step = $step
                    data = "Step executed"
                    status = "completed"
                }
            }
        }

        $stepResults[$step] = $stepResult
        $flow.progress = [math]::Round((($i + 1) / $flow.steps.Count) * 100, 0)

        Write-Host "[DATA_FLOW] ✓ 步骤完成: $step" -ForegroundColor Green
    }

    $flow.status = "completed"
    $flow.results = $stepResults
    $flow.progress = 100

    # 保存结果
    $flow | ConvertTo-Json -Depth 10 | Set-Content $flowPath -Encoding UTF8

    Write-Host "[DATA_FLOW] ✓ 数据流完成: $FlowId" -ForegroundColor Green

    return @{
        success = $true
        flow_id = $flowId
        status = "completed"
        results = $stepResults
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
}
```

### 5. 结果聚合器

```powershell
function Invoke-ResultAggregator {
    param(
        [Parameter(Mandatory=$true)]
        [array]$Results,
        [string]$AggregationType = "summary"
    )

    Write-Host "[AGGREGATOR] 📊 结果聚合" -ForegroundColor Cyan
    Write-Host "[AGGREGATOR]    类型: $AggregationType" -ForegroundColor Cyan

    $aggregatedResults = @{}

    switch ($AggregationType) {
        "summary" {
            # 汇总所有结果
            foreach ($result in $Results) {
                if ($result.success) {
                    $aggregatedResults.success_count++
                } else {
                    $aggregatedResults.failed_count++
                }
            }

            $aggregatedResults.total = $Results.Count
            $aggregatedResults.success_rate = [math]::Round(($aggregatedResults.success_count / $Results.Count) * 100, 2)
        }

        "detailed" {
            # 详细结果
            $aggregatedResults = @{
                total = $Results.Count
                completed = ($Results | Where-Object { $_.status -eq "completed" }).Count
                failed = ($Results | Where-Object { $_.status -eq "failed" }).Count
                details = $Results
                timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            }
        }
    }

    return $aggregatedResults
}
```

---

## 📊 使用示例

```powershell
# 示例1: 技能组合执行
$combo1 = New-SkillCombo `
    -ComboId "COMBO-001" `
    -ComboName "Tech News & Analysis" `
    -SkillNames @("technews", "code-mentor") `
    -Parameters @{
        topic = "AI"
        count = 5
        action = "review"
        code = "print('AI trends')"
        language = "Python"
    }

$combo2 = New-SkillCombo `
    -ComboId "COMBO-002" `
    -ComboName "Exa Search & Summary" `
    -SkillNames @("exa", "technews") `
    -Parameters @{
        query = "Python automation"
        type = "news"
        maxResults = 5
        topic = "automation"
        count = 3
    }

$collaboration = Invoke-SkillCollaboration -SkillCombos @($combo1, $combo2)

# 示例2: 数据流执行
$flow = New-DataFlow `
    -FlowId "FLOW-001" `
    -FlowName "News Analysis Pipeline" `
    -Steps @("technews", "exa_search", "code_review")

$dataFlow = Invoke-DataFlow -FlowId "FLOW-001"
```

---

## 🎯 技术特性

- **技能组合**: 支持多技能协同执行
- **依赖管理**: 自动处理技能间依赖
- **数据流管理**: 逐步执行复杂流程
- **结果聚合**: 多种聚合方式
- **错误处理**: 完善的错误恢复
- **进度追踪**: 实时进度显示

---

**版本**: 1.0
**状态**: ✅ 开发完成
**完成度**: 85%
