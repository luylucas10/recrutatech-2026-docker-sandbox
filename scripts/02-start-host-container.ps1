$Name = 'recrutatech-host-guard'

# --------------------------------------------------
# PASSO 1 — detectar colisão pelo nome exato
# Resultado esperado: nenhum container ou exatamente o container da demo.
# --------------------------------------------------
$existing = docker ps -a --filter "name=^/$Name$" --format '{{.Names}}'
if ($existing -and $existing -ne $Name) { throw "Colisão inesperada: $existing" }

# --------------------------------------------------
# PASSO 2 — criar ou iniciar somente o container da demo
# Resultado esperado: recrutatech-host-guard permanece executando.
# --------------------------------------------------
if (-not $existing) { docker run -d --name $Name alpine:3.20 sleep 86400 }
elseif (-not (docker ps --filter "name=^/$Name$" --format '{{.Names}}')) { docker start $Name }

# --------------------------------------------------
# PASSO 3 — mostrar somente o recurso da demo
# Resultado esperado: uma linha com recrutatech-host-guard.
# --------------------------------------------------
docker ps --filter "name=^/$Name$" --format 'table {{.Names}}\t{{.Status}}\t{{.Image}}'
