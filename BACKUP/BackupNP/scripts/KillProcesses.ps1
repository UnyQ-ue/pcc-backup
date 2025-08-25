Write-Host "Terminating twin.exe..." -ForegroundColor Yellow
try {
    Stop-Process -Name "twin" -Force -ErrorAction SilentlyContinue
    Write-Host "twin.exe terminated successfully" -ForegroundColor Green
} catch {
    Write-Host "twin.exe was not running or could not be terminated" -ForegroundColor Gray
}

Write-Host ""

Write-Host "Terminating elerechnung.exe..." -ForegroundColor Yellow
try {
    Stop-Process -Name "elerechnung" -Force -ErrorAction SilentlyContinue
    Write-Host "elerechnung.exe terminated successfully" -ForegroundColor Green
} catch {
    Write-Host "elerechnung.exe was not running or could not be terminated" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Task termination complete." -ForegroundColor Cyan


