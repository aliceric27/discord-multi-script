@echo off
setlocal enabledelayedexpansion

:: =================================================================================
:: Discord Multi-Instance Manager v4.1 (Safe Deletion)
:: =================================================================================
:: New Feature:
:: - Checks for running Discord processes before deletion and prompts to kill them,
::   ensuring the deletion succeeds.
:: =================================================================================

:: --- Environment Variables ---
set "DISCORD_LAUNCH_EXE=%LOCALAPPDATA%\Discord\Update.exe"
set "PROFILES_BASE_PATH=%LOCALAPPDATA%\Discord\profiles"

:: --- Initialization ---
if not exist "%PROFILES_BASE_PATH%" (
    echo Creating profiles directory...
    mkdir "%PROFILES_BASE_PATH%"
)

:: =================================================================================
:: Main Loop (Instance Dashboard)
:: =================================================================================
:main_loop
cls
echo ============================================================
echo.
echo                 Discord Instance Dashboard
echo.
echo ============================================================
echo.
set "instance_count=0"
for /d %%i in ("%PROFILES_BASE_PATH%\*") do (
    set /a instance_count+=1
    set "INSTANCE_!instance_count!=%%~ni"
    echo   [!instance_count!] %%~ni
)

if %instance_count% equ 0 (
    echo No instances found. You can create one.
)
echo.
echo ------------------------------------------------------------
echo.
echo   [C] Create New Instance     [Q] Quit
echo.
echo ============================================================
set "choice="
set /p "choice=Enter an instance number, or select an action: "

if /i "%choice%"=="q" exit /b
if /i "%choice%"=="c" goto create_instance
if "%choice%"=="" goto main_loop

rem -- Validate if input is a valid number --
set "selected_instance_name="
if %choice% gtr 0 if %choice% leq %instance_count% (
    set "selected_instance_name=!INSTANCE_%choice%!"
    goto instance_action_menu
)

echo Invalid input.
pause
goto main_loop

:: =================================================================================
:: Instance Action Menu
:: =================================================================================
:instance_action_menu
if "%selected_instance_name%"=="" goto main_loop
cls
set "INSTANCE_PATH=%PROFILES_BASE_PATH%\%selected_instance_name%"
call :check_devtools_status "%INSTANCE_PATH%"

echo ============================================================
echo.
echo              Actions for Instance: %selected_instance_name%
echo ------------------------------------------------------------
echo   Path: %INSTANCE_PATH%
echo   DevTools: !DEVTOOLS_STATUS!
echo.
echo ============================================================
echo.
echo   [L] Launch   [M] Modify Name   [T] Toggle DevTools   [D] Delete
echo.
echo   [B] Back to Main List
echo.
echo ============================================================
set "action_choice="
set /p "action_choice=Select an action: "

if /i "%action_choice%"=="b" goto main_loop
if /i "%action_choice%"=="l" (
    call :action_launch "%INSTANCE_PATH%" "%selected_instance_name%"
    pause
    goto instance_action_menu
)
if /i "%action_choice%"=="m" (
    call :action_rename
    goto main_loop
)
if /i "%action_choice%"=="t" (
    call :action_toggle_devtools "%INSTANCE_PATH%"
    pause
    goto instance_action_menu
)
if /i "%action_choice%"=="d" (
    call :action_delete
    goto main_loop
)
if "%action_choice%"=="" goto instance_action_menu

echo Invalid action.
pause
goto instance_action_menu

:: =================================================================================
:: Create Instance (Standalone Function)
:: =================================================================================
:create_instance
cls
echo ==================== Create New Instance ===================
echo.
set "new_instance_name="
set /p "new_instance_name=Enter a name for the new instance (or press Enter to cancel): "
if "%new_instance_name%"=="" goto main_loop
if exist "%PROFILES_BASE_PATH%\%new_instance_name%" (
    echo Instance '%new_instance_name%' already exists.
    pause
    goto create_instance
)
mkdir "%PROFILES_BASE_PATH%\%new_instance_name%"
echo. & echo Instance '%new_instance_name%' created successfully. & echo.
:ask_devtools
set "dev_choice="
set /p "dev_choice=Enable Developer Tools for this instance? (y/n): "
if /i "%dev_choice%"=="y" ( call :enable_devtools "%PROFILES_BASE_PATH%\%new_instance_name%" )
if /i "%dev_choice%"=="n" ( echo DevTools will not be enabled. )
if /i not "%dev_choice%"=="y" if /i not "%dev_choice%"=="n" (
    echo Invalid input. & goto ask_devtools
)
echo. & pause
goto main_loop

:: =================================================================================
:: Subroutines: Instance Actions
:: =================================================================================
:action_launch
set "INSTANCE_PATH_ARG=%~1"
set "INSTANCE_NAME_ARG=%~2"
echo. & echo Launching instance '%INSTANCE_NAME_ARG%'...
setlocal
set "DISCORD_USER_DATA_DIR=%INSTANCE_PATH_ARG%"
start "" "%DISCORD_LAUNCH_EXE%" --processStart Discord.exe --process-start-args "--multi-instance"
endlocal
echo Instance launched.
goto :eof

:action_rename
cls
echo --- Rename Instance ---
echo Current name: %selected_instance_name%
echo.
set "new_name="
set /p "new_name=Enter the new name (or press Enter to cancel): "
if "%new_name%"=="" goto :eof
if exist "%PROFILES_BASE_PATH%\%new_name%" (
    echo An instance named '%new_name%' already exists. & pause
    goto action_rename
)
ren "%PROFILES_BASE_PATH%\%selected_instance_name%" "%new_name%"
echo Instance has been renamed to '%new_name%'. & pause
goto :eof

:action_toggle_devtools
if /i "!DEVTOOLS_STATUS!"=="Enabled" ( call :disable_devtools "%~1" ) else ( call :enable_devtools "%~1" )
goto :eof

:action_delete
echo.
set "confirm="
set /p "confirm=WARNING: This will permanently delete all data for '%selected_instance_name%'. Are you sure? (y/n): "
if /i not "%confirm%"=="y" ( echo Deletion cancelled. & pause & goto :eof )

echo. & echo Checking for running Discord processes...
tasklist | findstr /i "discord.exe" >nul
if %errorlevel% equ 0 (
    echo Discord is currently running in the background.
    set "kill_choice="
    set /p "kill_choice=To ensure deletion succeeds, it must be closed. Force kill all Discord processes? (y/n): "
    if /i "%kill_choice%"=="y" (
        echo Killing Discord processes...
        taskkill /F /IM discord.exe /T >nul
        echo Waiting a moment for processes to release files...
        timeout /t 2 /nobreak >nul
    ) else (
        echo Deletion cancelled. Please close Discord manually and try again.
        pause
        goto :eof
    )
)

echo Deleting instance '%selected_instance_name%'...
rmdir /s /q "%PROFILES_BASE_PATH%\%selected_instance_name%"
echo Instance deleted successfully. & pause
goto :eof

:: =================================================================================
:: Helper Subroutines
:: =================================================================================
:check_devtools_status
set "SETTINGS_FILE=%~1\Discord\settings.json"
set "DEVTOOLS_STATUS=Disabled"
if not exist "%SETTINGS_FILE%" goto :eof
findstr /C:"\"DANGEROUS_ENABLE_DEVTOOLS_ONLY_ENABLE_IF_YOU_KNOW_WHAT_YOURE_DOING\": true" "%SETTINGS_FILE%" >nul && set "DEVTOOLS_STATUS=Enabled"
goto :eof

:enable_devtools
set "DISCORD_SETTINGS_FOLDER=%~1\Discord"
echo. & echo Enabling Developer Tools...
if not exist "%DISCORD_SETTINGS_FOLDER%" mkdir "%DISCORD_SETTINGS_FOLDER%"
> "%DISCORD_SETTINGS_FOLDER%\settings.json" (
    echo {
    echo   "DANGEROUS_ENABLE_DEVTOOLS_ONLY_ENABLE_IF_YOU_KNOW_WHAT_YOURE_DOING": true
    echo }
)
echo Developer Tools have been enabled.
goto :eof

:disable_devtools
set "SETTINGS_FILE=%~1\Discord\settings.json"
echo. & echo Disabling Developer Tools...
if exist "%SETTINGS_FILE%" ( del "%SETTINGS_FILE%" & echo Developer Tools have been disabled. ) else ( echo Developer Tools were already disabled. )
goto :eof