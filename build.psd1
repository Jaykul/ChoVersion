@{
    ModuleManifest           = ".\Source\ChoVersion.psd1"
    SourceDirectories        = @("Private", "Public")
    CopyDirectories          = "lib"
    Prefix                   = "Header\Constants.ps1"
    ReadMe                   = "..\..\ReadMe.md"
    OutputDirectory          = "../"
    VersionedOutputDirectory = $true
}