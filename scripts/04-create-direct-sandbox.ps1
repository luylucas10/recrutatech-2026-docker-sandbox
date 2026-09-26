$Workspace = Join-Path (Split-Path -Parent $PSScriptRoot) 'workspace'

# --------------------------------------------------
# PASSO 1 — criar, sem anexar, a sandbox direct
# Resultado esperado: somente recrutatech-direct; workspace exato em leitura/escrita.
# Agente desta demonstração: OpenCode.
# --------------------------------------------------
sbx create --name recrutatech-direct opencode $Workspace

# --------------------------------------------------
# PASSO 2 — conferir cadastro antes de iniciar o agente
# Resultado esperado: recrutatech-direct aponta para workspace.
# --------------------------------------------------
sbx ls

# A sessão do OpenCode só é aberta no PASSO 4 de 05-configure-network-policy.ps1,
# depois das regras e checks de rede.
