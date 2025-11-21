<#
    Windows Defender Killer
    Menu-driven PowerShell helper to apply various Defender-disabling methods as described in AGENTS.md.
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$LogPath = Join-Path -Path $PSScriptRoot -ChildPath "windows-defender-killer.log"

function Write-Log {
    param(
        [Parameter(Mandatory)][string]$Message,
        [ValidateSet('INFO','WARN','ERROR')][string]$Level = 'INFO'
    )
    $timestamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    $entry = "[$timestamp][$Level] $Message"
    $foreground = switch ($Level) {
        'INFO' { 'White' }
        'WARN' { 'Yellow' }
        'ERROR' { 'Red' }
        default { 'White' }
    }
    Write-Host $entry -ForegroundColor $foreground
    Add-Content -Path $LogPath -Value $entry
}

function Confirm-Action {
    param(
        [Parameter(Mandatory)][string]$Prompt
    )
    do {
        $response = Read-Host "$Prompt (y/n)"
    } while ($response -notmatch '^[ynYN]$')
    return $response.ToLower() -eq 'y'
}

function Invoke-CommandSafe {
    param(
        [Parameter(Mandatory)][scriptblock]$ScriptBlock,
        [string]$Description = 'Executing command'
    )
    Write-Log "Starting: $Description"
    try {
        & $ScriptBlock
        Write-Log "Completed: $Description"
    }
    catch {
        Write-Log "Failed: $Description - $($_.Exception.Message)" 'ERROR'
    }
}

function Show-Section {
    param([string]$Title)
    Write-Host "`n=== $Title ===" -ForegroundColor Cyan
}

$methods = @(
    [pscustomobject]@{
        Id = 1
        Name = 'Disable Individual Defender Features (Set-MpPreference)'
        Description = 'Disable active protection components while keeping the service mostly passive.'
        Risks = 'Windows updates may re-enable features; Defender remains installed and may reactivate.'
        Recommendations = 'Create a scheduled task to reapply on boot; export configuration for quick restore; combine with Method 4 for persistence.'
        Persistence = 'Reapply after updates or on startup to keep preferences enforced.'
        Commands = @(
            { Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue },
            { Set-MpPreference -DisableIOAVProtection $true -ErrorAction SilentlyContinue },
            { Set-MpPreference -DisableBehaviorMonitoring $true -ErrorAction SilentlyContinue },
            { Set-MpPreference -DisableScanningNetworkFiles $true -ErrorAction SilentlyContinue },
            { Set-MpPreference -DisableArchiveScanning $true -ErrorAction SilentlyContinue },
            { Set-MpPreference -DisableBlockAtFirstSeen $true -ErrorAction SilentlyContinue },
            { Set-MpPreference -DisableAutoExclusions $true -ErrorAction SilentlyContinue },
            { Set-MpPreference -MAPSReporting Disabled -ErrorAction SilentlyContinue },
            { Set-MpPreference -SubmitSamplesConsent NeverSend -ErrorAction SilentlyContinue }
        )
    }
    [pscustomobject]@{
        Id = 2
        Name = 'Stop Defender Services'
        Description = 'Force stop core Defender services (WinDefend, WdNisSvc, Sense).'
        Risks = 'Services may auto-restart or refuse to stop; Security Center warnings may appear.'
        Recommendations = 'Consider disabling startup type; schedule the stop at logon for reapplication; pair with Method 1.'
        Persistence = 'Apply at every logon or set startup type to Disabled for temporary sessions.'
        Commands = @(
            { Stop-Service WinDefend -Force -ErrorAction SilentlyContinue },
            { Stop-Service WdNisSvc -Force -ErrorAction SilentlyContinue },
            { Stop-Service Sense -Force -ErrorAction SilentlyContinue },
            { Set-Service WinDefend -StartupType Disabled -ErrorAction SilentlyContinue },
            { Set-Service WdNisSvc -StartupType Disabled -ErrorAction SilentlyContinue },
            { Set-Service Sense -StartupType Disabled -ErrorAction SilentlyContinue }
        )
    }
    [pscustomobject]@{
        Id = 3
        Name = 'Disable Defender via Group Policy (Policies Registry)'
        Description = 'Use policy registry keys to signal Windows to disable Defender officially.'
        Risks = 'Windows Home may ignore keys; updates or domain policies can override settings.'
        Recommendations = 'Reapply after updates; use Local Group Policy Editor for reinforcement; prefer on Pro/Enterprise.'
        Persistence = 'Import .reg backups or schedule reapplication to maintain policies.'
        Commands = @(
            { New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Force | Out-Null },
            { Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Name "DisableAntiSpyware" -Value 1 -Type DWord },
            { New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" -Force | Out-Null },
            { Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" -Name "DisableRealtimeMonitoring" -Value 1 -Type DWord },
            { Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" -Name "DisableIOAVProtection" -Value 1 -Type DWord },
            { Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" -Name "DisableOnAccessProtection" -Value 1 -Type DWord },
            { Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" -Name "DisableBehaviorMonitoring" -Value 1 -Type DWord }
        )
    }
    [pscustomobject]@{
        Id = 4
        Name = 'Low-Level Defender Disable via System Registry'
        Description = 'Forcefully tampers with core Defender registry values for deeper suppression.'
        Risks = 'Security Center warnings may persist; keys can reset after major updates; may conflict with security baselines.'
        Recommendations = 'Combine with Method 1; automate at startup for persistence; consider muting Security Center notifications if needed.'
        Persistence = 'Use startup scripts or scheduled tasks to reapply low-level keys after updates.'
        Commands = @(
            { New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Services\WinDefend" -Force | Out-Null },
            { Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\WinDefend" -Name "Start" -Value 4 -Type DWord },
            { New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Services\WdNisSvc" -Force | Out-Null },
            { Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\WdNisSvc" -Name "Start" -Value 4 -Type DWord },
            { New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Sense" -Force | Out-Null },
            { Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Sense" -Name "Start" -Value 4 -Type DWord }
        )
    }
    [pscustomobject]@{
        Id = 5
        Name = 'Disable AMSI (Anti-Malware Script Interface)'
        Description = 'Disable AMSI to prevent script scanning (PowerShell, JS/VBS, Python, partial .NET).'
        Risks = 'Reduced script execution security; enterprise policies may object; dependent applications may warn.'
        Recommendations = 'Use in isolated/dev environments; combine with script signing; enable only when necessary.'
        Persistence = 'Reapply after security updates; keep backup of original AMSI key for restoration.'
        Commands = @(
            { New-Item -Path "HKLM:\SOFTWARE\Microsoft\AMSI" -Force | Out-Null },
            { Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\AMSI" -Name "EnableAmsi" -Value 0 -Type DWord }
        )
    }
)

function Show-MethodDetails {
    param([pscustomobject]$Method)
    Show-Section $Method.Name
    Write-Host "Description: $($Method.Description)" -ForegroundColor White
    Write-Host "Risks: $($Method.Risks)" -ForegroundColor Yellow
    Write-Host "Recommendations: $($Method.Recommendations)" -ForegroundColor White
    Write-Host "Persistence/Reapply Notes: $($Method.Persistence)" -ForegroundColor White
}

function Invoke-Method {
    param([pscustomobject]$Method)
    Show-MethodDetails -Method $Method
    if (-not (Confirm-Action -Prompt "Apply '$($Method.Name)'?")) {
        Write-Log "Skipped: $($Method.Name)" 'WARN'
        return
    }
    foreach ($cmd in $Method.Commands) {
        Invoke-CommandSafe -ScriptBlock $cmd -Description $cmd.ToString()
    }
    Write-Log "Completed method: $($Method.Name)"
}

function Show-Menu {
    Show-Section 'Windows Defender Killer'
    Write-Host "Select a method to apply:" -ForegroundColor White
    foreach ($method in $methods) {
        Write-Host "[$($method.Id)] $($method.Name)" -ForegroundColor Green
    }
    Write-Host "[Q] Quit" -ForegroundColor Red
}

Write-Log "Script started"
while ($true) {
    Show-Menu
    $choice = Read-Host "Enter selection"
    if ($choice -match '^[Qq]$') {
        break
    }
    $selected = $methods | Where-Object { $_.Id -eq [int]$choice }
    if ($null -eq $selected) {
        Write-Log "Invalid selection: $choice" 'WARN'
        continue
    }
    Invoke-Method -Method $selected
}
Write-Log "Script ended"
