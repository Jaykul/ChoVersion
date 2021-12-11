@{

# Script module or binary module file associated with this manifest.
ModuleToProcess = 'ChoVersion.psm1'

# Version number of this module.
ModuleVersion = '1.0.3'

# ID used to uniquely identify this module
GUID = '60fc0027-8325-4fd5-8109-7d86cc123193'

# Author of this module
Author = @('Joel Bennett')

# Company or vendor of this module
CompanyName = 'PoshCode.org'

# Copyright statement for this module
Copyright = 'Copyright (c) 2021 by Joel Bennett, all rights reserved.'

# Description of the functionality provided by this module
Description = 'A module for switching between multiple versions of command-line tools'

RequiredModules = @(
    @{ ModuleName='Configuration'; ModuleVersion='1.5.0' }
)

# Exports - populated by the build
FunctionsToExport = @('*')
CmdletsToExport = @()
VariablesToExport = @()
AliasesToExport = @()

# List of all files packaged with this module
FileList = @()

PrivateData = @{

    # PSData is module packaging and gallery metadata embedded in PrivateData
    # It's for the PoshCode and PowerShellGet modules
    # We had to do this because it's the only place we're allowed to extend the manifest
    # https://connect.microsoft.com/PowerShell/feedback/details/421837
    PSData = @{
        # The semver pre-release version information
        PreRelease = ''

        # Release notes for this particular version of the module
        ReleaseNotes = '
        Fixed a bug using Set-ChoVersion with packages with names that did not match the executable
        '

        # Keyword tags to help users find this module via navigations and search.
        Tags = @('Chocolatey','Version','Install')

        # The web address of this module's project or support homepage.
        ProjectUri = "https://github.com/Jaykul/ChoVersion"

        # The web address of this module's license. Points to a page that's embeddable and linkable.
        LicenseUri = "http://opensource.org/licenses/MIT"
    }
}

}


