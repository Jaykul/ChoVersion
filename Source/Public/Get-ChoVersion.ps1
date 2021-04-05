filter Get-ChoVersion {
    [CmdletBinding()]
    param(
        # The name of the chocolatey package
        [Parameter(ValueFromPipelineByPropertyName, Mandatory, Position = 0)]
        [string]$Package,

        # The version of the chocolatey package
        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$Version,

        # The base name of the executable (without the .exe), like "terraform"
        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$Executable = "*",

        # If set, lists all versions available.
        # Otherwise, Get-ChoVersion only returns the specified or newest version
        [switch]$ListAvailable
    )
    if (!$Executable) {
        $Executable = "*"
    }
    $Pattern = $Package -replace "[-\.]", "|"
    $ChildParam = @{
        Filter = "$Executable.exe"
        Recurse = $true
        OutVariable = "App"
    }

    $ChocoApplications = if ($Version) {
        choco list --by-id-only $Package --version $Version --localonly -allversions --limitoutput --includeprograms |
            ConvertFrom-Csv -Delimiter "|" -Header Package, Version
    } else {
        choco list --by-id-only $Package --localonly -allversions --limitoutput --includeprograms |
            ConvertFrom-Csv -Delimiter "|" -Header Package, Version
    }

    if (!$ChocoApplications) {
        Write-Error "Choco package '$Package'$(if($Version){ " version $Version" }) not found!"
        return
    }

    if ($ChocoApplications.Count -gt 1) {
        # On Windows PowerShell, there's no built-in [semver] type accelerator
        if (-not ('semver' -as [type])) {
            Import-Module PackageManagement -Scope Global
            $xlr8r = [psobject].assembly.gettype("System.Management.Automation.TypeAccelerators")
            $xlr8r::Add('semver', [Microsoft.PackageManagement.Provider.Utility.SemanticVersion])
        }
        $ChocoApplications = $ChocoApplications | Sort-Object { [semver]$_.Version } -Descending

        if (!$ListAvailable) {
            $ChocoApplications = $ChocoApplications[0]
        }
    }

    @($ChocoApplications).ForEach{
        Add-Member -InputObject $_ -Passthru -NotePropertyName Path -NotePropertyValue $(
            if (Test-Path "$Env:ChocolateyInstall\lib\$($_.Package).$($_.Version)") {
                $ChildParam["Path"] = "$Env:ChocolateyInstall\lib\$($_.Package).$($_.Version)"
            } elseif (Test-Path $Env:ChocolateyInstall\lib\$($_.Package)) {
                $ChildParam["Path"] = "$Env:ChocolateyInstall\lib\$($_.Package)"
            }

            Get-ChildItem @ChildParam | Convert-Path | Where-Object {
                # we can try matching based on the package name
                $Executable -ne "*" -or $_ -match $Pattern
            } | Select-Object -Unique -First 1
        )
    }
}