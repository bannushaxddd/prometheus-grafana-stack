# Quick health check of the monitoring stack
$ErrorActionPreference = "Continue"
Write-Host "=== docker compose ps ===" -ForegroundColor Cyan
docker compose ps

$checks = @(
    @{ Name = "Grafana";     Url = "http://localhost:3001/api/health" },
    @{ Name = "Prometheus";  Url = "http://localhost:9090/-/ready" },
    @{ Name = "App";         Url = "http://localhost:3000/health" },
    @{ Name = "Alertmanager";Url = "http://localhost:9093/-/ready" },
    @{ Name = "Alert logger";Url = "http://localhost:9999/health" },
    @{ Name = "Loki";        Url = "http://localhost:3100/ready" }
)

Write-Host "`n=== HTTP checks ===" -ForegroundColor Cyan
foreach ($c in $checks) {
    try {
        $null = Invoke-WebRequest -Uri $c.Url -UseBasicParsing -TimeoutSec 5
        Write-Host ("  {0,-14} OK  {1}" -f $c.Name, $c.Url) -ForegroundColor Green
    } catch {
        Write-Host ("  {0,-14} FAIL {1}" -f $c.Name, $c.Url) -ForegroundColor Red
    }
}

try {
    $t = Invoke-RestMethod "http://localhost:9090/api/v1/targets"
    $active = $t.data.activeTargets
    $up = ($active | Where-Object { $_.health -eq "up" }).Count
    $down = ($active | Where-Object { $_.health -ne "up" }).Count
    Write-Host "`n=== Prometheus targets: $up up / $down down / $($active.Count) total ===" -ForegroundColor Cyan
    $active | ForEach-Object {
        $color = if ($_.health -eq "up") { "Green" } else { "Red" }
        Write-Host ("  [{0}] {1,-16} {2}" -f $_.health.ToUpper(), $_.labels.job, $_.labels.instance) -ForegroundColor $color
    }
} catch {
    Write-Host "Could not query Prometheus targets" -ForegroundColor Yellow
}
