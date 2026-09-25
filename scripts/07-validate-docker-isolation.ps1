$Name = 'recrutatech-host-guard'

# --------------------------------------------------
# PASSO 1 — mostrar o container no daemon do host
# Resultado esperado: recrutatech-host-guard.
# --------------------------------------------------
docker ps --filter "name=^/$Name$" --format 'table {{.Names}}\t{{.Status}}'

# --------------------------------------------------
# PASSO 2 — listar o daemon privado da sandbox
# Resultado esperado: NÃO contém recrutatech-host-guard.
# --------------------------------------------------
sbx exec recrutatech-direct docker ps --format 'table {{.Names}}\t{{.Status}}'

# --------------------------------------------------
# PASSO 3 — provar que Docker continua disponível na sandbox
# Resultado esperado: recrutatech-sandbox-container inicia no Engine privado.
# --------------------------------------------------
sbx exec recrutatech-direct docker run -d --name recrutatech-sandbox-container alpine:3.20 sleep 3600
sbx exec recrutatech-direct docker ps --filter 'name=^/recrutatech-sandbox-container$'
