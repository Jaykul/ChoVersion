filter Get-ChoVersion {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipelineByPropertyName, Mandatory)]
        [string]$Package,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$Version,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$Application = "*"
    )
    if (!$Application) {
        $Application = "*"
    }
    $Pattern = $Package -replace "[-\.]", "|"
    $ChildParam = @{
        Filter = "$Application.exe"
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

    $ChocoApplications.ForEach{
        Add-Member -InputObject $_ -Passthru -NotePropertyName Path -NotePropertyValue $(
            if (Test-Path "$Env:ChocolateyInstall\lib\$($_.Package).$($_.Version)") {
                $ChildParam["Path"] = "$Env:ChocolateyInstall\lib\$($_.Package).$($_.Version)"
            } elseif (Test-Path $Env:ChocolateyInstall\lib\$($_.Package)) {
                $ChildParam["Path"] = "$Env:ChocolateyInstall\lib\$($_.Package)"
            }

            Get-ChildItem @ChildParam | Convert-Path | Where-Object {
                # we can try matching based on the package name
                $Application -ne "*" -or $_ -match $Pattern
            } | Select-Object -Unique -First 1
        )
    }
}