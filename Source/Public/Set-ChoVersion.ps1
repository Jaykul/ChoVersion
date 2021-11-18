filter Set-ChoVersion {
    <#
        .SYNOPSIS
            Set which version of a chocolatey tool package should be used.
        .DESCRIPTION
            Set-ChoVersion changes your PATH environment variable to include the
            Chocolatey lib folder for the specified version of the package.

            If it's not already installed, it will be installed.
        .EXAMPLE
            Set-ChoVersion terraform

            Ensures that terraform is available on the PATH without worrying about the version
        .EXAMPLE
            Set-ChoVersion gitversion.portable 5.8.1

            Ensures that gitversion version 5.8.1 is available on the PATH
            Set-Choversion will assume that the executable is named "gitversion" because it knows about ".portable" and ".install" package conventions
        .Example
            Set-ChoVersion @{ Package = "terraform"; Version = "1.0.1" },
                           @{ Package = "bicep"; Version = "0.4.6" }

            Switches to terraform 1.0.1 and bicep 0.4.6
        .Example
            Set-Content ChoVersion.psd1 @"
            @{ ChocolateyPackages = @(
                @{
                    Package = "gitversion.portable"
                    Executable = "gitversion"
                    Version = "5.8.1"
                }
                )
            }
            "@
            Set-ChoVersion

            Shows how a psd1 file can be used in a project repository to support installing tool dependencies and using specific versions of tools.
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
        [string]$Executable = ($Package -replace "\.portable$|\.install$"),

        # An array of hashtables specifying multiple applications to set or install
        # This parameter is intended to support configuration via a ChoVersion.psd1 file like:
        # @{ChocolateyPackages = @(@{ Package = "terraform"; Version = "1.0.0" })}
        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = "Chocolatey", Position = 0)]
        [hashtable[]]$ChocolateyPackages,

        # If set, makes the change permanent for the current user by modifying their PATH at user scope
        [Alias("Permanent")]
        [switch]$SetForUserExperimental
    )
    # Set executable from Package if it's piped in empty
    if (!$Executable -and $Package) {
        $Executable = $Package -replace ".+\.portable$|.+\.install$"
    }
    # There's got to be an easier way to show *all* parameter values (including defaults)
    if ($DebugPreference -eq "Continue") {
        $Parameters = @($PSCmdlet.MyInvocation.MyCommand.Parameters.Keys)
        Write-Debug (@(
            $MyInvocation.MyCommand.Name
            $((Get-Variable -Name $Parameters -Scope Local -ErrorAction SilentlyContinue).
                Where({$_.Value}).
                ForEach({ "-" + $_.Name, $_.Value})
            )
            "$([char]27)[90m# ParameterSet:"
            $PSCmdlet.ParameterSetName
            "$([char]27)[0m"
        ) -join " ")
    }
    if ($PSCmdlet.ParameterSetName -eq 'Chocolatey') {
        if (-not $ChocolateyPackages) {
            # Only import default parameters if we actually need them
            Import-ParameterConfiguration
        }
        if ($ChocolateyPackages) {
            $Packages = $ChocolateyPackages.ForEach{ [PSCustomObject]$_ }
            Write-Verbose "Installing multiple ChocolateyPackages: $($Packages | Format-Table -Auto | Out-String)"
            $Packages | Set-ChoVersion -SetForUserExperimental:$SetForUserExperimental
            return
        } else {
            Write-Warning "No ChocolateyPackages specified"
            return
        }
    }

    $null = $PSBoundParameters.Remove("SetForUserExperimental")
    $null = $PSBoundParameters.Remove("Confirm")
    Write-Verbose "Setting choco package '$Package'$(if($Version){ " version $Version" })$(if($Executable){ " for $Executable" })"

    if (!(($ChoPackage = Get-ChoVersion @PSBoundParameters -ErrorAction SilentlyContinue))) {
        if ($Version) {
            choco install -y $Package --version $Version --sxs
        } else {
            choco install -y $Package --sxs
        }
        $ChoPackage = Get-ChoVersion @PSBoundParameters -ErrorAction Stop
    }

    $ExecutablePath = Get-Command $Executable -ErrorAction SilentlyContinue | Convert-Path
    if ($ExecutablePath -eq $ChoPackage.Path) {
        # nothing to do, it's already the default
        return
    }

    if ($PSCmdlet.ShouldProcess("Use $($ChoPackage.Package) v$($ChoPackage.Version)", "Prepend PATH for '$($ChoPackage.Path)'")) {
        $ChoPackage | Add-ToolPath -SetForUserExperimental:$SetForUserExperimental
    }
}
