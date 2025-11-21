# Microsoft Defender Killer Specification

This specification is intended for use by a coding agent, such as Codex, Copilot, etc. Follow the specification to generate a complete project.

This specification provides instructions on generating a script that allows the user to disable Microsoft Defender in Windows 11. Upon script launch, the user should be presented with a menu of five disabling methods — each containing:

* Description
* Potential problems / risks
* Recommendations for usage
* PowerShell code example

The five supported methods are:

1. Disable Individual Defender Features (Set-MpPreference)
2. Stop Defender Services
3. Disable Defender via Group Policy (Registry: Policies)
4. Low-Level Defender Disable via System Registry
5. Disable AMSI (Anti-Malware Script Interface)

---

## 💀 Method 1: Disable Individual Defender Features (Set-MpPreference)

### Description

This method disables the **active protection mechanisms** of Microsoft Defender without disabling the service fully.

Disabled components:

* Real-time protection
* File operation interception
* Behavior monitoring
* Cloud-based protection
* Archive scanning
* Network scanning

### Effect

Defender becomes mostly passive and stops impacting system performance, especially disk I/O.

### Risks

* Windows updates may re-enable some functions.

### Mitigation

* Create a scheduled task that reapplies settings on boot.
* Export current config and reapply after major Windows updates.
* Bundle this method with Method 4 for higher persistence.

### Recommended Use

* Ideal for reducing NVMe/SSD slowdowns.
* Low risk.

### PowerShell Example

```powershell
Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue
Set-MpPreference -DisableIOAVProtection $true -ErrorAction SilentlyContinue
Set-MpPreference -DisableBehaviorMonitoring $true -ErrorAction SilentlyContinue
Set-MpPreference -DisableScanningNetworkFiles $true -ErrorAction SilentlyContinue
Set-MpPreference -DisableArchiveScanning $true -ErrorAction SilentlyContinue
Set-MpPreference -DisableBlockAtFirstSeen $true -ErrorAction SilentlyContinue
Set-MpPreference -DisableAutoExclusions $true -ErrorAction SilentlyContinue
Set-MpPreference -MAPSReporting Disabled -ErrorAction SilentlyContinue
Set-MpPreference -SubmitSamplesConsent NeverSend -ErrorAction SilentlyContinue
```

---

## 🪓 Method 2: Stop Defender Services

### Description

Stops core Defender services:

* `WinDefend`
* `WdNisSvc`
* `Sense`

### Effect

Temporarily disables Defender until next reboot.

### Risks

* Services may refuse to stop.
* Windows may restart them automatically.
* Security Center may show warnings.

### Mitigation

* Use `Set-Service -StartupType Disabled` to prevent auto-restart.
* Apply service-stop script via Scheduled Task triggered at logon.
* Combine with Method 1 for fallback protection suppression.

### Recommended Use

* Good for temporary (single-session) disabling.

### PowerShell Example

```powershell
Stop-Service WinDefend -Force -ErrorAction SilentlyContinue
Stop-Service WdNisSvc -Force -ErrorAction SilentlyContinue
Stop-Service Sense -Force -ErrorAction SilentlyContinue
```

---

## 🧱 Method 3: Disable Defender via Group Policy (Registry: Policies)

### Description

Configures Group Policy registry keys to officially signal Windows to disable Defender.

### Effect

A clean, system-recognized method for Pro/Enterprise editions.

### Risks

* Windows Home may ignore these keys.
* Updates may reset policies.
* Conflicts with domain GPOs may occur.

### Mitigation

* Deploy the same keys via Local Group Policy Editor to strengthen persistence.
* Export `.reg` backup and reapply after Windows updates.
* For Windows Home, use Method 4 instead.

### Recommended Use

* Pro/Enterprise systems.
* When stability and system recognition matter.

### PowerShell Example

```powershell
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Name "DisableAntiSpyware" -Value 1 -Type DWord

New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" -Name "DisableRealtimeMonitoring" -Value 1 -Type DWord
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" -Name "DisableIOAVProtection" -Value 1 -Type DWord
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" -Name "DisableOnAccessProtection" -Value 1 -Type DWord
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" -Name "DisableBehaviorMonitoring" -Value 1 -Type DWord
```

---

## 🔥 Method 4: Low-Level Defender Disable via System Registry

### Description

Forcibly disables core Defender components using deep registry keys.

### Effect

Significantly reduces Defender functionality.

### Risks

* Windows Security Center may display warnings.
* Keys may reset after major updates.
* May conflict with certain security baselines.

### Mitigation

* Combine with Method 1 for stronger enforcement.
* Use a startup script to reapply registry values automatically.
* Disable Windows Security Center notifications via registry if necessary.

### Recommended Use

* When maximum suppression is required.
* Best combined with Method 1.

### PowerShell Example

```powershell
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Name "DisableAntiSpyware" -Value 1 -Type DWord

New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" -Name "DisableRealtimeMonitoring" -Value 1 -Type DWord
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" -Name "DisableOnAccessProtection" -Value 1 -Type DWord
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" -Name "DisableBehaviorMonitoring" -Value 1 -Type DWord
```

---

## 🪤 Method 5: Disable AMSI (Anti-Malware Script Interface)

### Description

Disables AMSI, preventing Defender from scanning scripts:

* PowerShell
* JS / VBS
* Python
* Partial .NET scripts

### Effect

Greatly speeds up script execution; prevents Defender from analyzing executed code.

### Risks

* Reduces script execution security.
* Enterprise policies may object.
* Certain applications depending on AMSI may show warnings.

### Mitigation

* Use this method only in isolated/dev environments.
* Combine with script signing to reduce security exposure.
* Limit the scope by enabling AMSI only for specific tasks when needed.

### Recommended Use

* Developers
* Heavy PowerShell/Python automation users
* Users suffering from script execution lag

### PowerShell Example

```powershell
New-Item -Path "HKLM:\SOFTWARE\Microsoft\AMSI" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\AMSI" -Name "EnableAmsi" -Value 0 -Type DWord
```

---

# End of Specification
