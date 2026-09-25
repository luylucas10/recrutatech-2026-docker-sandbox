$DemoRoot = Split-Path -Parent $PSScriptRoot
$Workspace = Join-Path $DemoRoot 'workspace'
$StateDir = Join-Path $DemoRoot '.demo-state'

# --------------------------------------------------
# PASSO 1 — restaurar somente o arquivo conhecido
# Resultado esperado: ANTES DA IA.
# --------------------------------------------------
Set-Content -LiteralPath (Join-Path $Workspace 'message.txt') -Value 'ANTES DA IA' -Encoding utf8NoBOM

# --------------------------------------------------
# PASSO 2 — limpar somente logs conhecidos da demo
# Resultado esperado: logs vazios ou ausentes.
# --------------------------------------------------
foreach ($name in 'deploy.log', 'blocked.log') {
    $path = Join-Path $StateDir $name
    if (Test-Path -LiteralPath $path) { Clear-Content -LiteralPath $path }
}

# --------------------------------------------------
# PASSO 3 — remover somente o container interno conhecido, se a sandbox existir
# Resultado esperado: nenhum recrutatech-sandbox-container no Engine privado.
# --------------------------------------------------
if ((Get-Command sbx -ErrorAction SilentlyContinue) -and ((sbx ls --quiet) -contains 'recrutatech-direct')) {
    sbx exec recrutatech-direct sh -lc 'docker rm -f recrutatech-sandbox-container 2>/dev/null || true'
}

Get-Content -LiteralPath (Join-Path $Workspace 'message.txt')
git -C $Workspace status --short

Write-Warning 'Clone mode mantém estado dentro da sandbox. Para zerá-lo, remova e recrie somente recrutatech-clone usando 99-cleanup.ps1 e 10-create-clone-sandbox.ps1.'
