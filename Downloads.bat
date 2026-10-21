
@echo off
setlocal EnableExtensions

title Downloads and Installers

set "DESKTOP=C:\Users\Public\Desktop"
set "LOG=%TEMP%\Downloads-install.log"
set "ZIP=%DESKTOP%\7zip.exe"
set "VMCONFIG=%DESKTOP%\VMQuickConfig.exe"

echo ================================================== > "%LOG%"
echo Downloads started at %DATE% %TIME% >> "%LOG%"
echo ================================================== >> "%LOG%"

echo Current user: %USERNAME%
echo Log file: %LOG%

if not exist "%DESKTOP%" mkdir "%DESKTOP%" 2>nul

if not exist "%DESKTOP%" (
    echo ERROR: Desktop directory is unavailable.
    exit /b 1
)

where curl.exe >nul 2>&1
if errorlevel 1 (
    echo ERROR: curl.exe is unavailable.
    exit /b 1
)

echo.
echo [1/2] Downloading 7-Zip...

call :Download ^
    "https://www.7-zip.org/a/7z2501-x64.exe" ^
    "%ZIP%"

if errorlevel 1 goto :Failure

echo.
echo [2/2] Downloading VMQuickConfig...

call :Download ^
    "https://github.com/chieunhatnang/VM-QuickConfig/releases/download/1.6.1/VMQuickConfig.exe" ^
    "%VMCONFIG%"

if errorlevel 1 goto :Failure

echo.
echo Installing 7-Zip...

call :Install "%ZIP%" "/S" 180

if errorlevel 1 goto :Failure

del /q "%ZIP%" 2>nul

echo.
echo ==========================================
echo Installation and download steps completed.
echo ==========================================

echo VMQuickConfig.exe was downloaded but NOT executed.
echo Review it before deciding whether to run it.

echo Epic Games Launcher and Unity Hub shortcuts were preserved.
echo No Telegram download or installation was performed.
echo No hidden PowerShell scripts were executed.

echo SUCCESS: Tasks completed at %DATE% %TIME% >> "%LOG%"

echo.
echo Log file: %LOG%

exit /b 0


:Download
echo Downloading: %~1
echo DOWNLOAD START: %~1 >> "%LOG%"

set "DOWNLOAD_ATTEMPT=1"

:DownloadRetry
echo Attempt %DOWNLOAD_ATTEMPT% of 3...

if exist "%~2" del /q "%~2" 2>nul

curl.exe --fail --location --show-error --silent ^
    --connect-timeout 20 ^
    --max-time 240 ^
    --retry 2 ^
    --retry-delay 3 ^
    --output "%~2" "%~1" >> "%LOG%" 2>&1

if errorlevel 1 goto :DownloadFailed

if not exist "%~2" goto :DownloadFailed

set "FILESIZE=0"

for %%F in ("%~2") do set "FILESIZE=%%~zF"

if "%FILESIZE%"=="0" goto :DownloadFailed

echo Download successful: %~2 (%FILESIZE% bytes)
echo DOWNLOAD OK: %~2 (%FILESIZE% bytes) >> "%LOG%"

exit /b 0


:DownloadFailed
echo Download attempt %DOWNLOAD_ATTEMPT% failed.
echo DOWNLOAD ATTEMPT FAILED: %~1 >> "%LOG%"

if exist "%~2" del /q "%~2" 2>nul

set /a DOWNLOAD_ATTEMPT+=1

if %DOWNLOAD_ATTEMPT% LEQ 3 (
    timeout /t 3 /nobreak >nul
    goto :DownloadRetry
)

echo ERROR: Download failed after 3 attempts.
echo DOWNLOAD FAILED: %~1 >> "%LOG%"

exit /b 1


:Install
echo Starting installer: %~1
echo INSTALL START: %~1 >> "%LOG%"

powershell.exe -NoProfile -NonInteractive -Command ^
  "$ErrorActionPreference='Stop'; $exe=$args[0]; $argLine=$args[1]; $limit=[int]$args[2]; $p=Start-Process -FilePath $exe -ArgumentList $argLine -PassThru; if(-not $p.WaitForExit($limit*1000)){ & taskkill.exe /PID $p.Id /T /F | Out-Null; Write-Output 'INSTALL TIMEOUT'; exit 124 }; $p.Refresh(); Write-Output ('INSTALL EXIT CODE: ' + $p.ExitCode); exit $p.ExitCode" ^
  "%~1" "%~2" "%~3" >> "%LOG%" 2>&1

set "INSTALL_RESULT=%ERRORLEVEL%"

echo Installer exit code: %INSTALL_RESULT%
echo INSTALL RESULT: %~1 exit=%INSTALL_RESULT% >> "%LOG%"

if not "%INSTALL_RESULT%"=="0" (
    echo ERROR: Installer failed or timed out.
    exit /b 1
)

echo Installer completed successfully.

exit /b 0


:Failure
echo.
echo ==========================================
echo ERROR: A download or installation failed.
echo ==========================================

echo Check the log file: %LOG%
echo FAILED at %DATE% %TIME% >> "%LOG%"

exit /b 1
