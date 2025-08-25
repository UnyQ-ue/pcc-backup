Write-Host "Restarting PC in 30 seconds..." -ForegroundColor Red
Write-Host "Press Ctrl+C to cancel" -ForegroundColor Yellow
Write-Host ""

try {
    # Countdown from 30 to 1
    for ($i = 30; $i -gt 0; $i--) {
        Write-Host "Restarting in $i seconds..." -ForegroundColor Cyan
        Start-Sleep -Seconds 1
    }
    
    Write-Host "Restarting now..." -ForegroundColor Red
    Restart-Computer -Force
} catch {
    Write-Host "Restart cancelled by user." -ForegroundColor Green
}


