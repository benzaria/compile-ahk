@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul

:: ╭───────────────────────────────────────────────────────────────────────╮ ::
:: │                      compile-ahk MadeBy Benzaria                      │ ::
:: │            Compile your AutoHotkey scripts with better CLI            │ ::
:: ╰───────────────────────────────────────────────────────────────────────╯ ::
::  ver 1.2 >> for more info check https://github.com/benzaria/compile-ahk   ::

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
set "cp="

:: default pre/post-commands
set "pre_build="
set "post_build="

call :__parse-args__ %* || %clean-exit%
call :__start-alternative-buffer__

if !__args_length! geq 1 if not defined ahk_in_file (
    set "ahk_in_file=!__args[0]!"
    set "__args=!__args:^"%__args[0]%^"=!"
    set /a __args_length -= 1
) 
call :__ahk-in-file__ "!ahk_in_file!" "*.ahk*"
if not exist "!ahk_exe!" %warn% ahk-exe Compiler could not be resolved from '!ahk_exe!' ^
    set "ahk_exe=!ahk_dir!\Compiler\Ahk2Exe.exe"

for /f %%i in (' dir /b "!ahk_dir!\!ahk_ver!*" 2^>nul ') do set "ahk_dir=!ahk_dir!\%%~i"
for /f %%i in (' dir /b "!ahk_dir!\*.exe" 2^>nul ^| find /i /v "ui ansi" ^| find /i "32" ') do set "ahk_bin_32=%%~i"
for /f %%i in (' dir /b "!ahk_dir!\*.exe" 2^>nul ^| find /i /v "ui ansi" ^| find /i "64" ') do set "ahk_bin_64=%%~i"
if defined cp set "use_icon=/cp !cp!"
if defined icon set "use_icon=/icon !icon!"
if defined resource set "use_resource=/resourceid !resource!"

call :__start-watcher__ && %end%
call :__pre-compile__ &&^
call :__compile__ &&^
call :__post-compile__

set /a exit_code = !errorlevel!

:__end__
if defined no_emit call :__clean-build-dir__ "" true
timeout /t 1 /nobreak >nul
%info% Press a key to continue... & pause >nul

:__clean-exit__
call :__end-alternative-buffer__
endlocal & exit /b !exit_code!

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

        for /f %%j in (' echo !ver! ^| findstr "32 86" ') do set "ahk_bin=!ahk_bin_32!"
        for /f %%j in (' echo !ver! ^| findstr "64" ') do set "ahk_bin=!ahk_bin_64!"
    
        set "status=Building %esc%[96m!compile_name!%esc%[0m with %esc%[32m!ahk_bin!%esc%[0m %esc%[90m!compress_exe!%esc%[0m"
    
        %info% !status! %cr%
        "!ahk_exe!" /in "!ahk_in_file!" /out "!compile_path!" /base "!ahk_dir!\!ahk_bin!" ^
            /compress !compress! !use_icon! !use_resource! !use_cp! !gui! !no_msg! >nul 2>"%stderr%"

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
    
        if defined no_msg call :__type-delete__ "%stderr%"
        if defined fatal_error if not defined no_exit %exit% 2
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
    set "br=echo."
    set "cr=%esc%[F"
    set "this_path=%~dp1"
    set "this_name=%esc%[0;93m%~n1%esc%[0m"
    set "ahk_temp=%temp%\Compile-ahk\"
    set "stderr=%ahk_temp%stderr"
    set "cmd-stdout=%ahk_temp%cmd-stdout"
    set "regex=\.ahk$ \.ahk1$ \.ahk2$"
    set "start=goto :__start__"
    set "end=goto :__end__"
    set "clean-exit=goto :__clean-exit__"
    set "info=call :__info__"
    set "warn=call :__warn__"
    set "error=call :__error__"
    set "success=call :__success__"
    set "write=call :__write__"
    set "assets=%this_path%assets"
    set "bin=%this_path%bin"
    set "bin_compiler=%bin%\Compiler"
    set "bin_launcher=%bin%\AutoHotkey"
    set "no_msg=/silent"
    set "exit=%br% & exit /b"
    set "verbose=if not defined quiet echo"
    set "ascii_logo="

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
    if "%~1"=="" shift & %warn% ahk-input-file is empty, resolving from '*.ahk*'
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
    if not defined watch exit /b 1
    if !__args_length! geq 1 set "pass_args=-PassArgs "!__args!""
    if exist "%bin%\watcher.ps1" (
        powershell -ExecutionPolicy Bypass -NoProfile -NoLogo -File "%bin%\watcher.ps1" ^
            -Path "!ahk_in_file!" -Filter "*.ahk?" !pass_args! || %error% Watcher could not be started
    )
    exit /b 0

:__clean-build-dir__
    if not "%~2"=="" set "bypass=rem"
    if not "%~1"=="" !%~1! Building directory has been cleared
    del "!ahk_out_dir!\*.exe" >nul 2>&1
    !bypass! for /f %%i in (' dir /b "!ahk_out_dir!" 2^>nul ') do ^
        if not "%~1"=="" !%~1! Building directory has some non 'exe' files & exit /b 1
    exit /b 0

:__sys-arch__
    if not defined PROCESSOR_ARCHITEW6432 if "%PROCESSOR_ARCHITECTURE%"=="x86" set /a sys_arch = 32
    if not exist "%bin_compiler%\upx.exe" copy /y "%bin_compiler%\upx-!sys_arch!.exe" "%bin_compiler%\upx.exe" >nul 2>&1 
    exit /b 0

:__exec-cmd__
    set "name=%~1"
    if "!%~1!"=="" ( set "cmd=%~2" ) else ( set "cmd=!%~1!" ) 
    %br%
    set "status=Executing !name:_=-! '!cmd!'"
    %info% !status! %cr%
    !cmd! > "%cmd-stdout%" 2>&1 && %success% !status! || %error% !status!
    call :__type-delete__ "%cmd-stdout%"
    exit /b 0

:__write__
    <nul set /p="%*"
    exit /b 0

:__type-delete__
    type "%~1" 2>nul
    del "%~1" >nul 2>&1
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
    
    :--ascii-logo
        set "ascii_logo=true"
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

    :-a
    :--arch
        set /a n = 1
        set "next[1]=ahk_arch"
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

    :-p
    :--codepage
        set /a n = 1
        set "next[1]=cp"
        exit /b 0

    :-w
    :--watch
        set "watch=true"
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
    set "padding=%esc%[%pad%C"
    set "border=echo %esc%[%push%G│%esc%[G%padding%│"
    set "line=──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────"
    set "line=!line:~,%width%!"
    set "limit1=echo %padding%╭!line!╮"
    set "limit2=echo %padding%╰!line!╯"
    
    set "-=%esc%[96m" & set "--=%esc%[90m" & set "+=%esc%[94m" 
    set "¬=%esc%[0m" & set "'=%esc%[90m" & set "_=%esc%[4m"
    set "short=!limit1!%esc%[2G%padding%[%esc%[94mShort%¬%]"
    set "long=!limit1!%esc%[2G%padding%[%esc%[94mLong%¬%]"

    :: Display Help
    call :__display-logo__
    echo %esc%[1;94m AutoHotkey Compiler CLI %esc%[33mv1.2%¬% Made by %esc%[96m%esc%]8;;https://github.com/benzaria/compile-ahk@benzaria%esc%]8;;%¬% in %esc%[32m20/03/2025%¬%
    %br%
    echo      %esc%[3;90m$ %this_name% [%-%-f%¬%, %--%--file%¬%] %+%^<file^|dir^>%¬% [%+%Args%¬%] [%+%Options%¬%]
    %br%
    %short%
    %border% %-%-f%¬%, %--%--file%¬%      %+%^<path^>%¬%    Specify the input AHK file or directory. %'%(regex: '\.ahk[12]?$')%¬%
    %border% %-%-d%¬%, %--%--dir%¬%       %+%^<path^>%¬%    Define the executable output directory. %'%(default: dist)%¬%
    %border% %-%-v%¬%, %--%--versions%¬%  %+%^<list^>%¬%    Compile for multiple versions. %'%(e.g, "32 64 "32-mpress" ...")%¬%
    %border% %-%-i%¬%, %--%--icon%¬%      %+%^<icon^>%¬%    Set a custom icon for the executable.
    %border% %-%-c%¬%, %--%--compress%¬%  %+%^<method^>%¬%  Select a compression method (%_%mpress%¬% or %_%upx%¬%).
    %border% %-%-a%¬%, %--%--arch%¬%      %+%^<32^|64^>%¬%   Choose between %_%32%¬% and %_%64%¬% bit architectures. %'%(default: sys_arch)%¬%
    %border% %-%-r%¬%, %--%--resource%¬%  %+%^<res-id^>%¬%  Specify resource ID.
    %border% %-%-s%¬%, %--%--seperator%¬% %+%^<char^>%¬%    Define the separator between name and versions. %'%(default: -)%¬%
    %border% %-%-p%¬%, %--%--codepage%¬%  %+%^<code^>%¬%    Specify codepage.
    %border% %-%-w%¬%, %--%--watch%¬%               Watch ahk file for changes and execute them.
    %border% %-%-q%¬%, %--%--quiet%¬%               Disable verbose output.
    %border% %-%-m%¬%, %--%--msg%¬%                 Use default msgbox output.
    %border% %-%-n%¬%, %--%--clean%¬%               Clear the output directory before compilation.
    %border% %-%-g%¬%, %--%--gui%¬%                 Use the GUI version of the compiler.
    %border% %-%-h%¬%, %--%--help%¬%                Display %this_name% help menu.
    %limit2%
    %br%
    %long%
    %border% %-%--pre-build%¬%     %+%^<cmd^>%¬%     Register a pre-build script or command.
    %border% %-%--post-build%¬%    %+%^<cmd^>%¬%     Register a post-build script or command.
    %border% %-%--ahk-dir%¬%       %+%^<path^>%¬%    Specify the AutoHotkey installation directory.
    %border% %-%--ahk-ver%¬%       %+%^<v1^|v2^>%¬%   Set the AutoHotkey version. %'%(default: v2)%¬%
    %border% %-%--no-emit%¬%                 Don't Emit executable files.
    %border% %-%--no-exit%¬%                 Don't Exit on fatal errors. %'%(e.g, syntax)%¬%
    %limit2%
    exit /b 0
    
:__display-logo__
    if not defined ascii_logo if exist "%assets%\ahk-cli-logo.six" type "%assets%\ahk-cli-logo.six" 2>nul && exit /b 0
    echo  _____ _____ _____ _____ 
    echo ^|^|A  ^|^|^|H  ^|^|^|K  ^|^|^|CLI^|^|
    echo ^|^|___^|^|^|___^|^|^|___^|^|^|___^|^|
    echo ^|/___\^|/___\^|/___\^|/___\^|
    exit /b 0