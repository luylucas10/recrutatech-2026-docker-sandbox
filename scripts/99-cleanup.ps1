$DemoRoot = Split-Path -Parent $PSScriptRoot
$StateDir = Join-Path $DemoRoot '.demo-state'
$confirmedRoot = [IO.Path]::GetFullPath($DemoRoot)
$requiredMarkers = 'README.md', 'RUNBOOK.md', 'workspace', 'host-only', 'scripts/99-cleanup.ps1'
foreach ($marker in $requiredMarkers) {
    if (-not (Test-Path -LiteralPath (Join-Path $confirmedRoot $marker))) { throw "Raiz recusada; marcador ausente: $marker" }
}

Write-Host 'Recursos candidatos: sandboxes recrutatech-direct/recrutatech-clone; container recrutatech-host-guard; mocks 18080/18081.'
if ((Read-Host 'Digite LIMPAR-DEMO para continuar') -ne 'LIMPAR-DEMO') { Write-Host 'Cancelado sem alterações.'; return }

# --------------------------------------------------
# PASSO 1 — remover somente sandboxes com nomes exatos
# Resultado esperado: apenas recursos listados são solicitados para remoção.
# --------------------------------------------------
if (Get-Command sbx -ErrorAction SilentlyContinue) {
    $sandboxes = @(sbx ls --quiet)
    foreach ($name in 'recrutatech-direct', 'recrutatech-clone') {
        if ($sandboxes -contains $name) { Write-Host "Removendo sandbox: $name"; sbx rm $name }
    }
}

# --------------------------------------------------
# PASSO 2 — remover somente o container de host com nome exato
# Resultado esperado: nenhum outro container é afetado.
# --------------------------------------------------
if (Get-Command docker -ErrorAction SilentlyContinue) {
    $container = docker ps -a --filter 'name=^/recrutatech-host-guard$' --format '{{.Names}}'
    if ($container -eq 'recrutatech-host-guard') { Write-Host 'Removendo container: recrutatech-host-guard'; docker rm -f recrutatech-host-guard }
}

# --------------------------------------------------
# PASSO 3 — encerrar somente PIDs gravados cujo comando aponta para o helper
# Resultado esperado: nenhum PowerShell não relacionado é encerrado.
# --------------------------------------------------
foreach ($port in 18080, 18081) {
    $pidFile = Join-Path $StateDir "mock-$port.pid"
    if (-not (Test-Path -LiteralPath $pidFile)) { continue }
    $mockPid = [int](Get-Content -LiteralPath $pidFile)
    $process = Get-CimInstance Win32_Process -Filter "ProcessId=$mockPid" -ErrorAction SilentlyContinue
    if ($process -and $process.CommandLine -like "*mock-server.ps1*" -and $process.CommandLine -like "*$confirmedRoot*") {
        Write-Host "Encerrando mock PID $mockPid na porta $port"; Stop-Process -Id $mockPid
    } else { Write-Warning "PID $mockPid não corresponde ao mock desta demo; não foi encerrado." }
    Remove-Item -LiteralPath $pidFile
}

foreach ($name in 'deploy.log', 'blocked.log') {
    $path = Join-Path $StateDir $name
    if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path }
}
