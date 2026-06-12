@echo off
setlocal

set "ROOT=%~dp0.."
for %%I in ("%ROOT%") do set "ROOT=%%~fI"
set "OUT=%ROOT%\build\canary-860"
set "VSDEVCMD=C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\Tools\VsDevCmd.bat"

if not exist "%OUT%" mkdir "%OUT%"

if not defined VSCMD_VER (
    call "%VSDEVCMD%" -arch=x86 -host_arch=x64
    if errorlevel 1 exit /b %ERRORLEVEL%
)

(
    echo LIBRARY ddraw
    echo EXPORTS
    echo     DirectDrawCreate=_DirectDrawCreate@12
    echo     DirectDrawCreate@12=_DirectDrawCreate@12
) > "%OUT%\ddraw.def"

pushd "%ROOT%"
cl /nologo /LD /O2 /MT /EHsc /std:c++17 ^
    /DWIN32_LEAN_AND_MEAN ^
    /D_CRT_SECURE_NO_WARNINGS ^
    /Dstricmp=_stricmp ^
    /D__INCLUDE_860_VERSION__ ^
    /D__CONFIG__ ^
    /D__MAGIC_EFFECTS_U16__ ^
    /I src ^
    /Fo"%OUT%\\" ^
    src\config.cpp ^
    src\dllmain.cpp ^
    src\extdx9.cpp ^
    src\extogl.cpp ^
    src\hook.cpp ^
    src\sprites.cpp ^
    src\timer.cpp ^
    /link ^
    /OUT:"%OUT%\ddraw.dll" ^
    /IMPLIB:"%OUT%\ddraw.lib" ^
    /DEF:"%OUT%\ddraw.def" ^
    user32.lib ^
    opengl32.lib ^
    d3d9.lib
set "RESULT=%ERRORLEVEL%"
popd

exit /b %RESULT%
