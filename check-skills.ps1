Get-ChildItem -Path "C:\Users\Administrator\.openclaw\workspace\skills" -Directory | ForEach-Object {
    $skillName = $_.Name
    $skillPath = $_.FullName
    $skillFile = Join-Path $skillPath "SKILL.md"
    if (Test-Path $skillFile) {
        $content = Get-Content $skillFile -Raw
        if ($content -match 'metadata.*?openclaw.*?install.*?\[(.*?)\]') {
            $deps = $matches[1].Trim()
            if ($deps -ne '[]') {
                "$skillName : $deps"
            }
        }
    }
}
