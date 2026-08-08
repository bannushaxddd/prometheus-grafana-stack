# Generate sample traffic against the demo app so Grafana charts fill with data.
# Usage: .\scripts\generate-load.ps1 [-Requests 50] [-BaseUrl http://localhost:8080]

param(
    [int]$Requests = 50,
    [string]$BaseUrl = "http://localhost:8080"
)

Write-Host "Sending $Requests requests to $BaseUrl ..." -ForegroundColor Cyan

$success = 0
$fail = 0

1..$Requests | ForEach-Object {
    $amount = [math]::Round((Get-Random -Minimum 5 -Maximum 200) + (Get-Random) / [int]::MaxValue, 2)
    try {
        $null = Invoke-RestMethod -Method Post -Uri "$BaseUrl/api/orders" `
            -ContentType "application/json" `
            -Body (@{ amount = $amount } | ConvertTo-Json) `
            -TimeoutSec 10
        $success++
    } catch {
        $fail++
    }

    try { Invoke-RestMethod -Uri "$BaseUrl/api/cache" -TimeoutSec 5 | Out-Null } catch {}

    if ($_ % 10 -eq 0) {
        try { Invoke-RestMethod -Uri "$BaseUrl/api/slow" -TimeoutSec 15 | Out-Null } catch {}
        Write-Host "  progress: $_ / $Requests (ok=$success fail=$fail)"
    }

    Start-Sleep -Milliseconds (Get-Random -Minimum 50 -Maximum 200)
}

Write-Host "Done. success=$success fail=$fail" -ForegroundColor Green
Write-Host "Open Grafana: http://localhost:3001  (admin / admin123)" -ForegroundColor Yellow
