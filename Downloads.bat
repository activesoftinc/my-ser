
@echo off
setlocal EnableExtensions

title Downloads and Installers
set "DESKTOP=C:\Users\Public\Desktop"
set "LOG=%TEMP%\Downloads-install.log"

echo ================================================== > "%LOG%"
echo Downloads.bat started at %DATE% %TIME% >> "%LOG%"
echo ================================================== >> "%LOG%"

echo Current user: %USERNAME%
echo Log file: %LOG%

if not exist "%DESKTOP%" (
    mkdir "%DESKTOP%" 2>nul
)

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
echo [1/5] Downloading Telegram...
call :Download "https://telegram.org/dl/desktop/win64" "%DESKTOP%\Telegram.exe"
if errorlevel 1 goto :Failure

echo.
echo [2/5] Downloading 7-Zip...
call :Download "https://www.7-zip.org/a/7z2501-x64.exe" "%DESKTOP%\7zip.exe"
if errorlevel 1 goto :Failure

echo.
echo [3/5] Downloading VMQuickConfig...
call :Download "https://github.com/chieunhatnang/VM-QuickConfig/releases/download/1.6.1/VMQuickConfig.exe" "%DESKTOP%\VMQuickConfig.exe"
if errorlevel 1 goto :Failure

echo.
echo [4/5] Installing Telegram...
call :Install "%DESKTOP%\Telegram.exe" "/VERYSILENT /NORESTART" 180
if errorlevel 1 goto :Failure

del /q "%DESKTOP%\Telegram.exe" 2>nul

echo.
echo [5/5] Installing 7-Zip...
call :Install "%DESKTOP%\7zip.exe" "/S" 180
if errorlevel 1 goto :Failure

del /q "%DESKTOP%\7zip.exe" 2>nul

echo.
echo VMQuickConfig.exe was downloaded but NOT executed.
echo Review it before deciding whether to run it.
echo.

echo SUCCESS: All requested download and installer steps completed. >> "%LOG%"
echo Finished at %DATE% %TIME% >> "%LOG%"
echo Log: %LOG%

exit /b 0


:Download
echo Downloading: %~1
echo [%DATE% %TIME%] DOWNLOAD %~1 >> "%LOG%"

curl.exe --fail --location --show-error --silent ^
    --connect-timeout 15 --max-time 120 ^
    --output "%~2" "%~1" >> "%LOG%" 2>&1

if errorlevel 1 (
    echo ERROR: Download failed: %~1
    echo DOWNLOAD FAILED: %~1 >> "%LOG%"
    del /q "%~2" 2>nul
    exit /b 1
)

if not exist "%~2" (
    echo ERROR: Downloaded file is missing.
    exit /b 1
)

for %%F in ("%~2") do set "FILESIZE=%%~zF"

if "%FILESIZE%"=="0" (
    echo ERROR: Downloaded file is empty.
    exit /b 1
)

echo Download successful: %~2 (%FILESIZE% bytes)
echo DOWNLOAD OK: %~2 (%FILESIZE% bytes) >> "%LOG%"
exit /b 0


:Install
echo Starting installer: %~1
echo INSTALL START: %~1 >> "%LOG%"

powershell.exe -NoProfile -NonInteractive -Command ^
  "$ErrorActionPreference='Stop'; $exe=$args[0]; $argLine=$args[1]; $limit=[int]$args[2]; $p=Start-Process -FilePath $exe -ArgumentList $argLine -PassThru; if(-not $p.WaitForExit($limit*1000)){ Write-Output 'INSTALL TIMEOUT'; & taskkill.exe /PID $p.Id /T /F 2>&1 | Out-String | Write-Output; exit 124 }; $p.Refresh(); Write-Output ('INSTALL EXIT CODE: ' + $p.ExitCode); exit $p.ExitCode" ^
  "%~1" "%~2" "%~3" >> "%LOG%" 2>&1

set "INSTALL_RESULT=%ERRORLEVEL%"
echo Installer exit code: %INSTALL_RESULT%
echo INSTALL RESULT: %~1 exit=%INSTALL_RESULT% >> "%LOG%"

if not "%INSTALL_RESULT%"=="0" (
    echo ERROR: Installer failed or timed out.
    exit /b 1
)

exit /b 0


:Failure
echo.
echo ERROR: A download or installation step failed.
echo Check the log at: %LOG%
echo FAILED at %DATE% %TIME% >> "%LOG%"
exit /b 1
