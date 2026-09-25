$Workspace = Join-Path (Split-Path -Parent $PSScriptRoot) 'workspace'

# --------------------------------------------------
# PASSO 1 — confirmar origem limpa para uma comparação inequívoca
# Resultado esperado: message.txt contém ANTES DA IA.
# --------------------------------------------------
Get-Content -LiteralPath (Join-Path $Workspace 'message.txt')

# --------------------------------------------------
# PASSO 2 — criar clone privado, sem anexar
# Resultado esperado: somente recrutatech-clone em clone mode.
# --------------------------------------------------
sbx create --clone --name recrutatech-clone codex $Workspace

# --------------------------------------------------
# PASSO 3 — anexar ao Codex do clone
# Resultado esperado: sessão trabalha na cópia privada.
# --------------------------------------------------
sbx run --name recrutatech-clone
