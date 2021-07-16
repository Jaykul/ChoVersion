filter Set-ChoVersion {
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = "Chocolatey", ConfirmImpact = "Medium")]
    param(
        # The name of the chocolatey package
        [Parameter(ParameterSetName = "One", Mandatory, ValueFromPipelineByPropertyName, Position = 0)]
        [string]$Package,

        # The version of the chocolatey package
        [Parameter(ParameterSetName = "One", ValueFromPipelineByPropertyName, Position = 1)]
        [string]$Version,

        # The base name of the executable (without the .exe), like "terraform"
        [Parameter(ParameterSetName = "One", ValueFromPipelineByPropertyName)]
        [string]$Executable,

        # Supports a table syntax for specifying multiple applications at once:
        # PackageName|Version
        # or even:
        # PackageName|Version|ExecutableBaseName
        #
        # For example:
        # "terraform|0.14.9"
        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = "Chocolatey")]
        [string[]]$Chocolatey,

        # If set, makes the change permanent for the current user by modifying their PATH at user scope
        [switch]$SetForUserExperimental
    )
    if ($PSCmdlet.ParameterSetName -eq 'Chocolatey') {
        if (-not $Chocolatey) {
            # Only import default parameters if we actually need them
            Import-ParameterConfiguration
        }
        if ($Chocolatey) {
            $Chocolatey -replace "[ \|=]", "," |
                ConvertFrom-Csv -Header Package, Version, Executable |
                Set-ChoVersion -SetForUserExperimental:$SetForUserExperimental
            return
        }
    }
    
    $null = $PSBoundParameters.Remove("SetForUserExperimental")
    $null = $PSBoundParameters.Remove("Confirm")
    Write-Verbose "Setting choco package '$Package'$(if($Version){ " version $Version" })$(if($Executable){ " for executable $Executable" })"

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

    if ($PSCmdlet.ShouldProcess("Use $($ChoPackage.Package) v$($ChoPackage.Version)", "Prepend PATH for '$($ChoPackage.Path)'")) {
        $ChoPackage | Add-ToolPath -SetForUserExperimental:$SetForUserExperimental
    }
}
