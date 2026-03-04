<#
.SYNOPSIS
图表生成模块 - 生成各种可视化图表

.DESCRIPTION
支持柱状图、折线图、饼图、雷达图等，输出到控制台或文件。

.PARAMeter Type
图表类型：bar, line, pie, radar

.PARAMeter Data
数据对象

.PARAMeter Title
图表标题

.PARAMeter OutputFile
输出文件路径（可选）

.EXAMPLE
.\chart-generator.ps1 -Type "bar" -Data $data -Title "任务进度"
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("bar", "line", "pie", "radar", "histogram")]
    [string]$Type,

    [Parameter(Mandatory=$true)]
    $Data,

    [Parameter(Mandatory=$false)]
    [string]$Title = "Chart",

    [Parameter(Mandatory=$false)]
    [string]$OutputFile
)

function Show-BarChart {
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Data,

        [Parameter(Mandatory=$false)]
        [string]$Title
    )

    Write-Host "`n📊 柱状图: $Title" -ForegroundColor Cyan
    Write-Host "====================" -ForegroundColor Cyan

    $labels = $Data.labels
    $values = $Data.values

    $maxValue = ($values | Measure-Object -Maximum).Maximum
    $barWidth = 50
    $chartWidth = $labels.Count * ($barWidth + 4) + 20

    Write-Host "`n$Title" -ForegroundColor Yellow
    Write-Host "`n" + ("=" * $chartWidth)
    Write-Host (" " * 10) + ("{0,-20} {1,10} {2,12}" -f "标签", "值", "进度条")
    Write-Host ("=" * $chartWidth)

    for ($i = 0; $i -lt $labels.Count; $i++) {
        $label = $labels[$i]
        $value = $values[$i]
        $progress = ($value / $maxValue) * $barWidth

        $bar = "█" * [math]::Round($progress)
        $percentage = "{0,6:N1}%"

        Write-Host (" " * 10) + ("{0,-20} {1,10} {2,12} [{3}]" -f $label, $value, ($percentage -f $value), $bar)
    }

    Write-Host ("=" * $chartWidth) + "`n"
}

function Show-LineChart {
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Data,

        [Parameter(Mandatory=$false)]
        [string]$Title
    )

    Write-Host "`n📈 折线图: $Title" -ForegroundColor Cyan
    Write-Host "====================" -ForegroundColor Cyan

    $labels = $Data.labels
    $series = $Data.series

    $maxValue = ($series | ForEach-Object { $_.values } | Measure-Object -Maximum).Maximum
    $chartWidth = $labels.Count * 8 + 20
    $yAxisWidth = 10
    $xAxisWidth = $labels.Count * 8
    $headerWidth = 30

    Write-Host "`n$Title" -ForegroundColor Yellow
    Write-Host "`n" + ("=" * $chartWidth)

    # Y轴
    Write-Host (" " * 5) + ("Y")
    for ($i = 0; $i -le 10; $i++) {
        $yValue = [math]::Round($maxValue * ($i / 10), 1)
        $yPos = ($i * ($xAxisWidth / 10))
        Write-Host (" " * (5 + $yPos)) + ("{0,6}" -f $yValue)
    }

    # X轴标签和折线
    for ($row = 0; $row -le 10; $row++) {
        $line = " " * ($headerWidth + $yAxisWidth)
        $yValue = [math]::Round($maxValue * ($row / 10), 1)

        foreach ($s = 0; $s -lt $series.Count; $s++) {
            $seriesItem = $series[$s]
            $pointIndex = -1

            # 找到对应的X轴点
            for ($x = 0; $x -lt $labels.Count; $x++) {
                if ($seriesItem.points[$x] -eq $yValue) {
                    $pointIndex = $x
                    break
                }
            }

            if ($pointIndex -ge 0) {
                $xPos = $headerWidth + $yAxisWidth + ($pointIndex * 8)
                $line += "•"
            } else {
                $line += " "
            }
        }

        if ($row -eq 10) {
            # X轴标签
            Write-Host $line + (" " * ($chartWidth - $line.Length)) + "X"
            for ($x = 0; $x -lt $labels.Count; $x++) {
                $xPos = $headerWidth + $yAxisWidth + ($x * 8)
                $line = " " * ($headerWidth + $yAxisWidth)
                for ($sx = 0; $sx -lt $series.Count; $sx++) {
                    $line += " "
                }
                $line += " " * ($xPos - $line.Length) + $labels[$x]
                Write-Host $line
            }
        } else {
            Write-Host $line
        }
    }

    Write-Host ("=" * $chartWidth) + "`n"
}

function Show-PieChart {
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Data,

        [Parameter(Mandatory=$false)]
        [string]$Title
    )

    Write-Host "`n🥧 饼图: $Title" -ForegroundColor Cyan
    Write-Host "====================" -ForegroundColor Cyan

    $labels = $Data.labels
    $values = $Data.values
    $colors = @("绿色", "蓝色", "黄色", "红色", "紫色", "橙色", "粉色", "青色")

    $total = ($values | Measure-Object -Sum).Sum
    $anglePerSlice = 360 / $labels.Count

    Write-Host "`n$Title" -ForegroundColor Yellow
    Write-Host ""

    $x = 0
    $y = 0
    $currentAngle = 0

    for ($i = 0; $i -lt $labels.Count; $i++) {
        $percentage = [math]::Round(($values[$i] / $total) * 100, 1)
        $color = $colors[$i % $colors.Count]

        Write-Host "$color [{$($labels[$i])}] = $($values[$i]) ($percentage%)"

        $endAngle = $currentAngle + $anglePerSlice
        $x = [math]::Round([Math]::Cos([Math]::PI * $currentAngle / 180) * 8)
        $y = [math]::Round([Math]::Sin([Math]::PI * $currentAngle / 180) * 8)

        $endX = [math]::Round([Math]::Cos([Math]::PI * $endAngle / 180) * 8)
        $endY = [math]::Round([Math]::Sin([Math]::PI * $endAngle / 180) * 8)

        $line = (" " * ($x * 2)) + "⬤"
        for ($j = 1; $j -lt [Math]::Abs($endX - $x); $j++) {
            $stepX = [math]::Sign($endX - $x)
            $line += (" " * 2) + "⬤"
        }
        $line += (" " * ($y * 2)) + "⬤"

        Write-Host "  " + $line
        Write-Host (" " * ($x * 2)) + (" " * [Math]::Abs($endX - $x) * 2) + (" " * ($y * 2))

        $currentAngle = $endAngle
    }

    Write-Host "`n总计: $total" -ForegroundColor Green
    Write-Host "====================" -ForegroundColor Cyan
}

function Show-RadarChart {
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Data,

        [Parameter(Mandatory=$false)]
        [string]$Title
    )

    Write-Host "`n🎯 雷达图: $Title" -ForegroundColor Cyan
    Write-Host "====================" -ForegroundColor Cyan

    $labels = $Data.labels
    $dimensions = $Data.dimensions
    $maxValue = ($dimensions | Measure-Object -Maximum).Maximum

    $numSides = $labels.Count
    $radius = 10
    $centerX = 30
    $centerY = 15

    Write-Host "`n$Title" -ForegroundColor Yellow
    Write-Host ""

    # 绘制雷达图背景
    for ($r = $maxValue; $r -ge 0; $r -= $maxValue / 5) {
        $line = " " * $centerX

        for ($s = 0; $s -lt $numSides; $s++) {
            $angle = ($s * 360 / $numSides) - 90
            $distance = $radius * ($r / $maxValue)
            $x = [math]::Round($centerX + [Math]::Cos([Math]::PI * $angle / 180) * $distance)
            $y = [math]::Round($centerY + [Math]::Sin([Math]::PI * $angle / 180) * $distance)

            if ($s -eq 0) {
                $line += "─"
            } else {
                $line += "─"
            }
        }

        Write-Host $line
    }

    # 绘制X轴标签
    for ($s = 0; $s -lt $numSides; $s++) {
        $angle = ($s * 360 / $numSides) - 90
        $x = [math]::Round($centerX + [Math]::Cos([Math]::PI * $angle / 180) * $radius)
        $y = [math]::Round($centerY + [Math]::Sin([Math]::PI * $angle / 180) * $radius)

        $line = " " * ($x - 3)
        for ($l = 0; $l -lt $labels[$s].Length; $l++) {
            $line += $labels[$s][$l]
        }
        Write-Host $line
    }

    # 绘制维度值
    $line = " " * $centerX
    for ($s = 0; $s -lt $numSides; $s++) {
        $angle = ($s * 360 / $numSides) - 90
        $value = $dimensions[$s]
        $distance = $radius * ($value / $maxValue)
        $x = [math]::Round($centerX + [Math]::Cos([Math]::PI * $angle / 180) * $distance)
        $y = [math]::Round($centerY + [Math]::Sin([Math]::PI * $angle / 180) * $distance)

        $line += (" " * ($x - $line.Length)) + "$value"
    }
    Write-Host $line

    Write-Host "====================" -ForegroundColor Cyan
}

# 主程序入口
switch ($Type) {
    "bar" {
        Show-BarChart -Data $Data -Title $Title
    }
    "line" {
        Show-LineChart -Data $Data -Title $Title
    }
    "pie" {
        Show-PieChart -Data $Data -Title $Title
    }
    "radar" {
        Show-RadarChart -Data $Data -Title $Title
    }
    "histogram" {
        Show-RadarChart -Data $Data -Title $Title
    }
}

# 如果有输出文件，保存到文件
if ($OutputFile) {
    $content = Get-Content $OutputFile -Raw -ErrorAction SilentlyContinue
    if ($content) {
        $content += "`n`n" + ("=" * 50) + "`n`n"
    } else {
        $content = ""
    }

    $chartTitle = "图表: $Title"
    $chartContent = Get-Content $OutputFile -Raw -ErrorAction SilentlyContinue
    $chartContent += "`n`n## $chartTitle`n`n"

    # 这里可以添加更多图表内容
    # 目前只是保存到文件
    Set-Content -Path $OutputFile -Value $chartContent
}
