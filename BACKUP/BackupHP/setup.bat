@echo off
echo Setting up backup scripts...

REM MON, TUE, WED, THU, FRI, SAT, SUN
REM daily, weekly, monthly

REM Create the destination directories if they don't exist
if not exist "C:\Scripts" (
  echo Creating C:\Scripts directory...
  mkdir "C:\Scripts"
)

if not exist "C:\Scripts\Backup" (
  echo Creating C:\Scripts\Backup subdirectory...
  mkdir "C:\Scripts\Backup"
)

REM Copy all files from backup folder to C:\Scripts\Backup
echo Copying files from backup folder to C:\Scripts\Backup...
xcopy /Y /E "backup\*" "C:\Scripts\Backup\"

REM Check if copy was successful
if %errorlevel% equ 0 (
  echo Successfully copied files to C:\Scripts\Backup
  echo Files copied:
  dir "C:\Scripts\Backup"
  ) else (
  echo Error occurred during file copy
  goto :end
)

echo Reading configuration from task_config.ini...

REM Read the DAY value from [BACKUP_TASK] section
for /f "usebackq delims=" %%i in (`powershell -command "$content = Get-Content '%~dp0task_config.ini'; $backupSection = $false; foreach($line in $content) { if($line -eq '[BACKUP_TASK]') { $backupSection = $true } elseif($line -match '^\[.*\]$') { $backupSection = $false } elseif($backupSection -and $line -match '^DAY=(.*)$') { $matches[1]; break } }"`) do set TASK_DAY=%%i

REM Read INTERVAL value from [BACKUP_TASK] section
for /f "usebackq delims=" %%i in (`powershell -command "$content = Get-Content '%~dp0task_config.ini'; $backupSection = $false; foreach($line in $content) { if($line -eq '[BACKUP_TASK]') { $backupSection = $true } elseif($line -match '^\[.*\]$') { $backupSection = $false } elseif($backupSection -and $line -match '^INTERVAL=(.*)$') { $matches[1]; break } }"`) do set TASK_INTERVAL=%%i

REM Read backup task configuration
for /f "usebackq delims=" %%i in (`powershell -command "$content = Get-Content '%~dp0task_config.ini'; $backupSection = $false; foreach($line in $content) { if($line -eq '[BACKUP_TASK]') { $backupSection = $true } elseif($line -match '^\[.*\]$') { $backupSection = $false } elseif($backupSection -and $line -match '^NAME=(.*)$') { $matches[1]; break } }"`) do set BACKUP_NAME=%%i
for /f "usebackq delims=" %%i in (`powershell -command "$content = Get-Content '%~dp0task_config.ini'; $backupSection = $false; foreach($line in $content) { if($line -eq '[BACKUP_TASK]') { $backupSection = $true } elseif($line -match '^\[.*\]$') { $backupSection = $false } elseif($backupSection -and $line -match '^TIME=(.*)$') { $matches[1]; break } }"`) do set BACKUP_TIME=%%i

REM daily, weekly, monthly

if "%TASK_INTERVAL%"=="daily" (
  echo Creating scheduled task "%BACKUP_NAME%" to run daily at %BACKUP_TIME%...
  schtasks /create /tn "%BACKUP_NAME%" /tr "cmd /c cd /d C:\Scripts\Backup && backup.exe" /sc daily /st %BACKUP_TIME% /f
  ) else if "%TASK_INTERVAL%"=="weekly" (
  echo Creating scheduled task "%BACKUP_NAME%" to run every %TASK_DAY% at %BACKUP_TIME%...
  schtasks /create /tn "%BACKUP_NAME%" /tr "cmd /c cd /d C:\Scripts\Backup && backup.exe" /sc weekly /d %TASK_DAY% /st %BACKUP_TIME% /f
  ) else if "%TASK_INTERVAL%"=="monthly" (
  echo Creating scheduled task "%BACKUP_NAME%" to run on the %TASK_DAY% of every month at %BACKUP_TIME%...
  @echo off
  schtasks /create ^
  /sc monthly ^
  /d 1 ^
  /tn "%BACKUP_NAME%" ^
  /tr "cmd /c cd /d C:\Scripts\Backup && backup.exe" ^
  /st %BACKUP_TIME% ^
  /f
  ) else (
  echo Invalid INTERVAL specified in task_config.ini. Please use daily, weekly, or monthly.
  goto :end
)

REM Check if task creation was successful
if %errorlevel% equ 0 (
  echo Successfully created scheduled task "%BACKUP_NAME%"
  if "%TASK_INTERVAL%"=="daily" (
    echo Task will run daily at %BACKUP_TIME%
  ) else if "%TASK_INTERVAL%"=="weekly" (
    echo Task will run every %TASK_DAY% at %BACKUP_TIME%
  ) else if "%TASK_INTERVAL%"=="monthly" (
    echo Task will run on %TASK_DAY% of every month at %BACKUP_TIME%
  )
  echo Task details:
  schtasks /query /tn "%BACKUP_NAME%"
) else (
  echo Error occurred while creating scheduled task
  echo Please run this script as Administrator to create scheduled tasks
)


echo Füge Regel für ftp.exe zur Windows-Firewall hinzu...

netsh advfirewall firewall add rule name="FTP Allow Public" ^
    dir=in action=allow program="C:\Windows\System32\ftp.exe" enable=yes profile=public

echo Regel erfolgreich hinzugefügt.


:end
echo Setup complete!
pause
