@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul

set "standalone=Compile-ahk-Standalone"
set "sfx=Compile-ahk-sfx"

set /a sys_arch = 64
if "%PROCESSOR_ARCHITEW6432%"=="" if "%PROCESSOR_ARCHITECTURE%"=="x86" set /a sys_arch = 32

set "ahk_temp=%temp%\Compile-ahk"
set "7z=./dependencies/7z/7z.exe"
set "bat2exe=./dependencies/BatToExe/Bat_To_Exe_Converter_x!sys_arch!.exe"

mkdir "./dist" 2>nul
mkdir "%ahk_temp%" 2>nul
del "%ahk_temp%/*" 2>nul

xcopy "./assets" "%ahk_temp%/assets" /e /i /y
xcopy "./bin" "%ahk_temp%/bin" /e /i /y

del "./dist/*.exe" 2>nul
del "%ahk_temp%/bin/Compiler/upx.exe" 2>nul

call :__build-standalone__ "!bat2exe!"
call :__build-self-extract__ "!7z!"

endlocal
exit /b 0

:__build-standalone__
    :: if you encountered any problem with the help menu locking messed up 
    :: try using the gui BatToExe and in the settings set the codepage to UTF-8
    "%~1" /bat "./compile-ahk.bat" /exe "./dist/%standalone%-32.exe" /include "%ahk_temp%" /extractdir 2 /workdir 0 
    "%~1" /bat "./compile-ahk.bat" /exe "./dist/%standalone%-64.exe" /x64 /include "%ahk_temp%" /extractdir 2 /workdir 0 

    exit /b 0

:__build-self-extract__
    
    "%~1" a -t7z -m0=lzma2 -mx=9 -mfb=64 -md=32m -ms=on -mhc=on -mmt=on -mqs=on -mmtf=on -mtc=on "./dist/%sfx%.7z" "./bin" "./assets" "./compile-ahk.bat"

    copy /b "%~dp17zCon.sfx" + "%~dp1sfx.ini" + "./dist/%sfx%.7z" "./dist/%sfx%.exe"

    exit /b 0