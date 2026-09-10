@echo off
cd /d "%~dp0"

if not exist build mkdir build
if not exist build\x64host mkdir build\x64host

setlocal

call "%~dp0tools\vcvars.bat" amd64 || exit /b 1

cl /nologo /LD /EHsc /O2 /MD /W3 /std:c++20 ^
 /Iexternal\reshade\include ^
 /Iexternal\imgui ^
 /Iexternal\vulkan ^
 /Iexternal\minhook\include ^
 /Fobuild\x64host\ ^
 /Fdbuild\x64host\ ^
 src\dlss5-feed32.cpp ^
 external\minhook\src\buffer.c ^
 external\minhook\src\hook.c ^
 external\minhook\src\trampoline.c ^
 external\minhook\src\hde\hde64.c ^
 /link ^
 /OUT:build\dlss5-feed-hostclient.addon64 ^
 d3d11.lib dxgi.lib dwmapi.lib kernel32.lib user32.lib advapi32.lib

if errorlevel 1 exit /b 1

endlocal
echo.
echo HOST CLIENT ADDON64 BUILT.
