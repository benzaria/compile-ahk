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
::egkzugNsPRvcWATEpSI=
::dAsiuh18IRvcCxnZtBJQ
::cRYluBh/LU+EWAnk
::YxY4rhs+aU+IeA==
::cxY6rQJ7JhzQF1fEqQJhZkkaHErSXA==
::ZQ05rAF9IBncCkqN+0xwdVsFAlbMbCXqZg==
::ZQ05rAF9IAHYFVzEqQIRPQ9bZAuWN26jRpYT5fjy4++V4m4xfYI=
::eg0/rx1wNQPfEVWB+kM9LVsJDCeNMXuzCrBR6eDwoe+fpy0=
::fBEirQZwNQPfEVWB+kM9LVsJDCeNMXuzCrBR6eDwjw==
::cRolqwZ3JBvQF1fEqQITJxZERQiHfGq0AvU58O34+v6C4lQSQfB/WZrP1ZyBNOsW8wX3doQkxm5J2NwFGBMYfBe/egom6U1unwQ=
::dhA7uBVwLU+EWFuB+lgxOhJVLA==
::YQ03rBFzNR3SWATElA==
::dhAmsQZ3MwfNWATE9kc+MhpGRQXi
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
    echo [[1;94mINFO[0m] - First run can be a litle slow.
    timeout /t 5 /nobreak >nul
    call :__cli-exist__ || (
        echo [F[[1;91mERROR[0m] - Ahk CLI could not be resolved in '%cli_path%'
        exit /b 1
    )
)

echo [F[K[F
"%cli%" %*

exit /b 0

:__cli-exist__
    if exist "%cli%" exit /b 0
    exit /b 1