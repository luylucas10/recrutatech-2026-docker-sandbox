# --------------------------------------------------
# PASSO 1 — permitir somente a porta 18080 nesta sandbox
# Resultado esperado: regra local allow para localhost:18080.
# --------------------------------------------------
sbx policy allow network --sandbox recrutatech-direct localhost:18080

# --------------------------------------------------
# PASSO 2 — negar explicitamente a porta 18081 nesta sandbox
# Resultado esperado: regra local deny para localhost:18081.
# --------------------------------------------------
sbx policy deny network --sandbox recrutatech-direct localhost:18081

# --------------------------------------------------
# PASSO 3 — exibir e avaliar a política, sem tráfego
# Resultado esperado: 18080 Allowed; 18081 Denied.
# --------------------------------------------------
sbx policy ls recrutatech-direct --wide
sbx policy check network --sandbox recrutatech-direct localhost:18080
sbx policy check network --sandbox recrutatech-direct localhost:18081

# --------------------------------------------------
# PASSO 4 — anexar OpenCode somente depois da política
# Resultado esperado: sessão interativa na sandbox existente.
# --------------------------------------------------
sbx run --name recrutatech-direct
