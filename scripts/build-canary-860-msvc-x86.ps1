[CmdletBinding()]
param(
    [ValidateSet("canary-860", "client-11")]
    [string] $Profile = "canary-860",
    [string] $Root,
    [string] $OutDir,
    [string] $InstallDir,
    [string] $VsDevCmd = $env:VSDEVCMD,
    [string] $HostArch = "x64",
    [string[]] $Defines = @(),
    [switch] $Clean
)

$ErrorActionPreference = "Stop"

function Resolve-FullPath {
    param([Parameter(Mandatory)] [string] $Path)

    $executionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
}

function Find-VsDevCmd {
    param([string] $ExplicitPath)

    if ($ExplicitPath) {
        if (-not (Test-Path -LiteralPath $ExplicitPath -PathType Leaf)) {
            throw "VsDevCmd was provided but was not found: $ExplicitPath"
        }

        return (Resolve-FullPath $ExplicitPath)
    }

    $vsWhere = Join-Path ${env:ProgramFiles(x86)} "Microsoft Visual Studio\Installer\vswhere.exe"
    if (Test-Path -LiteralPath $vsWhere -PathType Leaf) {
        $installPath = & $vsWhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
        if ($LASTEXITCODE -eq 0 -and $installPath) {
            $candidate = Join-Path $installPath "Common7\Tools\VsDevCmd.bat"
            if (Test-Path -LiteralPath $candidate -PathType Leaf) {
                return (Resolve-FullPath $candidate)
            }
        }
    }

    throw "Could not find VsDevCmd.bat. Run this from a Visual Studio Developer PowerShell or pass -VsDevCmd."
}

function Import-VsDevEnvironment {
    param(
        [Parameter(Mandatory)] [string] $VsDevCmdPath,
        [Parameter(Mandatory)] [string] $HostArchitecture
    )

    $command = "`"$VsDevCmdPath`" -arch=x86 -host_arch=$HostArchitecture >nul && set"
    $environment = & cmd.exe /d /s /c $command
    if ($LASTEXITCODE -ne 0) {
        throw "VsDevCmd failed with exit code $LASTEXITCODE."
    }

    foreach ($line in $environment) {
        $separator = $line.IndexOf("=")
        if ($separator -le 0) {
            continue
        }

        $name = $line.Substring(0, $separator)
        $value = $line.Substring($separator + 1)
        Set-Item -LiteralPath "Env:$name" -Value $value
    }
}

if (-not $Root) {
    $Root = Join-Path $PSScriptRoot ".."
}

$Root = Resolve-FullPath $Root

if ($Defines.Count -eq 0) {
    switch ($Profile) {
        "canary-860" {
            $Defines = @(
                "__INCLUDE_860_VERSION__",
                "__CONFIG__",
                "__MAGIC_EFFECTS_U16__"
            )
        }
        "client-11" {
            $Defines = @(
                "__INCLUDE_CLIENT11_VERSION__",
                "__CONFIG__"
            )
        }
    }
}

if (-not $OutDir) {
    $OutDir = Join-Path $Root "build\$Profile"
}

$OutDir = Resolve-FullPath $OutDir

if ($InstallDir) {
    $InstallDir = Resolve-FullPath $InstallDir
}

if ($Clean -and (Test-Path -LiteralPath $OutDir)) {
    Remove-Item -LiteralPath $OutDir -Recurse -Force
}

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

if (-not $env:VSCMD_VER) {
    $VsDevCmd = Find-VsDevCmd $VsDevCmd
    Import-VsDevEnvironment -VsDevCmdPath $VsDevCmd -HostArchitecture $HostArch
}

$defPath = Join-Path $OutDir "ddraw.def"
@"
LIBRARY ddraw
EXPORTS
    DirectDrawCreate=_DirectDrawCreate@12
    DirectDrawCreate@12=_DirectDrawCreate@12
"@ | Set-Content -LiteralPath $defPath -Encoding ASCII

$sources = @(
    "src\config.cpp",
    "src\dllmain.cpp",
    "src\extdx9.cpp",
    "src\extogl.cpp",
    "src\hook.cpp",
    "src\sprites.cpp",
    "src\timer.cpp"
) | ForEach-Object { Join-Path $Root $_ }

$compilerArgs = @(
    "/nologo",
    "/LD",
    "/O2",
    "/MT",
    "/EHsc",
    "/std:c++17",
    "/DWIN32_LEAN_AND_MEAN",
    "/D_CRT_SECURE_NO_WARNINGS",
    "/Dstricmp=_stricmp",
    "/I", (Join-Path $Root "src"),
    "/Fo$OutDir\"
)

foreach ($define in $Defines) {
    if ($define) {
        $compilerArgs += "/D$define"
    }
}

$compilerArgs += $sources
$compilerArgs += @(
    "/link",
    "/OUT:$(Join-Path $OutDir "ddraw.dll")",
    "/IMPLIB:$(Join-Path $OutDir "ddraw.lib")",
    "/DEF:$defPath",
    "user32.lib",
    "ws2_32.lib",
    "opengl32.lib",
    "d3d9.lib"
)

Push-Location $Root
try {
    & cl.exe @compilerArgs
    if ($LASTEXITCODE -ne 0) {
        throw "cl.exe failed with exit code $LASTEXITCODE."
    }
}
finally {
    Pop-Location
}

$dllPath = Join-Path $OutDir "ddraw.dll"
if ($InstallDir) {
    if (-not (Test-Path -LiteralPath $InstallDir -PathType Container)) {
        throw "InstallDir does not exist: $InstallDir"
    }

    Copy-Item -LiteralPath $dllPath -Destination (Join-Path $InstallDir "ddraw.dll") -Force
    Write-Host "installed=$InstallDir\ddraw.dll"
}

Write-Host "built=$dllPath"
