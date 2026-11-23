<#
.SYNOPSIS
    Windows Optimizer - Rollback & Revert Tool
.DESCRIPTION
    Reverts all UI latency, animation, search, and power scheme tweaks
    back to default Windows settings.
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'SilentlyContinue'

Clear-Host
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host "         REVERTING WINDOWS TWEAKS TO DEFAULTS               " -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Yellow

# 1. Revert UI & Animation tweaks
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -Value "400"
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop\WindowMetrics" -Name "MinAnimate" -Value "1"
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAnimations" -Value 1
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 1
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "LaunchTo" -Value 2
Write-Host "[+] Restored Windows default animations, menu delay, and Explorer views." -ForegroundColor Green

# 2. Revert Start Menu Search
Remove-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -Name "DisableSearchBoxSuggestions" -ErrorAction SilentlyContinue
Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "BingSearchEnabled" -ErrorAction SilentlyContinue
Write-Host "[+] Restored default Start Menu search settings." -ForegroundColor Green

# 3. Restore Balanced Power Scheme
$balancedGuid = "381b4222-f694-41f0-9685-ff5bb260df2e"
powercfg /setactive $balancedGuid
Write-Host "[+] Restored 'Balanced' power plan." -ForegroundColor Green

Write-Host "`nAll tweaks reverted to Windows defaults successfully!" -ForegroundColor Green
Write-Host "Please restart or sign out to apply all changes.`n" -ForegroundColor Gray
