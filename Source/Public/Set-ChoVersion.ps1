filter Set-ChoVersion {
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = "Many")]
    param(
        [Parameter(ParameterSetName = "One", Mandatory, ValueFromPipelineByPropertyName)]
        [string]$Package,

        [Parameter(ParameterSetName = "One", ValueFromPipelineByPropertyName)]
        [string]$Version,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string[]]$Application,

        [switch]$SetForUserExperimental
    )
    Import-ParameterConfiguration

    if (-not $Package -and $Application) {
        $Application -replace "[ \|=]", "," |
            ConvertFrom-Csv -Header Package, Version, Application |
            Set-ChoVersion -SetForUserExperimental:$SetForUserExperimental
        return
    }
    $null = $PSBoundParameters.Remove("SetForUserExperimental")
    Write-Verbose "Setting choco package '$Package'$(if($Version){ " version $Version" })$(if($Application){ " application $Application" })"

    if (!(($ChoPackage = Get-ChoVersion @PSBoundParameters -ErrorAction Ignore))) {
        if ($Version) {
            choco install -y $package --version $Version --sxs
        } else {
            choco install -y $package --sxs
        }
        $ChoPackage = Get-ChoVersion @PSBoundParameters -ErrorAction Stop
    }

    $ExecutablePath = Get-Command $Package | Convert-Path
    if ($ExecutablePath -eq $ChoPackage.Path) {
        # nothing to do, it's already the default
        return
    }
    $ChoPackage | Add-ToolPath -SetForUserExperimental:$SetForUserExperimental
}