# Runbook de palco

Execute da raiz do repositório em PowerShell. Cada mutação declara seu recurso. Não cole um script inteiro no palco.

## Ordem rápida: scripts e prompts

```text
00 → 01 → 02 → 03 → 04 → 05 → PROMPT 1
                                 ↓
PROMPT 2 → 06 → PROMPT 3 → 07 → PROMPT 4 → 08
PROMPT 5 → 09 → 10 → PROMPT 6 → 11
PROMPT 7 → 12 → 90 (opcional) → 99
```

Os scripts são a fonte dos comandos; `PROMPTS.md` diz o que executar imediatamente antes e depois de cada prompt.

## Passo 1 — preflight

**O que esperamos que aconteça:** diagnósticos `[OK]`, sem correções automáticas.  
**Comando:** `& .\scripts\00-preflight.ps1`  
**Como saber se funcionou:** Windows, PowerShell, sbx, Docker, Git, políticas, pasta e portas aparecem.  
**Se der errado:** corrija somente o item `[FAIL]`; porta ocupada exige outro par consistente ou encerramento manual do dono conhecido.

## Passo 2 — fixtures

**O que esperamos que aconteça:** workspace vira Git independente com conteúdo inicial.  
**Recurso afetado:** somente `workspace` e `host-only/fake-secret.txt`.  
**Comando:** `& .\scripts\01-create-fixtures.ps1`  
**Como saber se funcionou:** `git status` aponta o repositório descartável; `message.txt` contém `ANTES DA IA`.  
**Se der errado:** confirme Git e permissões da pasta; não altere configuração global.

## Passo 3 — guarda no Docker do host

**Script de referência:** `scripts/02-start-host-container.ps1`.

**O que esperamos que aconteça:** criar/iniciar somente o guarda.  
**Recurso afetado:** container host `recrutatech-host-guard`.  
**Comando:** `docker run -d --name recrutatech-host-guard alpine:3.20 sleep 86400` (use apenas se o nome não existir)  
**Como saber se funcionou:** `docker ps --filter "name=^/recrutatech-host-guard$" --format 'table {{.Names}}\t{{.Status}}'` mostra uma linha.  
**Se der errado:** se já existe, use `docker start recrutatech-host-guard`; se o Hub estiver lento, use a imagem já pré-puxada no ensaio.

## Passo 4 — mocks locais

**O que esperamos que aconteça:** iniciar dois processos identificados por PID.  
**Recurso afetado:** listeners 18080/18081 e `.demo-state/`.  
**Comando:** `& .\scripts\03-start-mock-services.ps1`  
**Como saber se funcionou:** aparecem `NETWORK_ALLOWED` e `NETWORK_SHOULD_BE_BLOCKED`.  
**Se der errado:** não prossiga com a prova de rede; reveja portas/PIDs e rode cleanup específico.

## Passo 5 — criar direct sem anexar

**Script de referência:** `scripts/04-create-direct-sandbox.ps1`.

**O que esperamos que aconteça:** criar uma sandbox Codex direct.  
**Recurso afetado:** sandbox `recrutatech-direct`.  
**Comando:** `$workspace = (Resolve-Path .\workspace).Path; sbx create --name recrutatech-direct codex $workspace`  
**Como saber se funcionou:** `sbx ls` mostra nome e workspace corretos.  
**Se der errado:** valide `sbx create --help`, login e daemon; não crie com a raiz do projeto.

## Passo 6 — política por sandbox

**Script de referência:** `scripts/05-configure-network-policy.ps1`. O último bloco abre o Codex somente após os checks.

**O que esperamos que aconteça:** adicionar allow 18080.  
**Recurso afetado:** política local de `recrutatech-direct`.  
**Comando:** `sbx policy allow network --sandbox recrutatech-direct localhost:18080`  
**Como saber se funcionou:** `sbx policy check network --sandbox recrutatech-direct localhost:18080` retorna Allowed.

**O que esperamos que aconteça:** adicionar deny 18081.  
**Recurso afetado:** política local de `recrutatech-direct`.  
**Comando:** `sbx policy deny network --sandbox recrutatech-direct localhost:18081`  
**Como saber se funcionou:** `sbx policy check network --sandbox recrutatech-direct localhost:18081` retorna Denied.  
**Se der errado:** use `sbx policy ls recrutatech-direct --wide`; não altere política global.

## Passo 7 — iniciar Codex e mostrar autonomia

**O que esperamos que aconteça:** anexar à sandbox existente.  
**Recurso afetado:** sessão do agente em `recrutatech-direct`.  
**Comando:** `sbx run --name recrutatech-direct` (último bloco de `scripts/05-configure-network-policy.ps1`)

**Como saber se funcionou:** Codex abre no workspace; copie o PROMPT 1.  
**Se der errado:** siga com `sbx exec recrutatech-direct sh -lc 'pwd; ls -la; git --version; docker version'`.

## Passo 8 — filesystem fora do workspace

**Validação técnica:** `scripts/06-validate-filesystem.ps1`, depois do PROMPT 2.

**O que esperamos que aconteça:** exibir o segredo fictício apenas no host.  
**Comando:** `Get-Content -LiteralPath .\host-only\fake-secret.txt`  
**Como saber se funcionou:** aparece `RECRUTATECH_FAKE_SECRET=demo-only-not-a-real-secret`.

Copie o **PROMPT 2**. Depois valide:  
**Comando:** `sbx exec recrutatech-direct sh -lc 'find / -name fake-secret.txt -print 2>/dev/null'`  
**Como saber se funcionou:** nenhuma saída.  
**Se der errado:** qualquer caminho retornado deve ser investigado; não trate erro genérico como prova.

## Passo 9 — Docker Engine privado

**Validação técnica:** `scripts/07-validate-docker-isolation.ps1`, depois do PROMPT 3.

**O que esperamos que aconteça:** host mostra o guarda.  
**Comando:** `docker ps --filter "name=^/recrutatech-host-guard$" --format 'table {{.Names}}\t{{.Status}}'`  
**Como saber se funcionou:** guarda visível.

Copie o **PROMPT 3**.  
**Comando:** `sbx exec recrutatech-direct docker ps --format 'table {{.Names}}\t{{.Status}}'`  
**Como saber se funcionou:** guarda ausente.

**O que esperamos que aconteça:** criar container apenas no Engine privado.  
**Recurso afetado:** container interno `recrutatech-sandbox-container`.  
**Comando:** `sbx exec recrutatech-direct docker run -d --name recrutatech-sandbox-container alpine:3.20 sleep 3600`  
**Como saber se funcionou:** `sbx exec recrutatech-direct docker ps --filter 'name=^/recrutatech-sandbox-container$'` mostra o container.  
**Se der errado:** mostre `docker version` nos dois lados; pule o pull se a rede do evento estiver ruim.

## Passo 10 — rede permitida e bloqueada

**Validação técnica:** `scripts/08-validate-network.ps1`, depois do PROMPT 4.

**Comandos host:** `(Invoke-WebRequest -UseBasicParsing http://127.0.0.1:18080/).Content` e `(Invoke-WebRequest -UseBasicParsing http://127.0.0.1:18081/).Content`  
**Como saber se funcionou:** ambos os bodies aparecem.

Copie o **PROMPT 4** ou execute:  
**Comando:** `sbx exec recrutatech-direct curl --fail --show-error --max-time 5 http://host.docker.internal:18080/`  
**Como saber se funcionou:** `NETWORK_ALLOWED`.  
**Comando:** `sbx exec recrutatech-direct curl --fail --show-error --max-time 5 http://host.docker.internal:18081/`  
**Como saber se funcionou:** falha, enquanto `sbx policy check network --sandbox recrutatech-direct localhost:18081` diz Denied.  
**Se der errado:** confirme `command -v curl`, mocks no host e checks de política; diferencie ferramenta, DNS, serviço, timeout e deny.

## Passo 11 — direct mode escreve no host

**Validação e restauração:** `scripts/09-validate-direct-mode.ps1`, depois do PROMPT 5.

Copie o **PROMPT 5**.  
**O que esperamos que aconteça:** agente altera somente `message.txt`.  
**Recurso afetado:** `workspace/message.txt`.  
**Comando host:** `Get-Content .\workspace\message.txt`  
**Como saber se funcionou:** `ALTERADO PELO AGENTE`; depois `git -C .\workspace status --short` e `git -C .\workspace diff -- message.txt`.  
**Se der errado:** execute a alteração com `sbx exec recrutatech-direct sh -lc "printf 'ALTERADO PELO AGENTE\n' > message.txt"`.

## Passo 12 — restaurar entre modos

**O que esperamos que aconteça:** restaurar somente message.txt.  
**Recurso afetado:** `workspace/message.txt`.  
**Comando:** `Set-Content -LiteralPath .\workspace\message.txt -Value 'ANTES DA IA' -Encoding utf8NoBOM`  
**Como saber se funcionou:** `Get-Content .\workspace\message.txt` mostra `ANTES DA IA`.

## Passo 13 — clone mode

**Criação:** `scripts/10-create-clone-sandbox.ps1`. **Validação:** `scripts/11-validate-clone-mode.ps1`, depois do PROMPT 6.

**O que esperamos que aconteça:** criar sandbox clone sem anexar.  
**Recurso afetado:** sandbox `recrutatech-clone`.  
**Comando:** `$workspace = (Resolve-Path .\workspace).Path; sbx create --clone --name recrutatech-clone codex $workspace`  
**Como saber se funcionou:** `sbx ls` mostra sandbox separada.  
**Comando:** `sbx run --name recrutatech-clone`  
**Recurso afetado:** sessão do agente no clone.  
**Como saber se funcionou:** copie o **PROMPT 6**.

**Comando host:** `Get-Content .\workspace\message.txt` → `ANTES DA IA`.  
**Comando clone:** `sbx exec recrutatech-clone sh -lc 'cat message.txt'` → `ALTERADO SOMENTE NO CLONE`.  
**Comando origem:** `sbx exec recrutatech-clone sh -lc 'cat /run/sandbox/source/message.txt && test ! -w /run/sandbox/source/message.txt'` → origem inicial e não gravável.  
**Se der errado:** use os dois `Get-Content/cat` objetivos; não dependa da fala do agente.

## Passo 14 — risco residual

**Validação técnica:** `scripts/12-validate-residual-risk.ps1`, depois do PROMPT 7.

Copie o **PROMPT 7** ou:  
**O que esperamos que aconteça:** endpoint fictício registra uma ação externa permitida.  
**Recurso afetado:** `.demo-state/deploy.log`; nenhum deploy real.  
**Comando:** `sbx exec recrutatech-direct curl --fail --show-error --max-time 5 -X POST http://host.docker.internal:18080/deploy`  
**Como saber se funcionou:** resposta `FAKE_DEPLOY_RECEIVED` e `Get-Content .\.demo-state\deploy.log` mostra o registro.  
**Se der errado:** confirme allow 18080 e saúde do mock; nunca substitua por serviço real.

## Passo 15 — reset e cleanup

**O que esperamos que aconteça:** restaurar fixtures/logs/container interno conhecido.  
**Recurso afetado:** somente recursos da demo.  
**Comando:** `& .\scripts\90-reset-demo-state.ps1`  
**Como saber se funcionou:** `message.txt` voltou ao inicial.

**O que esperamos que aconteça:** listar candidatos, pedir `LIMPAR-DEMO` e remover somente nomes/PIDs exatos.  
**Recurso afetado:** as duas sandboxes, os dois containers da demo, mocks e estado efêmero.  
**Comando:** `& .\scripts\99-cleanup.ps1`  
**Como saber se funcionou:** `sbx ls`, filtro exato de `docker ps -a` e portas não mostram recursos da demo.  
**Se der errado:** remova manualmente um nome exato por vez; nunca use `prune`, `policy reset`, `git reset --hard` ou `git clean`.

## Contingência curta

- Sandbox/Codex lento: prossiga com `sbx exec` e `policy check`.
- Resposta diferente do agente: mostre os comandos objetivos; não discuta com o modelo no palco.
- Mock/porta: prove saúde no host primeiro; se falhar, pule apenas rede/risco residual.
- Hub/evento lento: pré-puxe `alpine:3.20`; se offline, preserve filesystem, modes e policy check.
- Nunca transforme uma falha genérica em “prova” de isolamento.

## Cinco primeiros comandos do ensaio

```powershell
sbx version
sbx create --help
sbx exec --help
sbx policy allow network --help
sbx policy check network --help
```
