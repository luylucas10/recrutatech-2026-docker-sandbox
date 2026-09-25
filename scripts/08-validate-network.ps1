$DemoRoot = Split-Path -Parent $PSScriptRoot

# --------------------------------------------------
# PASSO 1 — provar no host que ambos os serviços estão saudáveis
# Resultado esperado: NETWORK_ALLOWED e NETWORK_SHOULD_BE_BLOCKED.
# --------------------------------------------------
(Invoke-WebRequest -UseBasicParsing 'http://127.0.0.1:18080/').Content
(Invoke-WebRequest -UseBasicParsing 'http://127.0.0.1:18081/').Content

# --------------------------------------------------
# PASSO 2 — confirmar decisões sem depender do curl
# Resultado esperado: Allowed para 18080; Denied para 18081.
# --------------------------------------------------
sbx policy check network --sandbox recrutatech-direct localhost:18080
sbx policy check network --sandbox recrutatech-direct localhost:18081

# --------------------------------------------------
# PASSO 3 — confirmar curl e realizar tráfego real
# Resultado esperado: curl existe; 18080 responde; 18081 falha.
# NEEDS-VALIDATION: disponibilidade de curl no template Codex instalado.
# --------------------------------------------------
sbx exec recrutatech-direct sh -lc 'command -v curl'
sbx exec recrutatech-direct curl --fail --show-error --max-time 5 http://host.docker.internal:18080/
sbx exec recrutatech-direct curl --fail --show-error --max-time 5 http://host.docker.internal:18081/
