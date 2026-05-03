#Requires -RunAsAdministrator
<#
.SYNOPSIS
    REDMI Book battery charge limit control.
.EXAMPLE
    .\RedmiBookChargeLimit.ps1 -Action Status
    .\RedmiBookChargeLimit.ps1 -Action Set -Limit 40
    .\RedmiBookChargeLimit.ps1 -Action Set -Limit 80
    .\RedmiBookChargeLimit.ps1 -Action Set -Limit 100
#>
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("Set", "Status")]
    [string]$Action,

    [ValidateSet(40, 50, 60, 70, 80, 100)]
    [int]$Limit
)

if ($Action -eq "Set" -and -not $Limit) {
    Write-Error "Action 'Set' requires -Limit (40, 50, 60, 70, 80 or 100)."
    exit 1
}

$Namespace = "ROOT\WMI"
$ClassName = "MiCommonInterface"
$MethodName = "MiInterface"

$LimitTable = @{
    100 = 0x00
    80  = 0x01
    70  = 0x05
    60  = 0x06
    50  = 0x07
    40  = 0x08
}

function Invoke-MiCommand {
    param([byte[]]$InData)

    $instance = Get-CimInstance -Namespace $Namespace -ClassName $ClassName -ErrorAction Stop |
                Select-Object -First 1

    if (-not $instance) {
        throw "Class $ClassName not found. This script only works on Xiaomi/Redmi laptops."
    }

    $data = [byte[]]::new(32)
    [Array]::Copy($InData, $data, [Math]::Min($InData.Length, 32))

    return Invoke-CimMethod -InputObject $instance -MethodName $MethodName -Arguments @{ InData = $data }
}

function Get-ChargeLimit {
    $result = Invoke-MiCommand -InData @(0x00, 0xFA, 0x00, 0x10, 0x02, 0x00, 0x00, 0x00)
    if ($result.OutData -and $result.OutData.Length -gt 6) {
        $val = $result.OutData[6]
        $percent = $LimitTable.GetEnumerator() | Where-Object { $_.Value -eq $val } | Select-Object -ExpandProperty Key
        if ($percent) { return "${percent}%" } else { return "unknown (0x{0:X2})" -f $val }
    }
    return $null
}

function Set-ChargeLimit {
    param([byte]$LimitValue)

    Invoke-MiCommand -InData @(0x00, 0xFB, 0x00, 0x10, 0x02, 0x00, $LimitValue, 0x00) | Out-Null

    if ($LimitValue -eq 0x00) {
        Invoke-MiCommand -InData @(0x00, 0xFB, 0x00, 0x10, 0x02, 0x00, 0x00, 0x00) | Out-Null
    } else {
        Invoke-MiCommand -InData @(0x00, 0xFA, 0x00, 0x10, 0x02, 0x00, 0x00, 0x00) | Out-Null
        Invoke-MiCommand -InData @(0x00, 0xFA, 0x00, 0x10, 0x02, 0x00, 0x00, 0x00) | Out-Null
    }
}

try {
    switch ($Action) {
        "Status" {
            $state = Get-ChargeLimit
            if ($null -eq $state) {
                Write-Host "Failed to get charge limit status."
            } else {
                Write-Host "Charge limit: $state"
            }
        }
        "Set" {
            $hexVal = [byte]$LimitTable[$Limit]
            Set-ChargeLimit -LimitValue $hexVal
            Write-Host "Charge limit set to $Limit%"
        }
    }
} catch {
    Write-Error "Error: $_"
    exit 1
}
