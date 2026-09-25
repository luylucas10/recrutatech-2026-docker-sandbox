$DemoRoot = Split-Path -Parent $PSScriptRoot

# --------------------------------------------------
# PASSO 1 — provar no host que o fixture externo existe
# Resultado esperado: RECRUTATECH_FAKE_SECRET=demo-only-not-a-real-secret.
# --------------------------------------------------
Get-Content -LiteralPath (Join-Path $DemoRoot 'host-only/fake-secret.txt')

# --------------------------------------------------
# PASSO 2 — procurar objetivamente dentro da sandbox
# Resultado esperado: nenhuma saída; erros de permissão não contam como achado.
# --------------------------------------------------
sbx exec recrutatech-direct sh -lc 'find / -name fake-secret.txt -print 2>/dev/null'
