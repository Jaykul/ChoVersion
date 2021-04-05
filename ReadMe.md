# ChoVersion
### The Chocolatey Version Picker

## Install

I'm still not sure this is done, so you need to `-AllowPreRelease` in order to install it:

```PowerShell
Install-Module ChoVersion -AllowPrerelease
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

Since I've only spent a few hours over the weekend on this, and I mostly wanted to proove it could work, there are not yet tests, so the CI build is failing.

## Supports a `ChoVersion.psd1` configuration

To quickly specify dependency versions, you can add a `ChoVersion.psd1` configuration file to any folder. For instance, if you add this ChoVersion.psd1:

```PowerShell
@{
Chocolatey = @"
terraform|0.14.9
terragrunt|0.28.18
"@
}
```

Then simply running `Set-ChoVersion` in that folder will (install and) switch to the specified version of terraform and terragrunt -- assuming they're available in your chocolatey lib folder (or your chocolatey sources).

### I feel like I should apologize for the odd syntax of that file....

It's a default parameter file for the "Set-ChoVersion" command.

As such, it's setting "Chocolatey" parameter using the `PackageName|Version` syntax that chocolatey outputs when you ask for limited output, e.g. `choco list -lr` -- there's an optional third value "executable" you can provide which is the actual name of the executable (without the .exe extension), in case you need to use, for example, the "Terragruntt" package to install "terragrunt" ...

## TODO:

1. Support using a shim/symlink to support **permanent** switching. This could work the way chocolatey's install works, by switching out the shims that chocolatey generates for ones which point at the specified version. Honestly, if chocolatey just did this itself, I wouldn't have needed to write this module.
2. Make installed tools go to the agent tools cache when there is one
2. Provide a configurable way to provide installers for missing tools without explicitly relying on choco so this can function cross-platform (would need to use an existing install system, like apt-get or homebrew, because I'm not trying to handle arbitrary installs)
