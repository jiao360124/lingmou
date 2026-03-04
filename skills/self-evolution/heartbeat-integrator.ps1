# Heartbeat Integration System

# @Author: LingMou
# @Version: 1.0.0
# @Date: 2026-02-14

function Start-HeartbeatIntegration {
    param(
        [int]$IntervalMinutes = 30,
        [switch]$Start = $false
    )

    Write-Host "`n========== Heartbeat Integration System Started ==========" -ForegroundColor Magenta
    Write-Host "Interval: $IntervalMinutes minutes" -ForegroundColor Cyan
    Write-Host "Auto Start: $Start" -ForegroundColor Cyan

    # Initialize Task Queue
    . "$PSScriptRoot/heartbeat-task-queue.ps1"

    # Initialize Notification System
    . "$PSScriptRoot/heartbeat-notifications.ps1"

    if ($Start) {
        Start-HeartbeatCycle
    }
}

function Process-HeartbeatQueue {
    Write-Host "`n========== Processing Heartbeat Queue ==========" -ForegroundColor Magenta

    . "$PSScriptRoot/heartbeat-task-queue.ps1"

    $QueueStatus = Get-QueueStatus
    Write-Host "Current Queue Status:" -ForegroundColor Cyan
    Write-Host "  Total: $($QueueStatus.total)" -ForegroundColor Cyan
    Write-Host "  Completed: $($QueueStatus.completed)" -ForegroundColor Cyan
    Write-Host "  Pending: $($QueueStatus.pending)" -ForegroundColor Cyan
    Write-Host "  Failed: $($QueueStatus.failed)" -ForegroundColor Cyan

    Process-Queue -DryRun:$false

    if ($TaskQueue.tasks.Count -ge 100) {
        Send-QueueNotification -Count $TaskQueue.tasks.Count -Max 100
    }

    Clear-CompletedTasks

    $CurrentTasks = Get-QueueTasks -Limit 5
    if ($CurrentTasks.Count -gt 0) {
        Write-Host "`nCurrent Tasks:" -ForegroundColor Cyan
        foreach ($Task in $CurrentTasks) {
            Write-Host "  - $($Task.name) [$($Task.status)]" -ForegroundColor Cyan
        }
    }
}

function Start-HeartbeatCycle {
    Write-Host "`nStarting Heartbeat Auto-Cycle..." -ForegroundColor Green

    $Interval = 30

    while ($true) {
        try {
            Process-HeartbeatQueue
            Write-Host "`nWaiting $Interval seconds..." -ForegroundColor DarkGray
            Start-Sleep -Seconds $Interval
        } catch {
            Write-Host "Error in heartbeat cycle: $($_.Exception.Message)" -ForegroundColor Red
            Start-Sleep -Seconds 10
        }
    }
}

function Add-HeartbeatTask {
    param(
        [string]$Name,
        [string]$Action,
        [string]$Priority = "normal",
        [int]$DelaySeconds = 0
    )

    . "$PSScriptRoot/heartbeat-task-queue.ps1"

    $Task = Add-Task `
        -Name $Name `
        -Action $Action `
        -Priority $Priority `
        -DelaySeconds $DelaySeconds

    if ($Task) {
        Send-Notification -Type "task-completed" -Data @{taskName = $Task.name} -Priority "normal"
    }

    return $Task
}

function Get-HeartbeatStats {
    . "$PSScriptRoot/heartbeat-task-queue.ps1"

    $QueueStats = Get-QueueStatus
    $NotificationStats = Get-NotificationHistory -Limit 10

    return @{
        queue = $QueueStats
        notifications = @{
            total = ($NotificationStats).Count
            recent = $NotificationStats
        }
        timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }
}

# Main Entry
param(
    [ValidateSet("status", "start")]
    [string]$Mode = "status"
)

. "$PSScriptRoot/heartbeat-task-queue.ps1"
. "$PSScriptRoot/heartbeat-notifications.ps1"

switch ($Mode) {
    "status" {
        $Stats = Get-HeartbeatStats
        Write-Host "`n========== Heartbeat System Status ==========" -ForegroundColor Magenta
        Write-Host "Queue Status:" -ForegroundColor Yellow
        Write-Host "  Total: $($Stats.queue.total)" -ForegroundColor Cyan
        Write-Host "  Completed: $($Stats.queue.completed)" -ForegroundColor Cyan
        Write-Host "  Pending: $($Stats.queue.pending)" -ForegroundColor Cyan
        Write-Host "  Failed: $($Stats.queue.failed)" -ForegroundColor Cyan
        Write-Host "`nNotification Stats:" -ForegroundColor Yellow
        Write-Host "  Total: $($Stats.notifications.total)" -ForegroundColor Cyan
        Write-Host "  Timestamp: $($Stats.timestamp)" -ForegroundColor Cyan
        Write-Host "==============================================" -ForegroundColor Magenta
    }

    "start" {
        Start-HeartbeatIntegration -IntervalMinutes 30 -Start:$true
    }
}
