<#
.SYNOPSIS
请求验证模块 - 验证API请求参数

.DESCRIPTION
验证API请求参数，包括必填项、数据类型、业务规则等。

.PARAMeter Request
请求数据对象

.PARAMeter Schema
API规范对象

.EXAMPLE
.\api-validator.ps1 -Request $request -Schema $schema
#>

param(
    [Parameter(Mandatory=$true)]
    $Request,

    [Parameter(Mandatory=$true)]
    $Schema
)

function Validate-Parameter {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ParameterName,

        [Parameter(Mandatory=$true)]
        [PSCustomObject]$ParameterSchema,

        [Parameter(Mandatory=$true)]
        $RequestValue,

        [Parameter(Mandatory=$true)]
        [string]$Endpoint
    )

    $errors = @()

    # 检查必填项
    if ($ParameterSchema.required -eq $true) {
        if ($null -eq $RequestValue -or $RequestValue -eq "") {
            $errors += "参数 '$ParameterName' 是必填的"
            return $errors
        }
    }

    # 检查最小长度
    if ($ParameterSchema.min_length -and $RequestValue) {
        if ($RequestValue.Length -lt $ParameterSchema.min_length) {
            $errors += "参数 '$ParameterName' 最小长度为 $($ParameterSchema.min_length)"
        }
    }

    # 检查数据类型
    if ($ParameterSchema.type) {
        switch ($ParameterSchema.type) {
            "string" {
                if (-not ($RequestValue -is [string])) {
                    $errors += "参数 '$ParameterName' 必须是字符串类型"
                }
            }
            "number" {
                if (-not ($RequestValue -is [double] -or $RequestValue -is [int])) {
                    $errors += "参数 '$ParameterName' 必须是数字类型"
                }
            }
            "array" {
                if (-not ($RequestValue -is [array])) {
                    $errors += "参数 '$ParameterName' 必须是数组类型"
                }
            }
            "boolean" {
                if (-not ($RequestValue -is [bool])) {
                    $errors += "参数 '$ParameterName' 必须是布尔类型"
                }
            }
        }
    }

    # 检查枚举值
    if ($ParameterSchema.enum -and $RequestValue) {
        if ($RequestValue -notin $ParameterSchema.enum) {
            $errors += "参数 '$ParameterName' 必须是以下值之一: $($ParameterSchema.enum -join ', ')"
        }
    }

    # 检查数值范围
    if ($ParameterSchema.min -and $RequestValue -is [double]) {
        if ($RequestValue -lt $ParameterSchema.min) {
            $errors += "参数 '$ParameterName' 最小值为 $($ParameterSchema.min)"
        }
    }

    if ($ParameterSchema.max -and $RequestValue -is [double]) {
        if ($RequestValue -gt $ParameterSchema.max) {
            $errors += "参数 '$ParameterName' 最大值为 $($ParameterSchema.max)"
        }
    }

    return $errors
}

function Validate-Endpoint {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Endpoint,

        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Schema
    )

    $endpointConfig = $Schema.endpoints | Where-Object { $_.path -eq $Endpoint }

    if ($null -eq $endpointConfig) {
        return @("端点 '$Endpoint' 不存在")
    }

    return @()
}

function Validate-Request {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Request,

        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Schema,

        [Parameter(Mandatory=$true)]
        [string]$Endpoint
    )

    $allErrors = @()

    # 检查端点是否存在
    $endpointErrors = Validate-Endpoint -Endpoint $Endpoint -Schema $Schema
    $allErrors += $endpointErrors

    if ($endpointErrors.Count -gt 0) {
        return $allErrors
    }

    # 检查端点的请求参数
    $endpointConfig = $Schema.endpoints | Where-Object { $_.path -eq $Endpoint }

    if ($endpointConfig.request) {
        foreach ($paramName in ($endpointConfig.request.PSObject.Properties.Name)) {
            $paramSchema = $endpointConfig.request.$paramName

            $requestValue = if ($Request.ContainsKey($paramName)) { $Request.$paramName } else { $null }

            $paramErrors = Validate-Parameter -ParameterName $paramName -ParameterSchema $paramSchema -RequestValue $requestValue -Endpoint $Endpoint
            $allErrors += $paramErrors
        }
    }

    return $allErrors
}

function Test-Request {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Request,

        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Schema,

        [Parameter(Mandatory=$true)]
        [string]$Endpoint
    )

    $errors = Validate-Request -Request $Request -Schema $Schema -Endpoint $Endpoint

    return @{
        valid = ($errors.Count -eq 0)
        errors = $errors
    }
}

# 主程序入口
$result = Test-Request -Request $Request -Schema $Schema -Endpoint $Endpoint

return $result
