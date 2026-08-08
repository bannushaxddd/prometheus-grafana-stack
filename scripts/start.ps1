# Start the full monitoring stack and print login info
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

if (-not (Test-Path ".env")) {
    Copy-Item ".env.example" ".env"
    Write-Host "Created .env from .env.example - edit passwords if needed." -ForegroundColor Yellow
}

# Load .env into process environment
Get-Content ".env" | ForEach-Object {
    $line = $_.Trim()
    if ($line -eq "" -or $line.StartsWith("#")) { return }
    $idx = $line.IndexOf("=")
    if ($idx -lt 1) { return }
    $name = $line.Substring(0, $idx).Trim()
    $value = $line.Substring($idx + 1).Trim().Trim([char]34).Trim([char]39)
    [System.Environment]::SetEnvironmentVariable($name, $value, "Process")
}

Write-Host ""
Write-Host "=== Checking Docker ===" -ForegroundColor Cyan
docker info 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Docker is not running. Start Docker Desktop, wait until ready, then re-run." -ForegroundColor Red
    exit 1
}

Write-Host "=== Building and starting stack ===" -ForegroundColor Cyan
docker compose up -d --build
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "=== Waiting for Grafana ===" -ForegroundColor Cyan
for ($i = 0; $i -lt 50; $i++) {
    try {
        $null = Invoke-RestMethod -Uri "http://localhost:3001/api/health" -TimeoutSec 3
        break
    } catch {
        Start-Sleep -Seconds 3
        Write-Host ("  still starting... ({0})" -f $i)
    }
}

$user = $env:GRAFANA_ADMIN_USER
if (-not $user) { $user = "admin" }
$pass = $env:GRAFANA_ADMIN_PASSWORD
if (-not $pass) { $pass = "AdminMonitor2024" }
$viewerUser = $env:GRAFANA_VIEWER_USER
if (-not $viewerUser) { $viewerUser = "viewer" }
$viewerPass = $env:GRAFANA_VIEWER_PASSWORD
if (-not $viewerPass) { $viewerPass = "ViewerMonitor2024" }

$pair = $user + ":" + $pass
$bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
$basic = [Convert]::ToBase64String($bytes)
$headers = @{
    Authorization = "Basic $basic"
    "Content-Type" = "application/json"
}

try {
    $bodyObj = @{
        name = "Viewer"
        email = "viewer@localhost"
        login = $viewerUser
        password = $viewerPass
        OrgId = 1
    }
    $body = $bodyObj | ConvertTo-Json
    Invoke-RestMethod -Method Post -Uri "http://localhost:3001/api/admin/users" -Headers $headers -Body $body -TimeoutSec 10 | Out-Null
    Write-Host ("Created Grafana viewer user: {0}" -f $viewerUser) -ForegroundColor Green
} catch {
    Write-Host "Viewer user may already exist (OK)." -ForegroundColor Yellow
}

try {
    $users = Invoke-RestMethod -Uri "http://localhost:3001/api/org/users" -Headers $headers -TimeoutSec 10
    $vu = $users | Where-Object { $_.login -eq $viewerUser }
    if ($vu) {
        $uid = $vu.userId
        $roleBody = @{ role = "Viewer" } | ConvertTo-Json
        $roleUrl = "http://localhost:3001/api/org/users/" + $uid
        Invoke-RestMethod -Method Patch -Uri $roleUrl -Headers $headers -Body $roleBody -TimeoutSec 10 | Out-Null
    }
} catch {
    # ignore role patch errors
}

Write-Host ""
Write-Host "========================================================" -ForegroundColor Green
Write-Host "  STACK IS UP"
Write-Host "========================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  GRAFANA (dashboards)" -ForegroundColor Cyan
Write-Host "    URL:      http://localhost:3001"
Write-Host ("    Username: {0}" -f $user)
Write-Host ("    Password: {0}" -f $pass)
Write-Host ""
Write-Host "  VIEWER (read-only)" -ForegroundColor Cyan
Write-Host ("    Username: {0}" -f $viewerUser)
Write-Host ("    Password: {0}" -f $viewerPass)
Write-Host ""
Write-Host "  OTHER URLS" -ForegroundColor Cyan
Write-Host "    Demo app:      http://localhost:8080"
Write-Host "    Prometheus:    http://localhost:9090"
Write-Host "    Alertmanager:  http://localhost:9093"
Write-Host "    Alert logger:  http://localhost:9999"
Write-Host ""
Write-Host "  Generate traffic:  .\scripts\generate-load.ps1" -ForegroundColor Yellow
Write-Host "  Full guide:        HOW_TO_USE.md" -ForegroundColor Yellow
Write-Host ""
