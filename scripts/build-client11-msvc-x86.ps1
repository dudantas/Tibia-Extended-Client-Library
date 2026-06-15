[CmdletBinding()]
param(
    [string] $Root,
    [string] $OutDir,
    [string] $InstallDir,
    [string] $VsDevCmd = $env:VSDEVCMD,
    [string] $HostArch = "x64",
    [switch] $Clean
)

$buildParams = @{
    BuildProfile = "client-11"
    HostArch = $HostArch
}

if ($VsDevCmd) { $buildParams.VsDevCmd = $VsDevCmd }
if ($Root) { $buildParams.Root = $Root }
if ($OutDir) { $buildParams.OutDir = $OutDir }
if ($InstallDir) { $buildParams.InstallDir = $InstallDir }
if ($Clean) { $buildParams.Clean = $true }

& (Join-Path $PSScriptRoot "build-canary-860-msvc-x86.ps1") @buildParams
