@echo off
chcp 65001 > nul
setlocal enabledelayedexpansion

:: =================================================================================
:: Discord 多開管理器 v4.4 (管理員權限檢查) - 中文版
:: =================================================================================
:: 新功能:
:: - 腳本啟動時會自動檢查管理員權限，如果沒有，則會提示使用者並以管理員身分重新開啟。
:: =================================================================================

:: ---------------------------------------------------------------------------------
:: 管理員權限檢查
:: ---------------------------------------------------------------------------------
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo 正在請求管理員權限...
    powershell -Command "Start-Process -FilePath '%~dpnx0' -Verb RunAs" >nul
    exit
)
:: ---------------------------------------------------------------------------------

:: --- 環境變數設定 ---
set "DISCORD_LAUNCH_EXE=%LOCALAPPDATA%\Discord\Update.exe"
set "PROFILES_BASE_PATH=%LOCALAPPDATA%\Discord\profiles"

:: --- 初始化 ---
if not exist "%PROFILES_BASE_PATH%" (
    echo 正在建立實例設定檔目錄...
    mkdir "%PROFILES_BASE_PATH%"
)

:: =================================================================================
:: 主迴圈 (顯示實例列表)
:: =================================================================================
:main_loop
cls
echo ============================================================
echo.
echo                   Discord 實例儀表板
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
    echo 找不到任何實例。您可以建立一個新的。
)
echo.
echo ------------------------------------------------------------
echo.
echo   [C] 建立新實例          [Q] 離開
echo.
echo ============================================================
set "choice="
set /p "choice=請輸入實例編號，或選擇一個操作: "

if /i "%choice%"=="q" exit /b
if /i "%choice%"=="c" goto create_instance
if "%choice%"=="" goto main_loop

rem -- 檢查輸入是否為有效的數字 --
set "selected_instance_name="
if %choice% gtr 0 if %choice% leq %instance_count% (
    set "selected_instance_name=!INSTANCE_%choice%!"
    goto instance_action_menu
)

echo 無效的輸入。
pause
goto main_loop

:: =================================================================================
:: 實例操作選單
:: =================================================================================
:instance_action_menu
if "%selected_instance_name%"=="" goto main_loop
cls
set "INSTANCE_PATH=%PROFILES_BASE_PATH%\%selected_instance_name%"
call :check_devtools_status "%INSTANCE_PATH%"

set "STATUS_DISPLAY=已停用"
if /i "!DEVTOOLS_STATUS!"=="Enabled" set "STATUS_DISPLAY=已啟用"

echo ============================================================
echo.
echo              操作實例: %selected_instance_name%
echo ------------------------------------------------------------
echo   路徑: %INSTANCE_PATH%
echo   開發者工具: !STATUS_DISPLAY!
echo.
echo ============================================================
echo.
echo   [L] 啟動   [M] 改名   [T] 切換Dev   [D] 刪除   [F] 開啟資料夾
echo.
echo   [B] 返回主列表
echo.
echo ============================================================
set "action_choice="
set /p "action_choice=請選擇要執行的操作: "

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
if /i "%action_choice%"=="f" (
    call :action_open_folder "%INSTANCE_PATH%"
    pause
    goto instance_action_menu
)
if "%action_choice%"=="" goto instance_action_menu

echo 無效的操作。
pause
goto instance_action_menu

:: =================================================================================
:: 建立實例 (獨立功能)
:: =================================================================================
:create_instance
cls
echo ===================== 建立新的實例 =====================
echo.
set "new_instance_name="
set /p "new_instance_name=請為新實例輸入一個名稱 (或直接按 Enter 取消): "
if "%new_instance_name%"=="" goto main_loop
if exist "%PROFILES_BASE_PATH%\%new_instance_name%" (
    echo 名為 '%new_instance_name%' 的實例已存在。
    pause
    goto create_instance
)
mkdir "%PROFILES_BASE_PATH%\%new_instance_name%"
echo. & echo 實例 '%new_instance_name%' 已成功建立。 & echo.
:ask_devtools
set "dev_choice="
set /p "dev_choice=是否要為此實例啟用開發者工具？ (y/n): "
if /i "%dev_choice%"=="y" ( call :enable_devtools "%PROFILES_BASE_PATH%\%new_instance_name%" )
if /i "%dev_choice%"=="n" ( echo 將不啟用開發者工具。 )
if /i not "%dev_choice%"=="y" if /i not "%dev_choice%"=="n" (
    echo 無效的輸入。 & goto ask_devtools
)
echo. & pause
goto main_loop

:: =================================================================================
:: 子程序: 實例操作
:: =================================================================================
:action_launch
set "INSTANCE_PATH_ARG=%~1"
set "INSTANCE_NAME_ARG=%~2"
echo. & echo 正在啟動實例 '%INSTANCE_NAME_ARG%'...
setlocal
set "DISCORD_USER_DATA_DIR=%INSTANCE_PATH_ARG%"
start "" "%DISCORD_LAUNCH_EXE%" --processStart Discord.exe --process-start-args "--multi-instance"
endlocal
echo 實例已啟動。
goto :eof

:action_rename
cls
echo --- 重新命名實例 ---
echo 目前名稱: %selected_instance_name%
echo.
set "new_name="
set /p "new_name=請輸入新名稱 (或直接按 Enter 取消): "
if "%new_name%"=="" goto :eof
if exist "%PROFILES_BASE_PATH%\%new_name%" (
    echo 名為 '%new_name%' 的實例已存在。 & pause
    goto action_rename
)
ren "%PROFILES_BASE_PATH%\%selected_instance_name%" "%new_name%"
echo 實例已重新命名為 '%new_name%'. & pause
goto :eof

:action_toggle_devtools
if /i "!DEVTOOLS_STATUS!"=="Enabled" ( call :disable_devtools "%~1" ) else ( call :enable_devtools "%~1" )
goto :eof

:action_delete
echo.
set "confirm="
set /p "confirm=警告: 這將永久刪除 '%selected_instance_name%' 的所有資料。您確定嗎？ (y/n): "
if /i not "%confirm%"=="y" ( echo 已取消刪除操作。 & pause & goto :eof )

echo. & echo 正在檢查 Discord 處理程序...
tasklist | findstr /i "discord.exe" >nul
if not %errorlevel% equ 0 goto :proceed_with_delete

echo 偵測到 Discord 正在背景執行。
set "kill_choice="
set /p "kill_choice=為了成功刪除，需要關閉它。是否要強制關閉所有 Discord 處理程序？ (y/n): "
if /i not "%kill_choice%"=="y" (
    echo 刪除已取消。請手動關閉 Discord 後再試一次。
    pause
    goto :eof
)

echo 正在強制關閉 Discord...
taskkill /F /IM discord.exe /T >nul
echo 等待處理程序釋放檔案...
timeout /t 2 /nobreak >nul

:proceed_with_delete
echo 正在刪除實例 '%selected_instance_name%'...
rmdir /s /q "%PROFILES_BASE_PATH%\%selected_instance_name%"
echo 實例已成功刪除。 & pause
goto :eof

:action_open_folder
echo. & echo 正在檔案總管中開啟資料夾...
explorer "%~1"
goto :eof

:: =================================================================================
:: 輔助子程序
:: =================================================================================
:check_devtools_status
set "SETTINGS_FILE=%~1\Discord\settings.json"
set "DEVTOOLS_STATUS=Disabled"
if not exist "%SETTINGS_FILE%" goto :eof
findstr /C:"\"DANGEROUS_ENABLE_DEVTOOLS_ONLY_ENABLE_IF_YOU_KNOW_WHAT_YOURE_DOING\": true" "%SETTINGS_FILE%" >nul && set "DEVTOOLS_STATUS=Enabled"
goto :eof

:enable_devtools
set "DISCORD_SETTINGS_FOLDER=%~1\Discord"
echo. & echo 正在啟用開發者工具...
if not exist "%DISCORD_SETTINGS_FOLDER%" mkdir "%DISCORD_SETTINGS_FOLDER%"
> "%DISCORD_SETTINGS_FOLDER%\settings.json" (
    echo {
    echo   "DANGEROUS_ENABLE_DEVTOOLS_ONLY_ENABLE_IF_YOU_KNOW_WHAT_YOURE_DOING": true
    echo }
)
echo 開發者工具已啟用。
goto :eof

:disable_devtools
set "SETTINGS_FILE=%~1\Discord\settings.json"
echo. & echo 正在關閉開發者工具...
if exist "%SETTINGS_FILE%" ( del "%SETTINGS_FILE%" & echo 開發者工具已關閉。 ) else ( echo 開發者工具本來就未啟用。 )
goto :eof