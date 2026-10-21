
@echo off
setlocal EnableExtensions DisableDelayedExpansion

title Downloads and Installation

set "DESKTOP=C:\Users\Public\Desktop"
set "LOG=%TEMP%\Downloads-install.log"
set "ZIP=%DESKTOP%\7zip.exe"
set "VMCONFIG=%DESKTOP%\VMQuickConfig.exe"

echo.
echo ==========================================
echo   Downloads and Installation
echo ==========================================
echo Current user: %USERNAME%
echo Log file: %LOG%
echo.

> "%LOG%" echo ==================================================
>> "%LOG%" echo Downloads started at %DATE% %TIME%
>> "%LOG%" echo ==================================================

if not exist "%DESKTOP%\" (
    echo ERROR: Public Desktop folder not found.
    goto :Failure
)

where curl.exe >nul 2>&1
if errorlevel 1 (
    echo ERROR: curl.exe is not available.
    goto :Failure
)

echo [1/2] Downloading 7-Zip...
call :Download "https://www.7-zip.org/a/7z2501-x64.exe" "%ZIP%"
if errorlevel 1 goto :Failure

echo.
echo [2/2] Downloading VMQuickConfig...
call :Download "https://github.com/chieunhatnang/VM-QuickConfig/releases/download/1.6.1/VMQuickConfig.exe" "%VMCONFIG%"
if errorlevel 1 goto :Failure

echo.
echo Installing 7-Zip...
call :Install "%ZIP%" "/S" 180
if errorlevel 1 goto :Failure

echo.
echo ==========================================
echo   All requested steps completed.
echo ==========================================
echo 7-Zip installer completed successfully.
echo VMQuickConfig was downloaded but not executed.
echo Log file: %LOG%

>> "%LOG%" echo SUCCESS at %DATE% %TIME%
exit /b 0


:Download
set "DL_URL=%~1"
set "DL_FILE=%~2"
set "DL_ATTEMPT=0"

echo Downloading: %DL_URL%
>> "%LOG%" echo DOWNLOAD START: %DL_URL%

:DownloadRetry
set /a DL_ATTEMPT+=1

echo Attempt %DL_ATTEMPT% of 3...
>> "%LOG%" echo DOWNLOAD ATTEMPT: %DL_ATTEMPT%

if exist "%DL_FILE%" del /q "%DL_FILE%" >nul 2>&1

curl.exe --fail --location --show-error ^
    --connect-timeout 20 ^
    --max-time 240 ^
    --retry 2 ^
    --retry-delay 3 ^
    --output "%DL_FILE%" "%DL_URL%" >> "%LOG%" 2>&1

if not errorlevel 1 (
    if exist "%DL_FILE%" (
        for %%F in ("%DL_FILE%") do set "DL_SIZE=%%~zF"
        for %%F in ("%DL_FILE%") do echo Download successful: %%~fF (%%~zF bytes)
        >> "%LOG%" echo DOWNLOAD OK: %DL_FILE%
        exit /b 0
    )
)

echo Download attempt failed.
>> "%LOG%" echo DOWNLOAD FAILED: %DL_URL%

if exist "%DL_FILE%" del /q "%DL_FILE%" >nul 2>&1

if %DL_ATTEMPT% LSS 3 (
    timeout /t 3 /nobreak >nul
    goto :DownloadRetry
)

echo ERROR: Download failed after 3 attempts.
>> "%LOG%" echo DOWNLOAD ERROR: retries exhausted
exit /b 1


:Install
set "INSTALL_EXE=%~1"
set "INSTALL_ARGS=%~2"
set "INSTALL_TIMEOUT=%~3"

echo Starting installer: %INSTALL_EXE%
>> "%LOG%" echo INSTALL START: %INSTALL_EXE%

rem Pass values through environment variables to avoid PowerShell argument parsing issues.
set "INSTALL_EXE=%~1"
set "INSTALL_ARGS=%~2"
set "INSTALL_TIMEOUT=%~3"

powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $exe=$env:INSTALL_EXE; $argLine=$env:INSTALL_ARGS; $limit=[int]$env:INSTALL_TIMEOUT; $p=Start-Process -FilePath $exe -ArgumentList $argLine -PassThru; if(-not $p.WaitForExit($limit*1000)){ & taskkill.exe /PID $p.Id /T /F | Out-Null; Write-Output 'INSTALL TIMEOUT'; exit 124 }; $p.Refresh(); Write-Output ('INSTALL EXIT CODE: ' + $p.ExitCode); exit $p.ExitCode" >> "%LOG%" 2>&1

set "INSTALL_RC=%ERRORLEVEL%"
echo Installer exit code: %INSTALL_RC%
>> "%LOG%" echo INSTALL RESULT: %INSTALL_EXE% exit=%INSTALL_RC%

if not "%INSTALL_RC%"=="0" (
    echo ERROR: Installer failed or timed out.
    exit /b %INSTALL_RC%
)

echo Installer completed successfully.
exit /b 0


:Failure
echo.
echo ==========================================
echo ERROR: A download or installation failed.
echo ==========================================
echo Check the log file: %LOG%
if exist "%LOG%" (
    echo.
    echo ===== Installer log =====
    type "%LOG%"
)
>> "%LOG%" echo FAILED at %DATE% %TIME%
exit /b 1
