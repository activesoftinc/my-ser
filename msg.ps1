$hours = 6

for ($i = $hours; $i -gt 1; $i--) {
    msg RDP "Welcome to your Remote Desktop. You have $i hours remaining."
    Start-Sleep -Seconds 3600
}

Start-Sleep -Seconds 1800

msg RDP "⚠️ WARNING: Your Remote Desktop session will close in 15 minutes!"
Start-Sleep -Seconds 900