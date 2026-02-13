# Skill格式验证器

# @Author: 灵眸
# @Version: 1.0.0
# @Date: 2026-02-13

param(
    [Parameter(Mandatory=$true)]
    [string]$SkillPath,

    [Parameter(Mandatory=$false)]
    [switch]$Strict = $false,

    [Parameter(Mandatory=$false)]
    [switch]$DryRun = $false
)

# 初始化结果
$Result = @{
    Success = $true
    SkillPath = $SkillPath
    Strict = $Strict
    DryRun = $DryRun
    StartTime = Get-Date
    EndTime = $null
    Duration = 0
    Messages = @()
    Errors = @()
    Warnings = @()
    Checks = @{
        fileStructure = $false
        metadata = $false
        parameters = $false
        codeQuality = $false
        documentation = $false
    }
    Issues = @()
}

# 日志函数
function Write-Log {
    param([string]$Message, [ValidateSet("INFO", "SUCCESS", "ERROR", "WARNING", "DEBUG", "STANDARD")]
    [string]$Level = "INFO")

    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $Prefix = "[$Timestamp] [$Level]"

    switch ($Level) {
        "INFO"    { Write-Host "$Prefix $Message" -ForegroundColor Cyan }
        "SUCCESS" { Write-Host "$Prefix $Message" -ForegroundColor Green }
        "ERROR"   { Write-Host "$Prefix $Message" -ForegroundColor Red }
        "WARNING" { Write-Host "$Prefix $Message" -ForegroundColor Yellow }
        "DEBUG"   { Write-Host "$Prefix $Message" -ForegroundColor DarkGray }
        "STANDARD" { Write-Host "$Prefix $Message" -ForegroundColor Magenta }
    }

    $Result.Messages += "$Prefix $Message"
}

try {
    Write-Log "Skill格式验证器启动" "STANDARD"
    Write-Log "Skill路径: $SkillPath" "DEBUG"

    # 检查文件结构
    Write-Log "检查文件结构..." "STANDARD"

    if (-not (Test-Path "$SkillPath/SKILL.md")) {
        $Result.Errors += "缺少SKILL.md文件"
        $Result.Issues += @{ Type = "missing_file"; Path = "SKILL.md"; Severity = "error" }
        $Result.Success = $false
    } else {
        $Result.Checks.fileStructure = $true
        Write-Log "✓ SKILL.md 存在" "SUCCESS"
    }

    if (-not (Test-Path "$SkillPath/config.json")) {
        $Result.Errors += "缺少config.json文件"
        $Result.Issues += @{ Type = "missing_file"; Path = "config.json"; Severity = "error" }
        $Result.Success = $false
    } else {
        $Result.Checks.fileStructure = $true
        Write-Log "✓ config.json 存在" "SUCCESS"
    }

    if (-not (Test-Path "$SkillPath/scripts")) {
        $Result.Errors += "缺少scripts目录"
        $Result.Issues += @{ Type = "missing_dir"; Path = "scripts"; Severity = "error" }
        $Result.Success = $false
    } else {
        $Result.Checks.fileStructure = $true
        Write-Log "✓ scripts目录存在" "SUCCESS"
    }

    # 加载配置
    if ($Result.Success -and -not $DryRun) {
        $ConfigFile = "$SkillPath/config.json"

        try {
            $SkillConfig = Get-Content -Path $ConfigFile | ConvertFrom-Json
            Write-Log "✓ 配置文件加载成功" "SUCCESS"

            # 检查必需字段
            $RequiredFields = @("name", "version", "author", "description", "category")
            $MissingFields = @()

            foreach ($Field in $RequiredFields) {
                if (-not $SkillConfig.$Field) {
                    $MissingFields += $Field
                }
            }

            if ($MissingFields.Count -gt 0) {
                $Result.Errors += "缺少必需字段: $($MissingFields -join ', ')"
                $Result.Issues += @{ Type = "missing_field"; Fields = $MissingFields; Severity = "error" }
                $Result.Success = $false
            } else {
                $Result.Checks.metadata = $true
                Write-Log "✓ 元数据完整" "SUCCESS"
                Write-Log "  Skill名称: $($SkillConfig.name)" "DEBUG"
                Write-Log "  版本: $($SkillConfig.version)" "DEBUG"
                Write-Log "  作者: $($SkillConfig.author)" "DEBUG"
            }

            # 检查版本格式
            if ($SkillConfig.version -notmatch '^(\d+\.\d+\.\d+)(?:-(\w+))?$') {
                $Result.Warnings += "版本格式不符合semver: $($SkillConfig.version)"
                $Result.Issues += @{ Type = "version_format"; Value = $SkillConfig.version; Severity = "warning" }
            }

            # 检查参数定义
            if ($SkillConfig.parameters -isnot [System.Collections.Hashtable]) {
                $Result.Errors += "parameters必须是JSON对象"
                $Result.Issues += @{ Type = "parameter_format"; Severity = "error" }
                $Result.Success = $false
            } else {
                $Result.Checks.parameters = $true
                Write-Log "✓ 参数定义正确" "SUCCESS"
                Write-Log "  参数数量: $($SkillConfig.parameters.Count)" "DEBUG"
            }

            # 严格模式检查
            if ($Strict) {
                # 检查可选字段
                $OptionalFields = @(
                    "actions", "dependencies", "rateLimit", "performance",
                    "testing", "documentation", "metadata", "license", "tags"
                )

                foreach ($Field in $OptionalFields) {
                    if (-not $SkillConfig.$Field) {
                        $Result.Warnings += "可选字段缺失: $Field"
                        $Result.Issues += @{ Type = "missing_optional"; Field = $Field; Severity = "warning" }
                    }
                }

                # 检查actions
                if ($SkillConfig.actions -and $SkillConfig.actions -isnot [array]) {
                    $Result.Errors += "actions必须是数组"
                    $Result.Issues += @{ Type = "actions_format"; Severity = "error" }
                    $Result.Success = $false
                }

                # 检查dependencies
                if ($SkillConfig.dependencies -and $SkillConfig.dependencies -isnot [array]) {
                    $Result.Errors += "dependencies必须是数组"
                    $Result.Issues += @{ Type = "dependencies_format"; Severity = "error" }
                    $Result.Success = $false
                }
            }

        } catch {
            $Result.Errors += "配置文件解析失败: $($_.Exception.Message)"
            $Result.Issues += @{ Type = "config_parse"; Error = $_.Exception.Message; Severity = "error" }
            $Result.Success = $false
        }
    } else {
        Write-Log "✓ Dry Run模式：跳过详细检查" "DEBUG"
    }

    # 检查代码质量（如果有主脚本）
    Write-Log "检查代码质量..." "STANDARD"

    $MainScript = "$SkillPath/scripts/$($SkillConfig.name).ps1"

    if (Test-Path $MainScript) {
        $CodeContent = Get-Content -Path $MainScript -Raw

        # 检查错误处理
        if (-not ($CodeContent -match 'try\s*\{')) {
            $Result.Warnings += "主脚本缺少错误处理"
            $Result.Issues += @{ Type = "missing_error_handling"; Severity = "warning" }
        } else {
            $Result.Checks.codeQuality = $true
            Write-Log "✓ 错误处理已存在" "SUCCESS"
        }

        # 检查参数定义
        if (-not ($CodeContent -match 'param\(')) {
            $Result.Warnings += "主脚本缺少参数定义"
            $Result.Issues += @{ Type = "missing_parameters"; Severity = "warning" }
        } else {
            $Result.Checks.codeQuality = $true
            Write-Log "✓ 参数定义已存在" "SUCCESS"
        }
    } else {
        Write-Log "⚠️ 主脚本不存在，跳过代码质量检查" "WARNING"
    }

    # 检查文档
    Write-Log "检查文档..." "STANDARD"

    if ($Strict) {
        if (-not (Test-Path "$SkillPath/README.md")) {
            $Result.Warnings += "缺少README.md"
            $Result.Issues += @{ Type = "missing_readme"; Severity = "warning" }
        } else {
            $Result.Checks.documentation = $true
            Write-Log "✓ README.md 存在" "SUCCESS"
        }

        if (-not (Test-Path "$SkillPath/tests")) {
            $Result.Warnings += "缺少tests目录"
            $Result.Issues += @{ Type = "missing_tests"; Severity = "warning" }
        } else {
            $Result.Checks.documentation = $true
            Write-Log "✓ tests目录存在" "SUCCESS"
        }
    }

    # 生成验证报告
    Write-Log "生成验证报告..." "STANDARD"

    $ReportFile = "$SkillPath/reports/validation-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    if (-not (Test-Path (Split-Path $ReportFile))) {
        New-Item -ItemType Directory -Path (Split-Path $ReportFile) -Force | Out-Null
    }

    $ValidationReport = @{
        timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        skillPath = $SkillPath
        success = $Result.Success
        checks = $Result.Checks
        issues = $Result.Issues
        errors = $Result.Errors
        warnings = $Result.Warnings
        strictMode = $Strict
    }

    $ValidationReport | ConvertTo-Json -Depth 10 | Out-File -FilePath $ReportFile -Encoding UTF8 -Force

    Write-Log "验证报告已保存: $ReportFile" "SUCCESS"

    # 输出摘要
    Write-Log "========== 验证摘要 ==========" "STANDARD"
    Write-Log "状态: $($Result.Success ? '通过' : '失败')" "STANDARD"
    Write-Log "检查项: $($Result.Checks | ConvertTo-Json -Compress)" "DEBUG"
    Write-Log "错误数: $($Result.Errors.Count)" "ERROR"
    Write-Log "警告数: $($Result.Warnings.Count)" "WARNING"
    Write-Log "================================" "STANDARD"

    if ($Result.Errors.Count -gt 0) {
        Write-Log "`n错误详情:" "ERROR"
        foreach ($Error in $Result.Errors) {
            Write-Log "  - $Error" "ERROR"
        }
    }

    if ($Result.Warnings.Count -gt 0) {
        Write-Log "`n警告详情:" "WARNING"
        foreach ($Warning in $Result.Warnings) {
            Write-Log "  - $Warning" "WARNING"
        }
    }

    # 设置最终状态
    $Result.EndTime = Get-Date
    $Result.Duration = ($Result.EndTime - $Result.StartTime).TotalSeconds

} catch {
    $Result.Success = $false
    $Result.Errors += $_.Exception.Message
    $Result.Errors += $_.ScriptStackTrace

    Write-Log "验证失败: $($_.Exception.Message)" "ERROR"

} finally {
    return $Result
}
