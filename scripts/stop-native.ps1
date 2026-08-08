$root = Split-Path -Parent $PSScriptRoot
$pidFile = "$root\scripts\.native-pids.json"
if (Test-Path $pidFile) {
  $pids = Get-Content $pidFile | ConvertFrom-Json
  foreach ($name in @("app", "prometheus")) {
    $id = $pids.$name
    if ($id) {
      try {
        Stop-Process -Id $id -Force -ErrorAction Stop
        Write-Host "Stopped $name (PID $id)"
      } catch {
        Write-Host "$name PID $id already stopped"
      }
    }
  }
  Remove-Item $pidFile -Force
} else {
  Get-Process -Name prometheus, node -ErrorAction SilentlyContinue |
    Where-Object { $_.Path -like "*prometheus*" -or $_.CommandLine -like "*server.js*" } |
    Stop-Process -Force -ErrorAction SilentlyContinue
  Write-Host "Attempted cleanup of prometheus/node processes"
}
