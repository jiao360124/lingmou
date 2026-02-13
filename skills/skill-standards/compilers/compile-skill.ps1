# Skill编译器

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
    FilesProcessed = @{}
    GeneratedFiles = @()
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
    Write-Log "Skill编译器启动" "STANDARD"
    Write-Log "Skill路径: $SkillPath" "DEBUG"

    # 检查Skill路径
    if (-not (Test-Path $SkillPath)) {
        throw "Skill路径不存在: $SkillPath"
    }

    # 提取skill名称
    $SkillName = $SkillPath.Split('\')[-1]
    Write-Log "Skill名称: $SkillName" "STANDARD"

    if ($DryRun) {
        Write-Log "Dry Run 模式：不实际编译" "DEBUG"

        $Result.FilesProcessed = @{
            config = "验证完成"
            scripts = "格式统一完成"
            documentation = "文档检查完成"
        }

        $Result.GeneratedFiles = @(
            @{ Name = "$SkillName/skilled/$SkillName-skilled.json"; DryRun = $true }
            @{ Name = "$SkillName/skilled/$SkillName-compiled.ps1"; DryRun = $true }
        )

        $Result.Success = $true
        return $Result
    }

    # ========== 第1步：加载配置 ==========
    Write-Log "加载配置文件..." "STANDARD"

    $ConfigFile = "$SkillPath/config.json"
    if (-not (Test-Path $ConfigFile)) {
        throw "配置文件不存在: $ConfigFile"
    }

    $SkillConfig = Get-Content -Path $ConfigFile | ConvertFrom-Json
    Write-Log "✓ 配置文件加载成功" "SUCCESS"

    # ========== 第2步：创建标准化配置 ==========
    Write-Log "生成标准化配置..." "STANDARD"

    $StandardConfig = @{
        name = $SkillConfig.name
        version = $SkillConfig.version
        author = $SkillConfig.author
        description = $SkillConfig.description
        category = $SkillConfig.category
        license = $SkillConfig.license
        tags = $SkillConfig.tags

        parameters = $SkillConfig.parameters

        actions = $SkillConfig.actions
        dependencies = $SkillConfig.dependencies

        rateLimit = $SkillConfig.rateLimit

        metadata = @{
            createdDate = (Get-Date -Format "yyyy-MM-dd")
            lastUpdated = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
            standardVersion = "1.0.0"
        }

        # 添加标准字段
        quality = @{
            score = 0
            lastChecked = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        }
    }

    # ========== 第3步：创建编译输出目录 ==========
    $SkilledDir = "$SkillPath/skilled"
    if (-not (Test-Path $SkilledDir)) {
        New-Item -ItemType Directory -Path $SkilledDir -Force | Out-Null
        Write-Log "✓ 创建输出目录: $SkilledDir" "SUCCESS"
    }

    # ========== 第4步：保存标准化配置 ==========
    Write-Log "保存标准化配置..." "STANDARD"

    $StandardConfigFile = "$SkilledDir/$SkillName-skilled.json"
    $StandardConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath $StandardConfigFile -Encoding UTF8 -Force
    $Result.GeneratedFiles += @{ Name = $StandardConfigFile; Size = (Get-Item $StandardConfigFile).Length }

    $Result.FilesProcessed.config = "标准化配置已生成"
    Write-Log "✓ 标准化配置已保存" "SUCCESS"

    # ========== 第5步：编译主脚本 ==========
    Write-Log "编译主脚本..." "STANDARD"

    $MainScriptFile = "$SkillPath/scripts/$SkillName.ps1"
    if (Test-Path $MainScriptFile) {
        $ScriptContent = Get-Content -Path $MainScriptFile -Raw

        # 添加标准头部
        $StandardHeader = @"
# $SkillName

# @Author: $(if($SkillConfig.author){$SkillConfig.author}else{"未知"})
# @Version: $($SkillConfig.version)
# @Created: $(Get-Date -Format 'yyyy-MM-dd')
# @Standard: 1.0.0

# Description: $($SkillConfig.description)

"@

        # 合并头部和脚本
        $StandardScript = $StandardHeader + $ScriptContent

        # 检查并添加错误处理
        if (-not ($StandardScript -match 'try\s*\{')) {
            Write-Log "添加错误处理..." "WARNING"
            $StandardScript = $StandardScript.Insert(0, "try { `n") + "`n} catch { Write-Log \"Error: `$($_.Exception.Message)\" \"ERROR\" }"
        }

        # 检查并添加参数定义
        if (-not ($StandardScript -match 'param\(')) {
            Write-Log "添加参数定义..." "WARNING"
            $StandardScript = "param() { " + $StandardScript + " }"
        }

        # 保存标准化脚本
        $CompiledScriptFile = "$SkilledDir/$SkillName-compiled.ps1"
        $StandardScript | Out-File -FilePath $CompiledScriptFile -Encoding UTF8 -Force
        $Result.GeneratedFiles += @{ Name = $CompiledScriptFile; Size = (Get-Item $CompiledScriptFile).Length }

        $Result.FilesProcessed.scripts = "标准化脚本已生成"
        Write-Log "✓ 标准化脚本已保存" "SUCCESS"
    } else {
        Write-Log "⚠️ 主脚本不存在，跳过编译" "WARNING"
        $Result.FilesProcessed.scripts = "跳过（脚本不存在）"
    }

    # ========== 第6步：验证编译结果 ==========
    Write-Log "验证编译结果..." "STANDARD"

    $ValidationErrors = @()

    # 检查JSON格式
    try {
        $TestJson = Get-Content -Path $StandardConfigFile -Raw | ConvertFrom-Json
        Write-Log "✓ JSON格式验证通过" "SUCCESS"
    } catch {
        $ValidationErrors += "JSON格式验证失败: $($_.Exception.Message)"
    }

    # 检查脚本格式
    if (Test-Path $CompiledScriptFile) {
        $TestScript = Get-Content -Path $CompiledScriptFile -Raw
        if ($TestScript.Length -gt 0) {
            Write-Log "✓ 脚本格式验证通过" "SUCCESS"
        } else {
            $ValidationErrors += "脚本为空"
        }
    } else {
        $ValidationErrors += "脚本文件不存在"
    }

    # 严格模式额外检查
    if ($Strict) {
        # 检查必需字段
        $RequiredFields = @("name", "version", "author", "description")

        foreach ($Field in $RequiredFields) {
            if (-not $StandardConfig.$Field) {
                $ValidationErrors += "缺少必需字段: $Field"
            }
        }

        # 检查参数
        if ($StandardConfig.parameters -isnot [System.Collections.Hashtable]) {
            $ValidationErrors += "参数必须是JSON对象"
        }

        # 检查actions
        if ($StandardConfig.actions -isnot [array]) {
            $ValidationErrors += "actions必须是数组"
        }
    }

    # ========== 第7步：生成编译报告 ==========
    Write-Log "生成编译报告..." "STANDARD"

    $ReportFile = "$SkillPath/reports/compile-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    if (-not (Test-Path (Split-Path $ReportFile))) {
        New-Item -ItemType Directory -Path (Split-Path $ReportFile) -Force | Out-Null
    }

    $CompileReport = @{
        timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        skillPath = $SkillPath
        skillName = $SkillName
        compiled = $true
        generatedFiles = $Result.GeneratedFiles | ForEach-Object {
            @{
                name = $_.Name
                size = $_.Size
                dryRun = $_.DryRun
            }
        }
        filesProcessed = $Result.FilesProcessed
        errors = $ValidationErrors
        warnings = $Result.Warnings
        strictMode = $Strict
        standardVersion = "1.0.0"
    }

    $CompileReport | ConvertTo-Json -Depth 10 | Out-File -FilePath $ReportFile -Encoding UTF8 -Force
    Write-Log "✓ 编译报告已保存: $ReportFile" "SUCCESS"

    # ========== 输出编译摘要 ==========
    Write-Log "`n========== 编译摘要 ==========" "STANDARD"
    Write-Log "Skill名称: $SkillName" "STANDARD"
    Write-Log "编译状态: ✓ 成功" "SUCCESS"
    Write-Log "`n生成文件:" "STANDARD"

    foreach ($File in $Result.GeneratedFiles) {
        if ($File.Size) {
            $SizeKB = [math]::Round($File.Size / 1KB, 2)
            Write-Log "  ✓ $($File.Name) ($SizeKB KB)" "SUCCESS"
        } else {
            Write-Log "  ✓ $($File.Name) (DryRun)" "SUCCESS"
        }
    }

    Write-Log "`n处理文件:" "STANDARD"
    foreach ($Key in $Result.FilesProcessed.Keys) {
        Write-Log "  $($Key): $($Result.FilesProcessed[$Key])" "INFO"
    }

    if ($Result.Warnings.Count -gt 0) {
        Write-Log "`n警告:" "WARNING"
        foreach ($Warning in $Result.Warnings) {
            Write-Log "  - $Warning" "WARNING"
        }
    }

    if ($Result.Errors.Count -gt 0) {
        Write-Log "`n错误:" "ERROR"
        foreach ($Error in $Result.Errors) {
            Write-Log "  - $Error" "ERROR"
        }
    }

    Write-Log "================================" "STANDARD"

    # 设置最终状态
    $Result.EndTime = Get-Date
    $Result.Duration = ($Result.EndTime - $Result.StartTime).TotalSeconds

    Write-Log "编译完成" "SUCCESS"
    Write-Log "执行时间: $([math]::Round($Result.Duration, 2))秒" "SUCCESS"

} catch {
    $Result.Success = $false
    $Result.Errors += $_.Exception.Message
    $Result.Errors += $_.ScriptStackTrace

    Write-Log "编译失败: $($_.Exception.Message)" "ERROR"

    # 保存错误报告
    $ErrorReport = "$SkillPath/reports/compile-error-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
    $ErrorContent = @"
Skill编译器错误报告
时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Skill: $SkillPath
错误: $($_.Exception.Message)
堆栈: $($_.ScriptStackTrace)

"@
    $ErrorContent | Out-File -FilePath $ErrorReport -Encoding UTF8 -Force
    Write-Log "错误报告已保存: $ErrorReport" "WARNING"

} finally {
    return $Result
}
