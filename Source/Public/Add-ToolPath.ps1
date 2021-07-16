filter Add-ToolPath {
    <#
        .SYNOPSIS
            Prepend a path to the PATH environment variable, with support for Github Actions and Azure Pipelines
    #>
    [CmdletBinding()]
    param(
        # The path to prepend to the PATH environment variable
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, Position = 0)]
        [ValidateScript({ Test-Path $_ })]
        [string]$Path,

        # If set, and on Windows, update the user's PATH
        [switch]$SetForUserExperimental
    )

    # If they pass the path to a file, we'll look at the folder
    if (Test-Path $Path -PathType Leaf) {
        $Path = Split-Path $Path
    }

    $ChocoLib = "$Env:ChocolateyInstall\lib\"
    if ($Path.ToLowerInvariant().StartsWith($ChocoLib.ToLowerInvariant())) {
        $RemovablePaths = $Path -replace "[\d\.]+$"
    }

    ## ShimGen is a whole different option
    # if ($ExecutablePath.ToLowerInvariant().StartsWith()) {
    #     try {
    #         if ((Get-FileHash $ExecutablePath) -eq $Shim.Hash) {
    #             Set-Content ([IO.Path]::ChangeExtension($ExecutablePath,".shim")) "path = $($ChoPackage.Path)"
    #         }
    #         Copy-Item $Shim $ExecutablePath -Force
    #     } catch [UnauthorizedAccessException] {
    #         Write-Warning "Elevating to overwrite the chocolatey shim at: $ExecutablePath"
    #         $pwsh = Get-Command PowerShell, pwsh -ErrorAction Ignore | Select-Object -First 1
    #         Start-Process $pwsh.Name -Verb RunAs -ArgumentList "-Command", "Copy-Item", $Shim, $ExecutablePath
    #     }
    # } else {
    #     Write-Warning "The default '$Name' command was not a chocolatey copy: $ExecutablePath"
    # }

    # On Windows, we can prepend the path in the user environment to make it sticky
    if ($SetForUser -and (-not (Test-Path Variable:IsWindows) -or $IsWindows)) {

        [string[]]$EnvPath = [System.Environment]::GetEnvironmentVariable("PATH", "User").Split([IO.Path]::PathSeparator).Where{
            $_ -ine $Path
        }

        # we might want to remove any previous copies of this from the path
        if ($Path.ToLowerInvariant().StartsWith($ChocoLib.ToLowerInvariant())) {
            $ChocoLib = $Path.Substring(0, $ChocoLib.Length)
            $Name, $Folder = $Path.Substring($ChocoLib.Length) -split "(?=[\\/])", 2
            $Pattern = $Name -replace "\.[\d\.]+$", "\.[\d\.]+"
            $RemovablePaths = [regex]::Escape($ChocoLib) + $Pattern + [regex]::Escape($Folder)
            $EnvPath = $EnvPath -notmatch $RemovablePaths
        }

        [string]$EnvPath = @(@($Path) + $EnvPath) -join [IO.Path]::PathSeparator
        Write-Verbose "Set User PATH: $ENVPATH"
        [System.Environment]::SetEnvironmentVariable("PATH", $EnvPath, "User")
    }

    ## Prepend the path in the current session
    Write-Verbose "Prepending '$Path' to PATH"
    $ENV:PATH = $Path + [IO.Path]::PathSeparator + $Env:PATH

    if (Test-Path ENV:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI) {
        ## Prepend the path in Azure DevOps:
        Write-Host "##vso[task.prependpath]$Path"
    }
    if (Test-Path Env:GITHUB_PATH) {
        ## Prepend the path in Github Actions:
        Add-Content $Env:GITHUB_PATH $Path -Encoding UTF8
    }
}