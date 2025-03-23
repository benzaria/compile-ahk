@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul

:: ╭───────────────────────────────────────────────────────────────────────╮ ::
:: │                      compile-ahk MadeBy Benzaria                      │ ::
:: │            Compile your AutoHotkey scripts with better CLI            │ ::
:: ╰───────────────────────────────────────────────────────────────────────╯ ::
::  ver 1.0 >> for more info check https://github.com/benzaria/compile-ahk   ::

:__start__
call :__global-vars__ "%~f0"
call :__sys-arch__

:: default values
set "versions=32 64 32-mpress 64-mpress 32-upx 64-upx"
set "ahk_dir=%ProgramFiles%\AutoHotkey"
set "ahk_exe=%bin_compiler%\Ahk2Exe.exe"
set "ahk_out_dir=dist"
set "ahk_in_file="
set "ahk_arch=!sys_arch!"
set "ahk_ver=v2"
set "compressor="
set "resource="
set "clean="
set "icon="
set "sp=-"

:: default pre/post-commands
set "pre_build="
set "post_build="

call :__parse-args__ %* || %clean-exit%
call :__start-alternative-buffer__

if !__args_length! equ 1 if not defined ahk_in_file set "ahk_in_file=!__args[0]!"
call :__ahk-in-file__ "!ahk_in_file!" "*.ahk"
if not exist "!ahk_exe!" %warn% ahk-exe Compiler could not be resolved from '!ahk_exe!' ^
    set "ahk_exe=!ahk_dir!\Compiler\Ahk2Exe.exe"

for /f %%i in (' dir /b "!ahk_dir!\!ahk_ver!*" 2^>nul ') do set "ahk_dir=!ahk_dir!\%%~i"
for /f %%i in (' dir /b "!ahk_dir!\*.exe" 2^>nul ^| find /i /v "ui" ^| find /i "32" ') do set "ahk_bin_32=%%~i"
for /f %%i in (' dir /b "!ahk_dir!\*.exe" 2^>nul ^| find /i /v "ui" ^| find /i "64" ') do set "ahk_bin_64=%%~i"
if defined icon set "use_icon=/icon !icon!"
if defined resource set "use_resource=/resourceid !resource!"

call :__start-watcher__ && %end%
call :__pre-compile__ &&^
call :__compile__ &&^
call :__post-compile__

:__end__
if defined no_emit call :__clean-build-dir__ "" no-check
timeout /t 1 /nobreak >nul
%info% Press a key to continue... & pause >nul

:__clean-exit__
call :__end-alternative-buffer__
endlocal & exit /b !errorlevel!

:__compile__
    for %%i in (%versions%) do (
        if not "%%~i"=="" set "ver=!sp!%%~i"
        set /a ver_count += 1

        set "compress_exe=!compressor!"
        set "compile_name=!ahk_out_file!!ver!.exe"
        set "compile_path=!ahk_out_path!!compile_name!"

        for /f %%j in (' echo !ver! ^| findstr "mpress" ') do set "compress_exe=mpress"
        for /f %%j in (' echo !ver! ^| findstr "upx" ') do set "compress_exe=upx"

        call set /a compress = %%compressor[!compress_exe!]%%
        call set "ahk_bin=%%ahk_bin_!ahk_arch:~,2!%%"

        for /f %%j in (' echo !ver! ^| findstr "32" ') do set "ahk_bin=!ahk_bin_32!"
        for /f %%j in (' echo !ver! ^| findstr "64" ') do set "ahk_bin=!ahk_bin_64!"
    
        set "status=Building %esc%[96m!compile_name!%esc%[0m with %esc%[32m!ahk_bin!%esc%[0m %esc%[90m!compress_exe!%esc%[0m"
    
        %info% !status! %cr%
        "!ahk_exe!" /in "!ahk_in_file!" /out "!compile_path!" /base "!ahk_dir!\!ahk_bin!" ^
            /compress !compress! !use_icon! !use_resource! !cp! !gui! !no_msg! >nul 2>"%stderr%"

        if not exist "!compile_path!" set "compile_error=true"
        for /f "delims=" %%j in (' type %stderr% 2^>nul ') do (
            echo "%%~j" | findstr /i "error" >nul && set "compile_error=true"
            echo "%%~j" | findstr /i "syntax" >nul && set "fatal_error=true"
        )
        
        if defined compile_error ( 
            %error% !status!
            set "compile_error="
            set /a error_level += 1
        ) else %success% !status!
    
        if defined no_msg (
            type "%stderr%" 2>nul
            del "%stderr%" >nul 2>&1
        )
        if defined fatal_error if not defined no_exit %exit% 1
    )
    %exit% 0

:__pre-compile__
    if not exist "!ahk_dir!" %error% ahk-dir don't exist in "!ahk_dir!" & %exit% 1
    if not exist "!ahk_exe!" %error% ahk-exe Compiler don't exist in "!ahk_exe!" & %exit% 1
    if not exist "!ahk_in_file!" %error% ahk-input-file don't exist in "!ahk_in_file!" & %exit% 1

    if defined clean call :__clean-build-dir__ warn
    mkdir "!ahk_out_dir!" >nul 2>&1

    if defined pre_build call :__exec-cmd__ pre_build
    %exit% 0

:__post-compile__
    set "err=%esc%[1;91mUn" & set "suc=%esc%[1;32m" 
    set "ratio=!error_level!/!ver_count!"
    set "str=versions were compiled"
    if !error_level! == 0 ( 
        %success% All %str% %esc%[1;32mSuccessfully%esc%[0m
    ) else (
        if !error_level! equ !ver_count! ( 
            %error% All %str% %esc%[1;91mUnSuccessfully%esc%[0m
        ) else (
            %warn% Some %str% %esc%[1;91mUnSuccessfully %esc%[93m%ratio%%esc%[0m
        )
    )

    if defined post_build call :__exec-cmd__ post_build
    %exit% 0

:__global-vars__ this
    set "esc="
    set "cr=%esc%[F"
    set "this_path=%~dp1"
    set "this_name=%esc%[0;93m%~n1%esc%[0m"
    :: This line is for the standalone version
    if defined b2eincfilepath set "this_path=%b2eincfilepath%\Compile-ahk\"
    set "ahk_temp=%temp%\Compile-ahk\"
    set "stderr=%ahk_temp%stderr"
    set "regex=\.ahk$ \.ahk1$ \.ahk2$"
    set "start=goto :__start__"
    set "end=goto :__end__"
    set "clean-exit=goto :__clean-exit__"
    set "info=call :__info__"
    set "warn=call :__warn__"
    set "error=call :__error__"
    set "success=call :__success__"
    set "write=call :__write__"
    set "assets=!this_path!assets"
    set "bin=!this_path!bin"
    set "bin_compiler=%bin%\Compiler"
    set "bin_launcher=%bin%\AutoHotkey"
    set "br=echo."
    set "no_msg=/silent"
    set "exit=%br% & exit /b"
    set "verbose=if not defined quiet echo"

    set /a compressor[mpress] = 1
    set /a compressor[upx] = 2
    set /a compressor[] = 0
    set /a error_level = 0
    set /a ver_count = 0
    set /a sys_arch = 64

    mkdir %ahk_temp% 2>nul
    exit /b 0

:__start-alternative-buffer__
    set "alternative_buffer=true"
    %write% %esc%[?1049h%esc%[?25l%esc%[H
    exit /b 0

:__end-alternative-buffer__
    if defined alternative_buffer (
        set "alternative_buffer="
        %write% %esc%[?1049l%esc%[?25h
    )
    exit /b 0

:__ahk-in-file__
    :: !Do Not put a space before the pipe!
    if "%~1"=="" shift
    echo %~1| findstr "%regex%" >nul && set "file=%~f1" || (
        for /f %%i in (' dir /b /a:-D "%~dp1" 2^>nul ') do (
            echo %%~i| findstr "%regex%" >nul && set "file=%~dp1%%~i" && goto :break
        )
    )
    :break
    if not defined file set "file=%~1" & %warn% ahk-input-file could not be resolved from '%~1'
    call :__update-paths__ "!file!"
    exit /b 0

:__update-paths__
    set "ahk_in_file=%~f1"
    set "ahk_out_path=%~dp1"
    if defined no_emit set "ahk_out_path=%ahk_temp%"
    set "ahk_out_file=!ahk_out_dir!\%~n1"
    set "ahk_out_dir=!ahk_out_path!!ahk_out_dir!"
    exit /b 0

:__start-watcher__
echo !pass_args!
    if not defined watch exit /b 1
    if exist "%bin%\watcher.ps1" (
        powershell -ExecutionPolicy Bypass -NoProfile -NoLogo -File "%bin%\watcher.ps1" ^
            -Path "!ahk_in_file!" -Filter "*.ahk?" -PassArgs '!pass_args!' || %error% Watcher could not be started
    )
    exit /b 0

:__clean-build-dir__
    if "%~2"=="no-check" set "bypass=rem"
    if not "%~1"=="" !%~1! Building directory has been cleared
    del "!ahk_out_dir!\*.exe" >nul 2>&1
    !bypass! for /f %%i in (' dir /b "!ahk_out_dir!" 2^>nul ') do ^
        if not "%~1"=="" !%~1! Building directory has some non 'exe' files & exit /b 1
    exit /b 0

:__sys-arch__
    if "%PROCESSOR_ARCHITEW6432%"=="" if "%PROCESSOR_ARCHITECTURE%"=="x86" set /a sys_arch = 32
    if not exist "%bin_compiler%\upx.exe" copy /y "%bin_compiler%\upx-!sys_arch!.exe" "%bin_compiler%\upx.exe" >nul 2>&1 
    exit /b 0

:__exec-cmd__
    set "name=%~1"
    if "!%~1!"=="" ( set "cmd=%~2" ) else ( set "cmd=!%~1!" ) 
    %br%
    set "status=Executing !name:_=-! '!cmd!'"
    %info% !status!
    call !cmd! && %success% !status! || %error% !status!
    exit /b 0

:__write__
    <nul set /p="%*"
    exit /b 0

:: Args Parser from: https://github.com/benzaria/batch-args 
:__parse-args__ => __args[], args[], __args_length, args_length
    set "args=%*" & set "__args="
    set /a args_length = 0
    set /a __args_length = 0
    rem if not defined args goto :__help__
    for %%i in (!args!) do (
        set "arg=%%~i" 
        set "args[!args_length!]=!arg!"
        set /a args_length += 1
        call :!arg! 2>nul || (
            if !errorlevel! equ 2 exit /b 2
            if !n! equ 0 (
                set "__args=!__args!"!arg!" "
                set "__args[!__args_length!]=!arg!"
                set /a __args_length += 1
            ) else (
                call set "next=%%next[!n!]%%"
                set "!next!=!arg!"
                set /a n -= 1
            )
            if defined run if !n! equ 0 call :!run! & set "run="
        )
    )
    if !n! neq 0 %error% Unexpected argument: !arg! ... & %br% & %info% Try %this_name% -h, --help & exit /b 1
    exit /b 0

:: Args
    :--ahk-dir
        set /a n = 1
        set "next[1]=ahk_dir"
        exit /b 0
        
    :--ahk-ver
        set /a n = 1
        set "next[1]=ahk_ver"
        exit /b 0
        
    :--ahk-arch
        set /a n = 1
        set "next[1]=ahk_arch"
        exit /b 0
        
    :--pre-build
        set /a n = 1
        set "next[1]=pre_build"
        exit /b 0
        
    :--post-build
        set /a n = 1
        set "next[1]=post_build"
        exit /b 0
    
    :--no-emit
        set "no_emit=true"
        exit /b 0
    
    :--no-exit
        set "no_exit=true"
        exit /b 0
        
    :-f
    :--file
        set /a n = 1
        set "next[1]=ahk_in_file"
        exit /b 0

    :-d
    :--dir
        set /a n = 1
        set "next[1]=ahk_out_dir"
        exit /b 0

    :-v
    :--versions
        set /a n = 1
        set "next[1]=versions"
        exit /b 0

    :-i
    :--icon
        set /a n = 1
        set "next[1]=icon"
        exit /b 0

    :-c
    :--compress
        set /a n = 1
        set "next[1]=compressor"
        exit /b 0

    :-r
    :--resource
        set /a n = 1
        set "next[1]=resource"
        exit /b 0

    :-s
    :--seperator
        set /a n = 1
        set "next[1]=sp"
        exit /b 0

    :-w
    :--watch
        set "watch=true"
        exit /b 0

    :-a
    :--args
        set /a n = 1
        set "next[1]=pass_args"
        exit /b 0

    :-q
    :--quiet
        set "quiet=true"
        exit /b 0
    
    :-m
    :--msg
        set "no_msg="
        exit /b 0

    :-n
    :--clean
        set "clean=true"
        exit /b 0

    :-p
    :--codepage
        set "cp=/cp"
        exit /b 0

    :-g
    :--gui
        set "gui=/gui"
        exit /b 0
    
    :-h
    :--help
        call :__help__
        exit /b 2

:: Log level
    :__info__
        %verbose% [%esc%[1;94mINFO%esc%[0m] - %*
        exit /b 0
    
    :__warn__
        %verbose% [%esc%[1;33mWARN%esc%[0m] - %*
        exit /b 0
    
    :__error__
        %verbose% [%esc%[1;31mERROR%esc%[0m] - %*
        exit /b 0
    
    :__success__
        %verbose% [%esc%[1;92mSUCCESS%esc%[0m] - %*
        exit /b 0

:__help__
    :: Help Appearance
    set /a width = 90
    set /a pad = 1
    set /a push = 2 + width + pad
    set "show-ahk-logo=type "%assets%\ahk-logo.six" 2>nul || type "%assets%\ahk-logo.txt" 2>nul"
    set "padding=%esc%[%pad%C"
    set "border=echo %esc%[%push%G│%esc%[G%padding%│"
    set "line=──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────"
    set "line=!line:~,%width%!"
    set "limit1=echo %padding%╭!line!╮"
    set "limit2=echo %padding%╰!line!╯"
    
    set "-=96" & set "--=90" & set "+=94"
    set "short=!limit1!%esc%[2G%padding%[%esc%[94mShort%esc%[0m]"
    set "long=!limit1!%esc%[2G%padding%[%esc%[94mLong%esc%[0m]"
    
    :: Display Help
    %show-ahk-logo%
    echo %esc%[1;94m AutoHotkey Compiler CLI %esc%[33mv1.0%esc%[0m Made by %esc%[96m%esc%]8;;https://github.com/benzaria/compile-ahk@benzaria%esc%]8;;%esc%[0m in %esc%[32m20/03/2025%esc%[0m
    %br%
    echo      %esc%[3;90m$ %this_name% [%esc%[%-%m-f%esc%[0m, %esc%[%--%m--file%esc%[0m] %esc%[%+%m^<file^>%esc%[0m [%esc%[%+%mOptions%esc%[0m]
    %br%
    %short%
    %border% %esc%[%-%m-f%esc%[0m, %esc%[%--%m--file%esc%[0m      %esc%[%+%m^<file^>%esc%[0m    Specify the input AHK script file. %esc%[90m(regex: '\.ahk[12]?$')%esc%[0m
    %border% %esc%[%-%m-d%esc%[0m, %esc%[%--%m--dir%esc%[0m       %esc%[%+%m^<dir^>%esc%[0m     Define the executable output directory. %esc%[90m(default: dist)%esc%[0m
    %border% %esc%[%-%m-v%esc%[0m, %esc%[%--%m--versions%esc%[0m  %esc%[%+%m^<list^>%esc%[0m    Compile for multiple versions (e.g, "32 64 "32-mpress" ...").
    %border% %esc%[%-%m-i%esc%[0m, %esc%[%--%m--icon%esc%[0m      %esc%[%+%m^<icon^>%esc%[0m    Set a custom icon for the executable.
    %border% %esc%[%-%m-c%esc%[0m, %esc%[%--%m--compress%esc%[0m  %esc%[%+%m^<method^>%esc%[0m  Select a compression method (%esc%[4mmpress%esc%[0m or %esc%[4mupx%esc%[0m).
    %border% %esc%[%-%m-r%esc%[0m, %esc%[%--%m--resource%esc%[0m  %esc%[%+%m^<res-id^>%esc%[0m  Specify additional resources.
    %border% %esc%[%-%m-s%esc%[0m, %esc%[%--%m--seperator%esc%[0m %esc%[%+%m^<char^>%esc%[0m    Define the separator between name and versions. %esc%[90m(default: -)%esc%[0m
    %border% %esc%[%-%m-w%esc%[0m, %esc%[%--%m--watch%esc%[0m               Watch input file for changes.
    rem %border% %esc%[%-%m-a%esc%[0m, %esc%[%--%m--args%esc%[0m                Arguments to be passed to ahk file in watch mode.
    %border% %esc%[%-%m-q%esc%[0m, %esc%[%--%m--quiet%esc%[0m               Disable verbose output.
    %border% %esc%[%-%m-m%esc%[0m, %esc%[%--%m--msg%esc%[0m                 Use default no_msg output.
    %border% %esc%[%-%m-n%esc%[0m, %esc%[%--%m--clean%esc%[0m               Clear the output directory before compilation.
    %border% %esc%[%-%m-p%esc%[0m, %esc%[%--%m--codepage%esc%[0m            Enable codepage conversion.
    %border% %esc%[%-%m-g%esc%[0m, %esc%[%--%m--gui%esc%[0m                 Use the GUI version of the compiler.
    %border% %esc%[%-%m-h%esc%[0m, %esc%[%--%m--help%esc%[0m                Display this_name help message.
    %limit2%
    %br%
    %long%
    %border% %esc%[%-%m--pre-build%esc%[0m     %esc%[%+%m^<cmd^>%esc%[0m     Register a pre-build script or command.
    %border% %esc%[%-%m--post-build%esc%[0m    %esc%[%+%m^<cmd^>%esc%[0m     Register a post-build script or command.
    %border% %esc%[%-%m--ahk-dir%esc%[0m       %esc%[%+%m^<path^>%esc%[0m    Specify the AutoHotkey installation directory.
    %border% %esc%[%-%m--ahk-ver%esc%[0m       %esc%[%+%m^<version^>%esc%[0m Set the AutoHotkey version. %esc%[90m(default: v2)%esc%[0m
    %border% %esc%[%-%m--ahk-arch%esc%[0m      %esc%[%+%m^<arch^>%esc%[0m    Choose between %esc%[4m32%esc%[0m and %esc%[4m64%esc%[0m bit architectures. %esc%[90m(default: sys_arch)%esc%[0m
    %border% %esc%[%-%m--no-emit%esc%[0m                 Don't Emit executable files.
    rem %border% %esc%[%-%m--no-exit%esc%[0m                 Don't Exit on fatal errors (e.g, syntax).
    %limit2%
    exit /b 0
    