# Windows Defender Killer

Menu-driven PowerShell helper for applying five Microsoft Defender disabling methods (preferences, services, policy registry, low-level registry, and AMSI) as outlined in `AGENTS.md`.

## Quick remote launch
Run directly from a hosted raw URL with `Invoke-RestMethod` piped to `Invoke-Expression` (replace `<owner>` and branch if different):

```powershell
irm "https://raw.githubusercontent.com/<owner>/WindowsDefenderKiller/main/windows-defender-killer.ps1" | iex
```

Alternative PowerShell alias:

```powershell
iwr "https://raw.githubusercontent.com/<owner>/WindowsDefenderKiller/main/windows-defender-killer.ps1" | iex
```

> Tip: Enable TLS 1.2+ if your environment defaults lower:
>
> ```powershell
> [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
> irm "https://raw.githubusercontent.com/<owner>/WindowsDefenderKiller/main/windows-defender-killer.ps1" | iex
> ```

## Local usage
1. Download `windows-defender-killer.ps1`.
2. Open an elevated PowerShell session.
3. Run the script:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\windows-defender-killer.ps1
   ```
4. Choose a method from the menu; review the description, risks, and recommendations; confirm to apply.

## Notes and cautions
- Administrative rights are required for registry/service changes.
- Windows updates or policy refreshes can revert settings; reapply methods as needed.
- Expect Security Center warnings when Defender is disabled; re-enable protections when finished.
