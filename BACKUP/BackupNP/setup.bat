@echo off
setlocal enabledelayedexpansion

echo Reading configuration from task_config.ini...

:: Read DAY configuration
for /f "tokens=2 delims==" %%a in ('findstr "^DAY=" "%~dp0task_config.ini"') do set CONFIG_DAY=%%a
for /f "tokens=2 delims==" %%a in ('findstr "^INTERVAL=" "%~dp0task_config.ini"') do set TASK_INTERVAL=%%a

:: Initialize variables
set KILLPROCESS_TIME=
set RESTART_TIME=
set IN_KILLPROCESS=0
set IN_RESTART=0

:: Read configuration line by line
for /f "usebackq delims=" %%a in ("%~dp0task_config.ini") do (
  set "line=%%a"
  
  if "!line!"=="[KILLPROCESS_TASK]" (
    set IN_KILLPROCESS=1
    set IN_RESTART=0
    ) else if "!line!"=="[RESTART_TASK]" (
    set IN_KILLPROCESS=0
    set IN_RESTART=1
    ) else if "!line:~0,5!"=="TIME=" (
    if !IN_KILLPROCESS!==1 (
      for /f "tokens=2 delims==" %%b in ("!line!") do set KILLPROCESS_TIME=%%b
      ) else if !IN_RESTART!==1 (
      for /f "tokens=2 delims==" %%b in ("!line!") do set RESTART_TIME=%%b
    )
  )
)

:display_config
echo Configuration loaded:
echo - Day: !CONFIG_DAY!
echo - KillProcess Time: !KILLPROCESS_TIME!
echo - Restart Time: !RESTART_TIME!
echo.

:: Validate that we have all required values
if not defined CONFIG_DAY (
  echo ERROR: DAY configuration not found in task_config.ini
  pause
  exit /b 1
)

if not defined TASK_INTERVAL (
  echo ERROR: INTERVAL configuration not found in task_config.ini
  pause
  exit /b 1
)

if not defined KILLPROCESS_TIME (
  echo ERROR: KILLPROCESS_TASK TIME not found in task_config.ini
  pause
  exit /b 1
)

if not defined RESTART_TIME (
  echo ERROR: RESTART_TASK TIME not found in task_config.ini
  pause
  exit /b 1
)

echo Creating C:\Scripts directory if it doesn't exist...
if not exist "C:\Scripts" mkdir "C:\Scripts"

echo Copying KillProcesses.ps1 script to C:\Scripts\...
copy "%~dp0scripts\KillProcesses.ps1" "C:\Scripts\KillProcesses.ps1"
if %errorlevel% equ 0 (
  echo KillProcesses.ps1 copied successfully to C:\Scripts\
  ) else (
  echo Failed to copy KillProcesses.ps1
)

echo Copying RestartPC.ps1 script to C:\Scripts\...
copy "%~dp0scripts\RestartPC.ps1" "C:\Scripts\RestartPC.ps1"
if %errorlevel% equ 0 (
  echo RestartPC.ps1 copied successfully to C:\Scripts\
  ) else (
  echo Failed to copy RestartPC.ps1
)

if "%TASK_INTERVAL%"=="daily" (
  
  echo Creating scheduled task "KillProcesses" to run daily at !KILLPROCESS_TIME!...
  schtasks /create /tn "KillProcesses" /tr "powershell.exe -ExecutionPolicy Bypass -File C:\Scripts\KillProcesses.ps1" /sc daily /st !KILLPROCESS_TIME! /f
  echo Creating scheduled task "RestartPC" to run daily at !RESTART_TIME!...
  schtasks /create /tn "RestartPC" /tr "powershell.exe -ExecutionPolicy Bypass -File C:\Scripts\RestartPC.ps1" /sc daily /st !RESTART_TIME! /f
  
  ) else if "%TASK_INTERVAL%"=="weekly" (
  
  echo Creating scheduled task to run KillProcesses every !CONFIG_DAY! at !KILLPROCESS_TIME!...
  schtasks /create /tn "KillProcesses" /tr "powershell.exe -ExecutionPolicy Bypass -File C:\Scripts\KillProcesses.ps1" /sc weekly /d !CONFIG_DAY! /st !KILLPROCESS_TIME! /f
  echo Creating scheduled task to restart PC every !CONFIG_DAY! at !RESTART_TIME!...
  schtasks /create /tn "RestartPC" /tr "powershell.exe -ExecutionPolicy Bypass -File C:\Scripts\RestartPC.ps1" /sc weekly /d !CONFIG_DAY! /st !RESTART_TIME! /f
  
  ) else if "%TASK_INTERVAL%"=="monthly" (
  
  echo Creating scheduled task "KillProcesses" to run on the 1st of every month at !KILLPROCESS_TIME!...
  schtasks /create ^
  /sc monthly ^
  /mo 1 ^
  /tn "KillProcesses" ^
  /tr "powershell.exe -ExecutionPolicy Bypass -File C:\Scripts\KillProcesses.ps1" ^
  /st !KILLPROCESS_TIME! ^
  /f
  
  echo Creating scheduled task "RestartPC" to run on the 1st of every month at !RESTART_TIME!...
  schtasks /create ^
  /sc monthly ^
  /mo 1 ^
  /tn "RestartPC" ^
  /tr "powershell.exe -ExecutionPolicy Bypass -File C:\Scripts\RestartPC.ps1" ^
  /st !RESTART_TIME! ^
  /f
  
  
  ) else (
  echo Invalid INTERVAL specified in task_config.ini. Please use daily, weekly, or monthly.
  goto :end
)

echo Scheduled tasks created successfully!
if "%TASK_INTERVAL%"=="daily" (
  echo - KillProcesses will run daily at !KILLPROCESS_TIME!
  echo - RestartPC will run daily at !RESTART_TIME!
  ) else if "%TASK_INTERVAL%"=="weekly" (
  echo - KillProcesses will run every !CONFIG_DAY! at !KILLPROCESS_TIME!
  echo - RestartPC will run every !CONFIG_DAY! at !RESTART_TIME!
  ) else if "%TASK_INTERVAL%"=="monthly" (
  echo - KillProcesses will run on day 1 of every month at !KILLPROCESS_TIME!
  echo - RestartPC will run on day 1 of every month at !RESTART_TIME!
)
pause
