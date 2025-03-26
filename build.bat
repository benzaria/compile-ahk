@echo off
setlocal EnableDelayedExpansion

set "outdir=.\dist"
set "standalone=%outdir%\Compile-ahk-Standalone"
set "sfx=%outdir%\Compile-ahk-sfx.exe"
set "zip=%outdir%\Compile-ahk.7z"

set "ver=1.2.0.0"
set /a sys_arch = 64
if "%PROCESSOR_ARCHITEW6432%"=="" if "%PROCESSOR_ARCHITECTURE%"=="x86" set /a sys_arch = 32

set "ahk_temp=%temp%\Compile-ahk"
set "rh=.\dev-dependencies\ResourceHacker\RH.exe"
set "7z=.\dev-dependencies\7z\7z.exe"
set "bat2exe=.\dev-dependencies\BatToExe\Bat_To_Exe_Converter_x!sys_arch!.exe"

mkdir "%outdir%"
mkdir "%ahk_temp%"
del /q /s "%outdir%\*"
del /q /s "%ahk_temp%\*"

xcopy /y ".\bin" "%ahk_temp%\bin" /e /i
copy  /y ".\assets\ahk-cli-logo.six" "%ahk_temp%\assets\ahk-cli-logo.six"
copy  /y ".\Compile-ahk.bat" "%ahk_temp%\Compile-ahk.bat"

del /q "%ahk_temp%\bin\Compiler\upx.exe"

call :__build-standalone__ "!bat2exe!"
call :__build-self-extract__ "!7z!"

endlocal
exit /b 0

:__build-standalone__
    :: if you encountered any problem with the standalone version not working 
    :: try using the gui BatToExe and the settings will be configured for you
    set "param=/include "%ahk_temp%" /extractdir 2 /workdir 0 /overwrite /async /fileversion %ver% /productversion %ver% /productname "AutoHotkey Compiler CLI" /originalfilename Compile-ahk.exe /internalname Compile-ahk /description "Compile and Execute your AutoHotkey scripts with better CLI" /company benzaria /copyright benzaria"
    "%~1" /bat ".\wrapper.bat" /exe "%standalone%-32.exe" /icon ".\assets\ahk-cli.ico" %param%
    "%~1" /bat ".\wrapper.bat" /exe "%standalone%-64.exe" /icon ".\assets\ahk-cli.ico" %param% /x64
    exit /b 0

:__build-self-extract__
    "%~1" a -t7z -m0=lzma2 -mx=9 -mfb=64 -md=32m -ms=on -mhc=on -mmt=on -mqs=on -mmtf=on -mtc=on "%zip%" "%ahk_temp%\*"
    copy /b "%~dp17z.sfx" + "%~dp1sfx.ini" + "%zip%" "%sfx%"
    "%rh%" -open "%outdir%\Compile-ahk-sfx.exe" -save "%outdir%\Compile-ahk-sfx.exe" -action addoverwrite -mask ICONGROUP,1, -log CONSOLE -resource ".\assets\ahk-cli.ico"
    exit /b 0