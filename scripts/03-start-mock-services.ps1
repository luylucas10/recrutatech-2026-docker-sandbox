$DemoRoot = Split-Path -Parent $PSScriptRoot
$Helper = Join-Path $DemoRoot 'helpers/mock-server.ps1'
$StateDir = Join-Path $DemoRoot '.demo-state'
New-Item -ItemType Directory -Path $StateDir -Force | Out-Null

# --------------------------------------------------
# PASSO 1 — confirmar que as duas portas estão livres
# Resultado esperado: nenhum listener em 18080 ou 18081.
# --------------------------------------------------
foreach ($port in 18080, 18081) {
    if (Get-NetTCPConnection -State Listen -LocalPort $port -ErrorAction SilentlyContinue) { throw "Porta $port já está ocupada; nada foi iniciado." }
}

# --------------------------------------------------
# PASSO 2 — iniciar serviço permitido, identificado por PID
# Resultado esperado: body NETWORK_ALLOWED em 18080.
# --------------------------------------------------
$allowedArgs = '-NoProfile', '-File', ('"{0}"' -f $Helper), '-Port', '18080', '-LogPath', ('"{0}"' -f (Join-Path $StateDir 'deploy.log'))
$allowed = Start-Process pwsh -WindowStyle Hidden -PassThru -ArgumentList $allowedArgs
Set-Content -LiteralPath (Join-Path $StateDir 'mock-18080.pid') -Value $allowed.Id

# --------------------------------------------------
# PASSO 3 — iniciar serviço que será bloqueado, identificado por PID
# Resultado esperado: body NETWORK_SHOULD_BE_BLOCKED em 18081.
# --------------------------------------------------
$blockedArgs = '-NoProfile', '-File', ('"{0}"' -f $Helper), '-Port', '18081', '-LogPath', ('"{0}"' -f (Join-Path $StateDir 'blocked.log'))
$blocked = Start-Process pwsh -WindowStyle Hidden -PassThru -ArgumentList $blockedArgs
Set-Content -LiteralPath (Join-Path $StateDir 'mock-18081.pid') -Value $blocked.Id

# --------------------------------------------------
# PASSO 4 — provar no host que ambos respondem
# Resultado esperado: os dois bodies visuais; falha aqui NÃO prova política.
# --------------------------------------------------
Start-Sleep -Milliseconds 500
(Invoke-WebRequest -UseBasicParsing 'http://127.0.0.1:18080/').Content
(Invoke-WebRequest -UseBasicParsing 'http://127.0.0.1:18081/').Content
