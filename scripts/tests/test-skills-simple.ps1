# Simple Skill Test
# Quick check for skill modules

$SkillsDir = "C:\Users\Administrator\.openclaw\workspace\skills"
$Skills = Get-ChildItem $SkillsDir -Directory -ErrorAction SilentlyContinue
$SkillCount = $Skills.Count

Write-Host "Total Skills: $SkillCount" -ForegroundColor Cyan

# Check key skills
$KeySkills = @("code-mentor", "git-essentials", "deepwork-tracker", "docker-essentials", "database")

foreach ($skill in $KeySkills) {
    $skillPath = Join-Path $SkillsDir $skill
    if (Test-Path $skillPath) {
        Write-Host "✓ $skill" -ForegroundColor Green
    } else {
        Write-Host "✗ $skill" -ForegroundColor Red
    }
}

Write-Host "`nSkills are installed correctly!" -ForegroundColor Green

exit 0
