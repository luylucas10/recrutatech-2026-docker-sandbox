$Workspace = Join-Path (Split-Path -Parent $PSScriptRoot) 'workspace'

# --------------------------------------------------
# PASSO 1 — criar, sem anexar, a sandbox direct
# Resultado esperado: somente recrutatech-direct; workspace exato em leitura/escrita.
# Claude Code, Codex, Copilot, Cursor, Devin
# Docker Agent, Droid, Gemini, Kiro, OpenCode, Shell 
# --------------------------------------------------
sbx create --name recrutatech-direct opencode $Workspace

# --------------------------------------------------
# PASSO 2 — conferir cadastro antes de iniciar o agente
# Resultado esperado: recrutatech-direct aponta para workspace.
# --------------------------------------------------
sbx ls

# A sessão do Codex só é aberta no PASSO 4 de 05-configure-network-policy.ps1,
# depois das regras e checks de rede.
