$Shim = Get-FileHash "$PSScriptRoot\lib\shim.exe" -ErrorAction SilentlyContinue -ErrorVariable MissingShim
if ($MissingShim) {
    Write-Error "The 'shim.exe' is missing from '$PSScriptRoot\lib' and ChoVersion will not work. Please reinstall ChoVersion."
}
if ($Shim.Hash -ne "AA685053F4A5C0E7145F2A27514C8A56CEAE25B0824062326F04037937CAA558") {
    Write-Error "The 'shim.exe' file has been changed in '$PSScriptRoot\lib' and ChoVersion will not work. Please reinstall ChoVersion."
}