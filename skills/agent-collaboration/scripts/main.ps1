<#
.SYNOPSIS
Agent协作系统 - 主程序入口

.DESCRIPTION
Agent协作系统主程序，提供工作流执行、任务调度和结果聚合功能。

.EXAMPLE
.\main.ps1 -Action run -Workflow $workflow -Mode "collaborative"

.EXAMPLE
.\main.ps1 -Action list -Path ".\.agent-collaboration\workflows\"
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("run", "list", "create", "execute")]
    [string]$Action,

    [Parameter(Mandatory=$false)]
    [PSCustomObject]$Workflow,

    [Parameter(Mandatory=$false)]
    [string]$Path = ".\.agent-collaboration\workflows\"",

    [Parameter(Mandatory=$false)]
    [string]$Mode = "collaborative",

    [Parameter(Mandatory=$false)]
    [string]$Name = "Workflow",

    [Parameter(Mandatory=$false)]
    [string]$Description = "Agent协作工作流"
)

function Create-Workflow {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name,

        [Parameter(Mandatory=$true)]
        [string]$Description,

        [Parameter(Mandatory=$true)]
        [array]$Tasks
    )

    Write-Host "📝 创建工作流" -ForegroundColor Cyan
    Write-Host "====================" -ForegroundColor Cyan
    Write-Host "  名称: $Name" -ForegroundColor Yellow
    Write-Host "  描述: $Description" -ForegroundColor Yellow
    Write-Host "  任务数: $($Tasks.Count)" -ForegroundColor Yellow
    Write-Host "====================`n" -ForegroundColor Cyan

    $workflow = [PSCustomObject]@{
        name = $Name
        description = $Description
        mode = "collaborative"
        tasks = $Tasks
        created_at = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
        version = "1.0.0"
    }

    return $workflow
}

function Save-Workflow {
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Workflow,

        [Parameter(Mandatory=$false)]
        [string]$Path
    )

    if ([string]::IsNullOrEmpty($Path)) {
        $Path = ".\.agent-collaboration\workflows\"
    }

    $workflowPath = "$Path$(Get-Date -Format 'yyyyMMdd-HHmmss')-$($Workflow.name).json"

    New-Item -Path $Path -ItemType Directory -Force | Out-Null
    $Workflow | ConvertTo-Json -Depth 10 | Out-File -FilePath $workflowPath -Encoding UTF8 -Force

    Write-Host "✓ 工作流已保存到: $workflowPath" -ForegroundColor Green

    return $workflowPath
}

function List-Workflows {
    param(
        [Parameter(Mandatory=$false)]
        [string]$Path = ".\.agent-collaboration\workflows\"
    )

    Write-Host "📋 列出工作流" -ForegroundColor Cyan
    Write-Host "====================" -ForegroundColor Cyan

    if (-not (Test-Path $Path)) {
        Write-Host "  没有找到工作流文件" -ForegroundColor Yellow
        return
    }

    $workflowFiles = Get-ChildItem -Path $Path -Filter "*.json"

    if ($workflowFiles.Count -eq 0) {
        Write-Host "  没有找到工作流文件" -ForegroundColor Yellow
        return
    }

    foreach ($file in $workflowFiles) {
        if (Test-Path $file.FullName) {
            $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
            if ($content) {
                try {
                    $data = $content | ConvertFrom-Json
                    Write-Host "`n  $($file.Name)" -ForegroundColor Green
                    Write-Host "    名称: $($data.name)" -ForegroundColor Yellow
                    Write-Host "    描述: $($data.description)" -ForegroundColor Gray
                    Write-Host "    任务数: $($data.tasks.Count)" -ForegroundColor Gray
                    Write-Host "    创建时间: $($data.created_at)" -ForegroundColor Gray
                } catch {
                    Write-Host "  $($file.Name) - 格式错误" -ForegroundColor Red
                }
            }
        }
    }

    Write-Host "`n总计: $($workflowFiles.Count) 个工作流" -ForegroundColor Cyan
}

function Run-Workflow {
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Workflow,

        [Parameter(Mandatory=$false)]
        [string]$Mode = "collaborative"
    )

    Write-Host "`n" + ("=" * 50)
    Write-Host "🚀 开始执行Agent协作工作流" -ForegroundColor Cyan
    Write-Host ("=" * 50) + "`n"

    # 调用协作引擎
    $result = & .\scripts\collaboration-engine.ps1 -Workflow $Workflow -Mode $Mode

    return $result
}

# 主程序入口
switch ($Action) {
    "create" {
        if ($null -eq $Workflow) {
            Write-Error "错误: 工作流数据未提供"
            exit 1
        }

        $workflowPath = Save-Workflow -Workflow $Workflow -Path $Path
    }
    "list" {
        List-Workflows -Path $Path
    }
    "execute" {
        if ($null -eq $Workflow) {
            Write-Error "错误: 工作流数据未提供"
            exit 1
        }

        Run-Workflow -Workflow $Workflow -Mode $Mode
    }
    "run" {
        if ($null -eq $Workflow) {
            Write-Error "错误: 工作流数据未提供"
            exit 1
        }

        Run-Workflow -Workflow $Workflow -Mode $Mode
    }
}
