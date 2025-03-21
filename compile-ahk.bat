@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul

:: ╭───────────────────────────────────────────────────────────────────────╮ ::
:: │                      compile-ahk MadeBy Benzaria                      │ ::
:: │            Compile your AutoHotkey scripts with better CLI            │ ::
:: ╰───────────────────────────────────────────────────────────────────────╯ ::
::  ver 1.0 >> for more info check https://github.com/benzaria/compile-ahk   ::

:__start__
call :__global-vars__
call :__sys-arch__

:: default values
set "versions=32 64 32-mpress 64-mpress 32-upx 64-upx"
set "ahk_dir=%ProgramFiles%\AutoHotkey"
set "ahk_exe=%bin%\Ahk2Exe.exe"
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

if !__args_length! equ 1 if not defined ahk_in_file set "ahk_in_file=!__args[0]!"
call :__ahk-in-file__ "%ahk_in_file%" "*.ahk"

for /f %%i in (' dir /b "%ahk_dir%\%ahk_ver%*" 2^>nul ') do set "ahk_dir=%ahk_dir%\%%~i"
for /f %%i in (' dir /b "%ahk_dir%\*.exe" 2^>nul ^| find /i /v "ui" ^| find /i "32" ') do set "ahk_bin_32=%%~i"
for /f %%i in (' dir /b "%ahk_dir%\*.exe" 2^>nul ^| find /i /v "ui" ^| find /i "64" ') do set "ahk_bin_64=%%~i"
if defined icon set "use_icon=/icon %icon%"
if defined resource set "use_resource=/resourceid %resource%"
if not exist "!ahk_exe!" set "ahk_exe=!ahk_dir!\Compiler\Ahk2Exe.exe"

call :__start-alternative-buffer__
call :__pre-compile__ &&^
call :__compile__ &&^
call :__post-compile__

:__end__
if defined no_emit call :__clean-build-dir__ "" force
timeout /t 1 /nobreak >nul
%info% Press a key to continue... & pause >nul

:__clean-exit__
call :__end-alternative-buffer__
endlocal & exit /b !errorlevel!

:__compile__
    for %%i in (%versions%) do (
        if not "%%~i"=="" set "ver=!sp!%%~i"
        set /a ver_count += 1

        set "comp_exe=!compressor!"
        set "compile_name=!ahk_out_file!!ver!.exe"
        set "compile_path=!ahk_out_path!!compile_name!"

        for /f %%j in (' echo !ver! ^| findstr "mpress" ') do set "comp_exe=mpress"
        for /f %%j in (' echo !ver! ^| findstr "upx" ') do set "comp_exe=upx"

        call set /a compress = %%compressor[!comp_exe!]%%
        call set "ahk_bin=%%ahk_bin_!ahk_arch!%%"

        for /f %%j in (' echo !ver! ^| findstr "32" ') do set "ahk_bin=!ahk_bin_32!"
        for /f %%j in (' echo !ver! ^| findstr "64" ') do set "ahk_bin=!ahk_bin_64!"
    
        set "status=Building [%-%m!compile_name![0m with [32m!ahk_bin![0m [90m!comp_exe![0m"
    
        %info% !status! %cr%
        "!ahk_exe!" /in "!ahk_in_file!" /out "!compile_path!" /base "!ahk_dir!\!ahk_bin!" ^
        /compress !compress! !use_icon! !use_resource! !cp! !gui! !no_msg!
    
        if exist "!compile_path!" ( 
            %success% !status!
        ) else (
            %error% !status!
            set /a error_level += 1
        )
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
    set "err=[1;91mUn" & set "suc=[1;32m" 
    set "ratio=!error_level!/!ver_count!"
    set "str=versions were compiled"
    if !error_level! == 0 ( 
        %success% All %str% [1;32mSuccessfully[0m
    ) else (
        if !error_level! equ !ver_count! ( 
            %error% All %str% [1;91mUnSuccessfully[0m
        ) else (
            %warn% Some %str% [1;91mUnSuccessfully [93m%ratio%[0m
        )
    )

    if defined post_build call :__exec-cmd__ post_build
    %exit% 0

:__global-vars__
    set "this=[0;93m%~n0[0m"
    set "regex=\.ahk$ \.ahk1$ \.ahk2$"
    set "start=goto :__start__"
    set "end=goto :__end__"
    set "clean-exit=goto :__clean-exit__"
    set "info=call :__info__"
    set "warn=call :__warn__"
    set "error=call :__error__"
    set "success=call :__success__"
    set "write=call :__write__"
    set "assets=%~dp0assets"
    set "bin=%~dp0bin"
    set "cr=[F"
    set "br=echo."
    set "exit=%br% & exit /b"
    set "verbose=if not defined quiet echo"

    set /a compressor[mpress] = 1
    set /a compressor[upx] = 2
    set /a compressor[] = 0
    set /a error_level = 0
    set /a ver_count = 0
    set /a sys_arch = 64

    exit /b 0

:__start-alternative-buffer__
    set "alternative_buffer=true"
    %write% [?1049h[?25l[H
    exit /b 0

:__end-alternative-buffer__
    if defined alternative_buffer (
        set "alternative_buffer="
        %write% [?1049l[?25h
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
    if not defined file set "file=%~1" & %warn% ahk-input-file could not be resolved from '!%~1!'
    call :__update-paths__ !file!
    exit /b 0

:__update-paths__
    set "ahk_in_file=%~f1"
    set "ahk_out_path=%~dp1"
    set "ahk_out_file=!ahk_out_dir!\%~n1"
    set "ahk_out_dir=!ahk_out_path!!ahk_out_dir!"
    if defined no_emit (
        set "ahk_out_file=%~n1"
        set "ahk_out_path=%temp%\Compile-ahk\"
        set "ahk_out_dir=!ahk_out_path!"
    )
    exit /b 0

:__clean-build-dir__
    if not "%~2"=="force" set "force=/s /q"
    if not "%~1"=="" !%~1! Building directory has been cleared
    del "!ahk_out_dir!\*.exe" >nul 2>&1
    rmdir "!ahk_out_dir!" !force! >nul 2>&1 || for /f %%i in (' dir /b "!ahk_out_dir!" 2^>nul ') do ^
        if not "%~1"=="" !%~1! Building directory has some non 'exe' files & exit /b 1
    exit /b 0

:__sys-arch__
    if "%PROCESSOR_ARCHITEW6432%"=="" if "%PROCESSOR_ARCHITECTURE%"=="x86" set /a sys_arch = 32
    if not exist "%bin%\upx.exe" copy /y "%bin%\upx-!sys_arch!.exe" "%bin%\upx.exe" >nul 2>&1 
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
                set "__args=!__args!^"!arg!^" "
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
    if !n! neq 0 %error% Unexpected argument: !arg! ... ^
        %br% & %info% Try %this% -h, --help & exit /b 1
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
    
    :--no-msg
        set "no_msg=/silent"
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

    :-q
    :--quiet
        set "quiet=true"
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
        %verbose% [[1;94mINFO[0m] - %*
        exit /b 0
    
    :__warn__
        %verbose% [[1;33mWARN[0m] - %*
        exit /b 0
    
    :__error__
        %verbose% [[1;31mERROR[0m] - %*
        exit /b 0
    
    :__success__
        %verbose% [[1;92mSUCCESS[0m] - %*
        exit /b 0

:__help__
    :: Help Appearance
    set /a width = 90
    set /a pad = 1
    set /a push = width + pad + 2
    set "show-ahk-logo=type "%assets%\ahk-logo.six" 2>nul || type "%assets%\ahk-logo.txt" 2>nul"
    set "padding=[%pad%C"
    set "border=echo [%push%G│[G%padding%│"
    set "line=──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────"
    set "line=!line:~,%width%!"
    set "limit1=echo %padding%╭!line!╮"
    set "limit2=echo %padding%╰!line!╯"
    
    set "-=96"
    set "--=90"
    set "short=!limit1![2G%padding%[[94mShort[0m]"
    set "long=!limit1![2G%padding%[[94mLong[0m]"
    
    :: Display Help
    %show-ahk-logo%
    echo [1;94m AutoHotkey Compiler CLI [33mv1.0[0m Made by [96m]8;;https://github.com/benzaria/compile-ahk@benzaria]8;;[0m in [32m20/03/2025[0m
    %br%
    echo      [3;90m$ %this% [[%-%m-f[0m, [%--%m--file[0m] [94m^<file^>[0m [[94mOptions[0m]
    %br%
    %short%
    %border% [%-%m-f[0m, [%--%m--file[0m      [94m^<file^>[0m    Specify the input AHK script file. [90m(regex: '\.ahk[12]?$')[0m
    %border% [%-%m-d[0m, [%--%m--dir[0m       [94m^<dir^>[0m     Define the executable output directory. [90m(default: dist)[0m
    %border% [%-%m-v[0m, [%--%m--versions[0m  [94m^<list^>[0m    Compile for multiple versions (e.g., "32 64 "32-mpress" ...").
    %border% [%-%m-i[0m, [%--%m--icon[0m      [94m^<icon^>[0m    Set a custom icon for the executable.
    %border% [%-%m-c[0m, [%--%m--compress[0m  [94m^<method^>[0m  Select a compression method ([4mmpress[0m or [4mupx[0m).
    %border% [%-%m-r[0m, [%--%m--resource[0m  [94m^<res-id^>[0m  Specify additional resources.
    %border% [%-%m-s[0m, [%--%m--seperator[0m [94m^<char^>[0m    Define the separator between name and versions. [90m(default: -)[0m
    rem %border% [%-%m-w[0m, [%--%m--watch[0m               Watch input file for changes.
    %border% [%-%m-q[0m, [%--%m--quiet[0m               Disable verbose output.
    %border% [%-%m-n[0m, [%--%m--clean[0m               Clear the output directory before compilation.
    %border% [%-%m-p[0m, [%--%m--codepage[0m            Enable codepage conversion.
    %border% [%-%m-g[0m, [%--%m--gui[0m                 Use the GUI version of the compiler.
    %border% [%-%m-h[0m, [%--%m--help[0m                Display this help message.
    %limit2%
    %br%
    %long%
    %border% [%-%m--pre-build[0m     [94m^<cmd^>[0m     Register a pre-build script or command
    %border% [%-%m--post-build[0m    [94m^<cmd^>[0m     Register a post-build script or command 
    %border% [%-%m--ahk-dir[0m       [94m^<path^>[0m    Specify the AutoHotkey installation directory.
    %border% [%-%m--ahk-ver[0m       [94m^<version^>[0m Set the AutoHotkey version. [90m(default: v2)[0m
    %border% [%-%m--ahk-arch[0m      [94m^<arch^>[0m    Choose between [4m32[0m and [4m64[0m bit architectures. [90m(default: sys_arch)[0m
    %limit2%
    exit /b 0
    