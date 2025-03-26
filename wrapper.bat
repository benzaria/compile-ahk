::[Bat To Exe Converter]
::
::fBE1pAF6MU+EWHreyHcjLQlHcAaHMnGGJ6UMzOnv7tarrU4cWN4LfYLL5peBLfAa5kCpdJ4mtg==
::YAwzoRdxOk+EWAjk
::fBw5plQjdCyDJGyX8VAjFBlRQh6+cmi1CLMV79To7PiEslQha908d4LL07iLbeEb4XnlZoUowmlmmcMHQRhUd1yibQBU
::YAwzuBVtJxjWCl3EqQJgSA==
::ZR4luwNxJguZRRnk
::Yhs/ulQjdF+5
::cxAkpRVqdFKZSDk=
::cBs/ulQjdF25
::ZR41oxFsdFKZSDk=
::eBoioBt6dFKZSTk=
::cRo6pxp7LAbNWATEpCI=
::egkzugNsPRvcWATEpCI=
::dAsiuh18IRvcCxnZtBJQ
::cRYluBh/LU+EWAnk
::YxY4rhs+aU+JeA==
::cxY6rQJ7JhzQF1fEqQJQ
::ZQ05rAF9IBncCkqN+0xwdVs0
::ZQ05rAF9IAHYFVzEqQJQ
::eg0/rx1wNQPfEVWB+kM9LVsJDGQ=
::fBEirQZwNQPfEVWB+kM9LVsJDGQ=
::cRolqwZ3JBvQF1fEqQJQ
::dhA7uBVwLU+EWDk=
::YQ03rBFzNR3SWATElA==
::dhAmsQZ3MwfNWATElA==
::ZQ0/vhVqMQ3MEVWAtB9wSA==
::Zg8zqx1/OA3MEVWAtB9wSA==
::dhA7pRFwIByZRRnk
::Zh4grVQjdCyDJGyX8VAjFBlRQh6+cmi1CLMV79To7PiEslQha908d4LL07iLbeEb4XngfIU56llVldsFAB4VfxqgIzwgqGBGt2iKOcLR4F2vT1CMhg==
::YB416Ek+ZG8=
::
::
::978f952a14a936cc963da21a135fa983
@echo off

set "cli_path=%b2eincfilepath%\Compile-ahk"
set "cli=%cli_path%\Compile-ahk.bat"

call :__cli-exist__ || (
    timeout /t 2 /nobreak >nul
    call :__cli-exist__ || (
        echo [[1;91mERROR[0m] - Ahk CLI could not be resolved in '%cli_path%'
        exit /b 1
    )
)

"%cli%" %*

exit /b 0

:__cli-exist__
    if not exist "%cli_path%" exit /b 1
    if not exist "%cli%" exit /b 1
    exit /b 0