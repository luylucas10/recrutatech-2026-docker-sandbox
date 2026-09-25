$Workspace = Join-Path (Split-Path -Parent $PSScriptRoot) 'workspace'

# --------------------------------------------------
# PASSO 1 — provar que o host não mudou
# Resultado esperado: ANTES DA IA.
# --------------------------------------------------
Get-Content -LiteralPath (Join-Path $Workspace 'message.txt')

# --------------------------------------------------
# PASSO 2 — provar que o clone mudou
# Resultado esperado: ALTERADO SOMENTE NO CLONE.
# --------------------------------------------------
sbx exec recrutatech-clone sh -lc 'cat message.txt'

# --------------------------------------------------
# PASSO 3 — mostrar origem read-only documentada
# Resultado esperado: /run/sandbox/source/message.txt contém ANTES DA IA.
# --------------------------------------------------
sbx exec recrutatech-clone sh -lc 'cat /run/sandbox/source/message.txt && test ! -w /run/sandbox/source/message.txt'
