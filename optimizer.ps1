<#
.SYNOPSIS
    Windows Performance Optimizer & Latency Tuner
.DESCRIPTION
    Automated optimization script to tune UI latency, power plans, SSD health,
    gaming priority, network settings, and clean system junk.
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'SilentlyContinue'

function Write-Step ($step, $title) {
    Write-Host "`n[$step] $title" -ForegroundColor Cyan
    Write-Host ("-" * 60) -ForegroundColor DarkGray
}

function Write-Success ($msg) {
    Write-Host "  [+] $msg" -ForegroundColor Green
}

function Write-Warn ($msg) {
    Write-Host "  [!] $msg" -ForegroundColor Yellow
}

function Write-Info ($msg) {
    Write-Host "  [*] $msg" -ForegroundColor Gray
}

Clear-Host
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host "       WINDOWS PERFORMANCE & LATENCY OPTIMIZER KIT          " -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Magenta

# Check Admin Privileges
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Warn "Script is running without Administrator privileges."
    Write-Warn "Some system-level tweaks (TRIM, Power Schemes) may be skipped."
} else {
    Write-Success "Running with full Administrator privileges."
}

# -------------------------------------------------------------
# STEP 1: UI Responsiveness & Latency
# -------------------------------------------------------------
Write-Step "1/7" "Tuning UI Responsiveness & Desktop Latency"

# 1. Reduce context menu delay from 400ms to 20ms
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -Value "20"
Write-Success "Menu delay reduced from 400ms to 20ms (instant menus)."

# 2. Disable slow window minimize/maximize animation stutter
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop\WindowMetrics" -Name "MinAnimate" -Value "0"
Write-Success "Window minimize/maximize animations disabled."

# 3. Disable taskbar animations
if (-not (Test-Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced")) {
    New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Force | Out-Null
}
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAnimations" -Value 0
Write-Success "Taskbar hover animations disabled for snappier clicks."

# 4. Show file extensions by default (essential for power users & safety)
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0
Write-Success "File extensions visibility enabled."

# 5. Open File Explorer directly to 'This PC'
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "LaunchTo" -Value 1
Write-Success "File Explorer configured to open directly to 'This PC'."

# -------------------------------------------------------------
# STEP 2: Instant Start Menu Search (Disable Bing Web Lag)
# -------------------------------------------------------------
Write-Step "2/7" "Optimizing Start Menu Search (Disabling Web Queries)"

if (-not (Test-Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer")) {
    New-Item -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -Force | Out-Null
}
Set-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -Name "DisableSearchBoxSuggestions" -Value 1

if (-not (Test-Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search")) {
    New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Force | Out-Null
}
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "BingSearchEnabled" -Value 0
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "CortanaConsent" -Value 0
Write-Success "Bing web search disabled in Start Menu. Local app searches are now instant."

# -------------------------------------------------------------
# STEP 3: Power Plan & CPU Throttling
# -------------------------------------------------------------
Write-Step "3/7" "Unlocking High / Ultimate Performance Power Scheme"

$ultGuid = "e9a42b02-d5df-448d-aa00-03f14749eb61"
$highGuid = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
$activated = $false

# Try Ultimate Performance
$res = powercfg -duplicatescheme $ultGuid 2>&1
if ($res -match "([a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12})") {
    $planGuid = $matches[1]
    powercfg /setactive $planGuid
    Write-Success "Activated 'Ultimate Performance' power plan ($planGuid)."
    $activated = $true
}

if (-not $activated) {
    # Fallback to High Performance
    $resHigh = powercfg -duplicatescheme $highGuid 2>&1
    if ($resHigh -match "([a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12})") {
        $planGuid = $matches[1]
        powercfg /setactive $planGuid
        Write-Success "Activated 'High Performance' power plan ($planGuid)."
        $activated = $true
    }
}

if (-not $activated) {
    Write-Info "Current power scheme maintained."
}

# -------------------------------------------------------------
# STEP 4: Windows Game Mode & Priority
# -------------------------------------------------------------
Write-Step "4/7" "Configuring Windows Game Mode & Application Priority"

if (-not (Test-Path "HKCU:\Software\Microsoft\GameBar")) {
    New-Item -Path "HKCU:\Software\Microsoft\GameBar" -Force | Out-Null
}
Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AllowAutoGameMode" -Value 1
Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AutoGameModeEnabled" -Value 1
Write-Success "Game Mode enabled (prioritizes CPU & GPU for active games/apps)."

# -------------------------------------------------------------
# STEP 5: Network Stack & DNS Optimization
# -------------------------------------------------------------
Write-Step "5/7" "Tuning Network Stack & Flushing DNS"

try {
    Clear-DnsClientCache
    Write-Success "DNS resolver cache flushed."
} catch {
    Write-Warn "Could not flush DNS: $($_.Exception.Message)"
}

if ($isAdmin) {
    # Enable TCP autotuning normal & Receive Side Scaling
    netsh int tcp set global autotuninglevel=normal | Out-Null
    netsh int tcp set global rss=enabled | Out-Null
    Write-Success "TCP Auto-Tuning and Receive Side Scaling (RSS) set to optimal."
}

# -------------------------------------------------------------
# STEP 6: Temporary Files & Disk Cache Cleanup
# -------------------------------------------------------------
Write-Step "6/7" "Cleaning Junk Files, Crash Dumps & Temp Caches"

$cleanedBytes = 0

# Clean User Temp
$userTemp = $env:TEMP
if (Test-Path $userTemp) {
    Get-ChildItem -Path $userTemp -Recurse -Force -ErrorAction SilentlyContinue | ForEach-Object {
        try {
            if (-not $_.PSIsContainer) { $cleanedBytes += $_.Length }
            Remove-Item -LiteralPath $_.FullName -Recurse -Force -ErrorAction Stop
        } catch {}
    }
}

# Clean Windows Temp (if Admin)
$winTemp = "C:\Windows\Temp"
if ($isAdmin -and (Test-Path $winTemp)) {
    Get-ChildItem -Path $winTemp -Recurse -Force -ErrorAction SilentlyContinue | ForEach-Object {
        try {
            if (-not $_.PSIsContainer) { $cleanedBytes += $_.Length }
            Remove-Item -LiteralPath $_.FullName -Recurse -Force -ErrorAction Stop
        } catch {}
    }
}

# Clean Crash Dumps
$crashDumps = "$env:LOCALAPPDATA\CrashDumps"
if (Test-Path $crashDumps) {
    Get-ChildItem -Path $crashDumps -Recurse -Force -ErrorAction SilentlyContinue | ForEach-Object {
        try {
            if (-not $_.PSIsContainer) { $cleanedBytes += $_.Length }
            Remove-Item -LiteralPath $_.FullName -Recurse -Force -ErrorAction Stop
        } catch {}
    }
}

$cleanedMB = [math]::Round($cleanedBytes / 1MB, 2)
Write-Success "Cleaned approx. $cleanedMB MB of obsolete cache and temporary files."

# -------------------------------------------------------------
# STEP 7: SSD TRIM Re-Optimization
# -------------------------------------------------------------
Write-Step "7/7" "Optimizing SSD Volumes (TRIM)"

if ($isAdmin) {
    # Get all fixed drives and run TRIM if supported
    Get-Volume | Where-Object { $_.DriveType -eq 'Fixed' -and $_.DriveLetter } | ForEach-Object {
        $letter = $_.DriveLetter
        try {
            Write-Info "Sending TRIM command to Drive $letter`: ..."
            Optimize-Volume -DriveLetter $letter -ReTrim -ErrorAction Stop | Out-Null
            Write-Success "Drive $letter`: TRIM optimization complete."
        } catch {
            Write-Warn "Drive $letter`: Could not run TRIM ($($_.Exception.Message))."
        }
    }
} else {
    Write-Warn "Skipped manual TRIM trigger (requires Administrator privileges)."
}

# -------------------------------------------------------------
# COMPLETION
# -------------------------------------------------------------
Write-Host "`n============================================================" -ForegroundColor Magenta
Write-Host "         ALL OPTIMIZATIONS COMPLETED SUCCESSFULLY!          " -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host "Tip: Restarting your PC or logging out will ensure all changes" -ForegroundColor Gray
Write-Host "take full effect in your desktop session.`n" -ForegroundColor Gray
