# ChoVersion
### The Chocolatey Version Picker

## Install

Install it from the PowerShell gallery:

```PowerShell
Install-Module ChoVersion
```

## Usage

The simplest form is to specify each executable package you need to configure, like this:

```PowerShell
Set-ChoVersion terraform 0.14.9
Set-ChoVersion terragrunt 0.28.18
```

For a configuration-based approach, see the documentation of [ChoVersion.psd1](#supports-a-choversionpsd1-configuration) below.

## About ChoVersion

ChoVersion is a PowerShell module for switching between versions of command-line tools. The name is deliberately abiguously short for "Choco Version" or "Choose Version" and when people hear "Set-ChoVersion" it should sound like "set yo' version". Our unofficial mascot is [Cho'gath, the terror of the void](https://na.leagueoflegends.com/en-us/champions/cho-gath/).

It currently accomplishes switching apps simply: by prepending the path to the specific version on your environment PATH variable. Note that it does this in such away that it works locally on the PowerShell session you're in, but should also affect the rest of the build pipeline in Azure DevOps Pipelines and GitHub Actions..

It currently depends on using [chocolatey](https://chocolatey.org) as the installer, installing multiple versions of tools side-by-side, and then letting you pick one to use by changing which one is currently in your path. This makes it Windows only, but means that it will work out of the box on [Microsoft's hosted agents](https://github.com/actions/virtual-environments/blob/main/images/win/Windows2019-Readme.md). As long as you run it with sufficient rights, it can install missing tools for you -- although it does not yet use the agent's "tools" folder to install or cache the tools.

It also offers an experimental switch to change your current user's environment PATH permanently, so you can use it to switch between versions on your local box in a way that affects all new processes (but no existing processes except the current PowerShell session).

### Regarding build

Since I've only spent a few hours over the weekend on this, and I mostly wanted to proove it could work, there are not many tests, so the CI build may be failing, but the .\build.ps1 script is working, and the tests that are there pass.

## Supports a `ChoVersion.psd1` configuration

To quickly specify dependency versions, you can add a `ChoVersion.psd1` configuration file to any folder. For instance, if you add this ChoVersion.psd1:

```PowerShell
@{
ChocolateyPackages = @(
    @{
        Package = "bicep"
        Version = "0.4.1008"
    }
    @{
        Executable = "gitversion"
        Package = "gitversion.portable"
        Version = "5.8.1"
    }
)
}
```

Then simply running `Set-ChoVersion` in that folder will (install and) switch to the specified version of terraform and terragrunt -- assuming they're available in your chocolatey lib folder (or your chocolatey sources).

Of course, if you're building the array in a script, you can pass it directly to the ChocolateyPackages parameter:

```PowerShell
Set-ChoVersion -ChocolateyPackages @(
    @{
        Package = "terraform"
        Version = "0.14.9"
    }
    @{
        Package = "terragrunt"
        Version = "0.28.18"
    }
)
```

## TODO:

1. Support using a version range, like Install-RequiredModule does.
2. Support using a shim/symlink to support **permanent** switching. This could work the way chocolatey's install works, by switching out the shims that chocolatey generates for ones which point at the specified version. Honestly, if chocolatey just did this itself, I wouldn't have needed to write this module.
3. Make installed tools go to the agent tools cache on build systems

### But probably not:

2. Provide a configurable way to provide installers for missing tools without explicitly relying on choco so this can function cross-platform (would need to use an existing install system, like apt-get or homebrew, because I'm not trying to handle arbitrary installs)
