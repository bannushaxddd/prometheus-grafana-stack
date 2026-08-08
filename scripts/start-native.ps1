# Minimal stack without Docker: Node demo app + local prometheus.exe
# Grafana/Alertmanager/Loki still require Docker (docker compose up -d)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

Write-Host "==> Installing app dependencies" -ForegroundColor Cyan
Push-Location "$root\app"
if (-not (Test-Path node_modules)) { npm install }
Pop-Location

Write-Host "==> Starting demo app on :3000" -ForegroundColor Cyan
$app = Start-Process -FilePath "node" -ArgumentList "server.js" -WorkingDirectory "$root\app" -PassThru -WindowStyle Minimized
Write-Host "    PID $($app.Id)"

Start-Sleep -Seconds 2

Write-Host "==> Starting Prometheus on :9090" -ForegroundColor Cyan
$promArgs = @(
  "--config.file=prometheus/prometheus.native.yml",
  "--storage.tsdb.path=data",
  "--storage.tsdb.retention.time=15d",
  "--web.enable-lifecycle"
)
$prom = Start-Process -FilePath "$root\prometheus.exe" -ArgumentList $promArgs -WorkingDirectory $root -PassThru -WindowStyle Minimized
Write-Host "    PID $($prom.Id)"

Write-Host ""
Write-Host "App metrics:  http://localhost:3000/metrics" -ForegroundColor Green
Write-Host "Prometheus:   http://localhost:9090" -ForegroundColor Green
Write-Host "Targets:      http://localhost:9090/targets" -ForegroundColor Green
Write-Host ""
Write-Host "For full stack (Grafana, exporters, Loki): start Docker Desktop, then:" -ForegroundColor Yellow
Write-Host "  docker compose up -d --build"
Write-Host ""
Write-Host "PIDs written for stop-native.ps1"
@{ app = $app.Id; prometheus = $prom.Id } | ConvertTo-Json | Set-Content "$root\scripts\.native-pids.json"
