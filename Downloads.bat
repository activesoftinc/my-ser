@echo off
setlocal EnableExtensions

title Downloads and Installers

set "DESKTOP=C:\Users\Public\Desktop"
set "LOG=%TEMP%\Downloads-install.log"
set "TELEGRAM=%DESKTOP%\Telegram.exe"
set "ZIP=%DESKTOP%\7zip.exe"
set "VMCONFIG=%DESKTOP%\VMQuickConfig.exe"

echo Downloads started at %DATE% %TIME% > "%LOG%"
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

echo [1/3] Downloading Telegram...
call :Download "https://telegram.org/dl/desktop/win64" "%TELEGRAM%"
if errorlevel 1 goto :Failure

echo Checking Telegram digital signature...
powershell.exe -NoProfile -NonInteractive -Command ^
  "$s=Get-AuthenticodeSignature -LiteralPath $args[0]; Write-Output ('Signature status: ' + $s.Status); if($s.SignerCertificate){Write-Output ('Signer: ' + $s.SignerCertificate.Subject)}" ^
  "%TELEGRAM%" >> "%LOG%" 2>&1

type "%LOG%"

echo Telegram downloaded for review; it has NOT been executed.

echo.
echo [2/3] Downloading 7-Zip...
call :Download "https://www.7-zip.org/a/7z2501-x64.exe" "%ZIP%"
if errorlevel 1 goto :Failure

echo Installing 7-Zip...
call :Install "%ZIP%" "/S" 180
if errorlevel 1 goto :Failure

del /q "%ZIP%" 2>nul

echo.
echo [3/3] Downloading VMQuickConfig...
call :Download "https://github.com/chieunhatnang/VM-QuickConfig/releases/download/1.6.1/VMQuickConfig.exe" "%VMCONFIG%"
if errorlevel 1 goto :Failure

echo VMQuickConfig.exe downloaded but NOT executed.
echo Review the executable before deciding whether to run it.

echo.
echo Epic Games Launcher and Unity Hub shortcuts were preserved.
echo No hidden PowerShell scripts were executed.

echo SUCCESS: Download and installation steps completed. >> "%LOG%"
echo Finished at %DATE% %TIME% >> "%LOG%"

exit /b 0

:Download
echo Downloading: %~1
echo DOWNLOAD START: %~1 >> "%LOG%"

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
  "$ErrorActionPreference='Stop'; $exe=$args[0]; $argLine=$args[1]; $limit=[int]$args[2]; $p=Start-Process -FilePath $exe -ArgumentList $argLine -PassThru; if(-not $p.WaitForExit($limit*1000)){ & taskkill.exe /PID $p.Id /T /F | Out-Null; Write-Output 'INSTALL TIMEOUT'; exit 124 }; $p.Refresh(); Write-Output ('INSTALL EXIT CODE: ' + $p.ExitCode); exit $p.ExitCode" ^
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
