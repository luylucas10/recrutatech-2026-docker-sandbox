$DemoRoot = Split-Path -Parent $PSScriptRoot
$Log = Join-Path $DemoRoot '.demo-state/deploy.log'

# --------------------------------------------------
# PASSO 1 — chamar somente o endpoint fictício explicitamente permitido
# Resultado esperado: FAKE_DEPLOY_RECEIVED; nenhum deploy real.
# --------------------------------------------------
sbx exec recrutatech-direct curl --fail --show-error --max-time 5 -X POST http://host.docker.internal:18080/deploy

# --------------------------------------------------
# PASSO 2 — provar no host que houve efeito fora da microVM
# Resultado esperado: linha FAKE_DEPLOY_RECEIVED no log local.
# --------------------------------------------------
Get-Content -LiteralPath $Log
