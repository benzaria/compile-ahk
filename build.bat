@echo off
setlocal EnableDelayedExpansion

set "standalone=.\dist\Compile-ahk-Standalone"
set "sfx=.\dist\Compile-ahk-sfx.exe"
set "zip=.\dist\Compile-ahk.7z"

set /a sys_arch = 64
if "%PROCESSOR_ARCHITEW6432%"=="" if "%PROCESSOR_ARCHITECTURE%"=="x86" set /a sys_arch = 32

set "ahk_temp=%temp%\Compile-ahk"
set "7z=.\dependencies\7z\7z.exe"
set "bat2exe=.\dependencies\BatToExe\Bat_To_Exe_Converter_x!sys_arch!.exe"

mkdir ".\dist"
mkdir "%ahk_temp%"
del /q ".\dist\*"
del /q "%ahk_temp%\*"

xcopy /y ".\assets" "%ahk_temp%\assets" /e /i
xcopy /y ".\bin" "%ahk_temp%\bin" /e /i
copy  /y ".\Compile-ahk.bat" "%ahk_temp%\Compile-ahk.bat"

del /q "%ahk_temp%\bin\Compiler\upx.exe"

call :__build-standalone__ "!bat2exe!"
call :__build-self-extract__ "!7z!"

endlocal
exit /b 0

:__build-standalone__
    :: if you encountered any problem with the standalone version not working 
    :: try using the gui BatToExe and the settings will be preconfigured for you
    "%~1" /bat ".\wrapper.bat" /exe "%standalone%-32.exe" /icon ".\assets\ahk-cli.ico" /include "%ahk_temp%" /extractdir 2 /workdir 0 /async
    "%~1" /bat ".\wrapper.bat" /exe "%standalone%-64.exe" /icon ".\assets\ahk-cli.ico" /include "%ahk_temp%" /extractdir 2 /workdir 0 /async /x64
    exit /b 0

:__build-self-extract__
    "%~1" a -t7z -m0=lzma2 -mx=9 -mfb=64 -md=32m -ms=on -mhc=on -mmt=on -mqs=on -mmtf=on -mtc=on "%zip%" "%ahk_temp%\*"
    copy /b "%~dp17z.sfx" + "%~dp1sfx.ini" + "%zip%" "%sfx%"
    exit /b 0