$Workspace = Join-Path (Split-Path -Parent $PSScriptRoot) 'workspace'

# --------------------------------------------------
# PASSO 1 — observar no host após o prompt do agente
# Resultado esperado: ALTERADO PELO AGENTE imediatamente.
# --------------------------------------------------
Get-Content -LiteralPath (Join-Path $Workspace 'message.txt')

# --------------------------------------------------
# PASSO 2 — mostrar alteração sem commit
# Resultado esperado: message.txt modificado e diff correspondente.
# --------------------------------------------------
git -C $Workspace status --short
git -C $Workspace diff -- message.txt

# --------------------------------------------------
# PASSO 3 — restauração cirúrgica para o próximo cenário
# Resultado esperado: somente message.txt volta a ANTES DA IA.
# --------------------------------------------------
Set-Content -LiteralPath (Join-Path $Workspace 'message.txt') -Value 'ANTES DA IA' -Encoding utf8NoBOM
Get-Content -LiteralPath (Join-Path $Workspace 'message.txt')
