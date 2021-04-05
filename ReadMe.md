# ChoVersion
### The Chocolatey Version Picker

This is a PowerShell module for choosing a particular version of command-line tools. It works with chocolatey as an installer, installing multiple versions of tools side-by-side, and then letting you pick one to use by changing which one is in your path.

It accomplishes this by adding the path to the tool to the environment PATH in a manner suitable for build pipelines. It is compatible with Azure DevOps Pipelines and GitHub Actions.

It currently depends on chocolatey (`choco`) for actually installing the tools on the agent, so it's Windows only, but it works on [Microsoft's hosted agents](https://github.com/actions/virtual-environments/blob/main/images/win/Windows2019-Readme.md), although it does not use the agent's "tools" folder to install or cache the tools, so it may not be the most efficient way to install tools.

It offers an experimental switch to change your current user's environment PATH permanently, so you can use it to switch between versions on your local box in a way that affects all new processes (but no existing processes except the current PowerShell session).

## Supports a `ChoVersion.psd1` file

To quickly install dependencies, you can add a `ChoVersion.psd1` file to any folder. For instance, if you add this ChoVersion.psd1
```PowerShell
@{
Application = @"
terraform|0.14.9
terragrunt|0.28.18
"@
}
```

Simply running `Set-ChoVersion` in that folder will (install and) switch to the specified version of terraform and terragrunt -- assuming they're available in your chocolatey tools (or your chocolatey sources).

## TODO:

1. Make installs go to the agent tools cache when there is one
2. Provide a configurable way to provide installers for missing tools without relying on choco so we can function cross-platform (i.e. support yarn or npm/pypi/apt-get/homebrew)
3. Support using a shim/symlink to support permanent switching. Should this really be possible? Should this require elevation?