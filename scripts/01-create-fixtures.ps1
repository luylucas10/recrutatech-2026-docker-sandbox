$DemoRoot = Split-Path -Parent $PSScriptRoot
$Workspace = Join-Path $DemoRoot 'workspace'

# --------------------------------------------------
# PASSO 1 — restaurar apenas os fixtures conhecidos
# Resultado esperado: conteúdos fictícios iniciais.
# --------------------------------------------------
Set-Content -LiteralPath (Join-Path $Workspace 'message.txt') -Value 'ANTES DA IA' -Encoding utf8NoBOM
Set-Content -LiteralPath (Join-Path $DemoRoot 'host-only/fake-secret.txt') -Value 'RECRUTATECH_FAKE_SECRET=demo-only-not-a-real-secret' -Encoding utf8NoBOM

# --------------------------------------------------
# PASSO 2 — inicializar somente o repositório descartável, se necessário
# Resultado esperado: workspace é um repositório Git independente.
# --------------------------------------------------
if (-not (Test-Path -LiteralPath (Join-Path $Workspace '.git'))) { git -C $Workspace init }

# --------------------------------------------------
# PASSO 3 — criar o commit inicial somente se ainda não houver commit
# Resultado esperado: HEAD existe; nenhuma identidade global é alterada.
# --------------------------------------------------
git -C $Workspace rev-parse --verify HEAD 2>$null
if ($LASTEXITCODE -ne 0) {
    git -C $Workspace add README.md agent-note.txt message.txt
    git -C $Workspace -c user.name='RecrutaTech Demo' -c user.email='demo@invalid.example' commit -m 'Initial disposable demo fixture'
}
git -C $Workspace status --short --branch
