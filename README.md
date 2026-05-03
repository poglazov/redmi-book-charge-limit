# REDMI Book Charge Limit

A PowerShell script for setting a battery charge limit on the **REDMI Book Pro 16 2025** running Windows 11.

May also work on other Xiaomi/Redmi laptops that use the `MiCommonInterface` WMI class.

## Requirements

- Windows 11
- PowerShell 5.1 or later
- Administrator privileges

## Usage

```powershell
# Check current limit
.\RedmiBookChargeLimit.ps1 -Action Status

# Set charge limit (value is a percentage)
.\RedmiBookChargeLimit.ps1 -Action Set -Limit 40
.\RedmiBookChargeLimit.ps1 -Action Set -Limit 50
.\RedmiBookChargeLimit.ps1 -Action Set -Limit 60
.\RedmiBookChargeLimit.ps1 -Action Set -Limit 70
.\RedmiBookChargeLimit.ps1 -Action Set -Limit 80

# Remove limit (charge to 100%)
.\RedmiBookChargeLimit.ps1 -Action Set -Limit 100
```

If script execution is blocked by execution policy, run with:

```powershell
powershell -ExecutionPolicy Bypass -File ".\RedmiBookChargeLimit.ps1" -Action Set -Limit 40
```

## Persist limit across reboots

By default, the charge limit is reset when the laptop restarts. To apply it automatically at every startup, create a scheduled task that runs the script as SYSTEM (no UAC prompt required).

Run the following in an administrator PowerShell, adjusting the path and limit as needed:

```powershell
$action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-ExecutionPolicy Bypass -File `"C:\ProgramData\RedmiBookChargeLimit\RedmiBookChargeLimit.ps1`" -Action Set -Limit 40"

$trigger = New-ScheduledTaskTrigger -AtStartup

$principal = New-ScheduledTaskPrincipal `
    -UserId "SYSTEM" `
    -LogonType ServiceAccount `
    -RunLevel Highest

Register-ScheduledTask `
    -TaskName "RedmiBookChargeLimit" `
    -Action $action `
    -Trigger $trigger `
    -Principal $principal
```

To remove the task:

```powershell
Unregister-ScheduledTask -TaskName "RedmiBookChargeLimit" -Confirm:$false
```

It is recommended to place the script in `C:\ProgramData\RedmiBookChargeLimit\` so the path is the same regardless of the current user.
