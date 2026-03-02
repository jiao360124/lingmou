$skills = Get-ChildItem -Path "C:\Users\Administrator\.openclaw\workspace\skills" -Directory
$extraModulesFound = @()

foreach ($skill in $skills) {
    $skillName = $skill.Name
    $extraModules = Get-ChildItem -Path $skill.FullName -Directory -ErrorAction SilentlyContinue

    if ($extraModules) {
        $moduleNames = $extraModules | Select-Object -ExpandProperty Name -Join ", "
        $extraModulesFound += "$skillName : $moduleNames"
    }
}

if ($extraModulesFound.Count -gt 0) {
    Write-Host "发现以下技能包含额外模块:"
    $extraModulesFound | ForEach-Object { Write-Host "  $_" }
} else {
    Write-Host "所有技能目录结构正常，无额外模块"
}
