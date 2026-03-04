# Search for task by GUID
$guid = "3a80f13c-de6e-41f9-b117-3ce626700f5e"

Write-Host "Searching for task with GUID: $guid" -ForegroundColor Yellow

# Method 1: Search in task names
Write-Host "`nMethod 1: Search in Task Names" -ForegroundColor Cyan
$tasks = Get-ScheduledTask
$foundInName = $tasks | Where-Object { $_.TaskName -like "*$guid*" }
if ($foundInName) {
    $foundInName | Format-Table TaskName, TaskPath, State, LastRunTime, NextRunTime -AutoSize
} else {
    Write-Host "Not found in Task Names" -ForegroundColor Red
}

# Method 2: Search in Task Paths
Write-Host "`nMethod 2: Search in Task Paths" -ForegroundColor Cyan
$foundInPath = $tasks | Where-Object { $_.TaskPath -like "*$guid*" }
if ($foundInPath) {
    $foundInPath | Format-Table TaskName, TaskPath, State, LastRunTime, NextRunTime -AutoSize
} else {
    Write-Host "Not found in Task Paths" -ForegroundColor Red
}

# Method 3: Search in Task Definitions
Write-Host "`nMethod 3: Search in Task Definitions" -ForegroundColor Cyan
$tasks | ForEach-Object {
    $task = Get-ScheduledTask -TaskName $_.TaskName -ErrorAction SilentlyContinue
    if ($task) {
        if ($task.TaskDefinition.Settings.RegistrationInfo.Id -like "*$guid*" -or
            $task.TaskDefinition.RegistrationInfo.Date -like "*$guid*" -or
            $task.TaskDefinition.RegistrationInfo.Author -like "*$guid*") {
            Write-Host "Found in Task: $($_.TaskName)" -ForegroundColor Green
            Write-Host "  TaskPath: $($_.TaskPath)" -ForegroundColor White
            Write-Host "  State: $($task.State)" -ForegroundColor White
        }
    }
}

# Method 4: Search all tasks with verbose output
Write-Host "`nMethod 4: Verbose search of all tasks" -ForegroundColor Cyan
$tasks | ForEach-Object {
    $task = Get-ScheduledTask -TaskName $_.TaskName -ErrorAction SilentlyContinue
    if ($task) {
        $xml = $task.TaskDefinition
        $properties = @(
            $xml.Settings.RegistrationInfo.Id,
            $xml.RegistrationInfo.Date,
            $xml.RegistrationInfo.Author,
            $xml.RegistrationInfo.Version,
            $xml.RegistrationInfo.Description
        )

        foreach ($prop in $properties) {
            if ($prop -like "*$guid*") {
                Write-Host "Found in Task: $($_.TaskName)" -ForegroundColor Green
                Write-Host "  TaskPath: $($_.TaskPath)" -ForegroundColor White
                Write-Host "  State: $($task.State)" -ForegroundColor White
                Write-Host "  RegistrationInfo.Id: $prop" -ForegroundColor Cyan
            }
        }
    }
}

# Method 5: Check if it's a session or other type
Write-Host "`nMethod 5: Check for other types" -ForegroundColor Cyan
Write-Host "This GUID might be:" -ForegroundColor White
Write-Host "  - A session ID (not a scheduled task)" -ForegroundColor Yellow
Write-Host "  - A message/notification ID" -ForegroundColor Yellow
Write-Host "  - A temporary reference ID" -ForegroundColor Yellow
Write-Host "  - Not a Windows scheduled task" -ForegroundColor Yellow

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Search Complete" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
