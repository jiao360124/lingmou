# Clean up all Gateway-related tasks
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Cleaning up Gateway-related tasks" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get all OpenClaw tasks
$openclawTasks = Get-ScheduledTask | Where-Object {
    $_.TaskName -like "*OpenClaw*"
}

Write-Host "Found $($openclawTasks.Count) OpenClaw-related tasks:" -ForegroundColor Yellow
$openclawTasks | Format-Table TaskName, State, LastRunTime, NextRunTime -AutoSize
Write-Host ""

# List tasks to delete
Write-Host "Tasks to delete:" -ForegroundColor Yellow
$openclawTasks | ForEach-Object {
    Write-Host "  - $($_.TaskName)" -ForegroundColor White
}
Write-Host ""

# Confirm deletion
$confirm = Read-Host "Do you want to delete all these tasks? (yes/no)"

if ($confirm -eq "yes") {
    $deletedCount = 0
    foreach ($task in $openclawTasks) {
        try {
            $result = Unregister-ScheduledTask -TaskName $task.TaskName -Confirm:$false -ErrorAction Stop
            Write-Host "Deleted: $($task.TaskName)" -ForegroundColor Green
            $deletedCount++
        } catch {
            Write-Host "Failed to delete: $($task.TaskName) - $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Cleanup Complete" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Deleted: $deletedCount tasks" -ForegroundColor Green
    Write-Host ""

    # Show remaining tasks
    $remainingTasks = Get-ScheduledTask | Where-Object {
        $_.TaskName -like "*OpenClaw*"
    }
    Write-Host "Remaining OpenClaw tasks: $($remainingTasks.Count)" -ForegroundColor White
    if ($remainingTasks.Count -gt 0) {
        $remainingTasks | Format-Table TaskName, State -AutoSize
    }
} else {
    Write-Host "Deletion cancelled" -ForegroundColor Yellow
}
