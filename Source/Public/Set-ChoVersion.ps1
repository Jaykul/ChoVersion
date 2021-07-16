filter Set-ChoVersion {
    <#
        .SYNOPSIS
            Set which version of a chocolatey tool package should be used.
        .EXAMPLE
            Set-ChoVersion terraform 0.13.2

            Switches to terraform version 0.13.2
        .Example
            Set-ChoVersion @{ Package = "terraform"; Version = "1.0.1" },
                           @{ Package = "bicep"; Version = "0.4.6" }

            Switches to terraform 1.0.1 and bicep 0.4.6
        .Example
            Set-Content ChoVersion.psd1 @"
            @{ ChocolateyPackages = @(
                @{ Package = "terraform"; Version = "1.0.1" }
                @{ Package = "bicep"; Version = "0.4.6" }
                )
            }
            "@
            Set-ChoVersion

            Shows how a psd1 file can be used in a project repository to support installing tool dependencies and using specific versions of tools
    #>
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

        # An array of hashtables specifying multiple applications to set or install
        # This parameter is intended to support configuration via a ChoVersion.psd1 file like:
        # @{ChocolateyPackages = @(@{ Package = "terraform"; Version = "1.0.0" })}
        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = "Chocolatey", Position = 0)]
        [hashtable[]]$ChocolateyPackages,

        # If set, makes the change permanent for the current user by modifying their PATH at user scope
        [switch]$SetForUserExperimental
    )
    Write-Verbose $PSCmdlet.ParameterSetName
    if ($PSCmdlet.ParameterSetName -eq 'Chocolatey') {
        if (-not $ChocolateyPackages) {
            # Only import default parameters if we actually need them
            Import-ParameterConfiguration
        }
        if ($ChocolateyPackages) {
            Write-Verbose "Installing multiple ChocolateyPackages: "
            $Packages = $ChocolateyPackages.ForEach{ [PSCustomObject]$_ }
            Write-Verbose $($Packages | Format-Table -Auto | Out-String)
            $Packages | Set-ChoVersion -SetForUserExperimental:$SetForUserExperimental
            return
        } else {
            Write-Warning "No ChocolateyPackages specified"
            return
        }
    }

    $null = $PSBoundParameters.Remove("SetForUserExperimental")
    $null = $PSBoundParameters.Remove("Confirm")
    Write-Verbose "Setting choco package '$Package'$(if($Version){ " version $Version" })$(if($Executable){ " for executable $Executable" })"

    if (!(($ChoPackage = Get-ChoVersion @PSBoundParameters -ErrorAction Ignore))) {
        if ($Version) {
            choco install -y $Package --version $Version --sxs
        } else {
            choco install -y $Package --sxs
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
