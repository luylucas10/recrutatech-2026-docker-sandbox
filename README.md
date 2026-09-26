# Docker Sandbox — kit técnico RecrutaTech 2026

Kit de demonstração para **“Docker Sandbox — Mais autonomia para agentes. Menos risco para sua máquina”**, por Luy Santana. Siga os scripts em ordem e confira cada resultado no [RUNBOOK.md](RUNBOOK.md), que também reúne os prompts para o OpenCode.

## Arquitetura

```text
Windows host
├─ Docker Engine do host → recrutatech-host-guard
├─ mock TCP/HTTP 127.0.0.1:18080 → permitido + POST /deploy fictício
├─ mock TCP/HTTP 127.0.0.1:18081 → explicitamente bloqueado
├─ host-only/fake-secret.txt → nunca compartilhado
└─ workspace/ → único caminho entregue às sandboxes
   ├─ direct: bind read-write
   └─ clone: origem read-only + clone privado na microVM
```

Cada sandbox tem microVM e Docker Engine próprios. A política referencia serviços do host como `localhost:<porta>`; o processo dentro da sandbox usa `host.docker.internal:<porta>`.

## Pré-requisitos e versões detectadas em 2026-09-19

- Windows 11 (o script confirma em tempo de execução).
- PowerShell detectado: **7.6.6**.
- Git detectado: **2.55.0.windows.3**.
- Docker CLI detectado: **29.7.2**; daemon indisponível durante a criação do kit.
- `sbx`: não encontrado no `PATH` durante a criação do kit.
- Docker Desktop/Engine, internet e autenticação do OpenCode funcionais no ensaio.

Execute `scripts/00-preflight.ps1` antes do ensaio. Ele é read-only e não tenta corrigir falhas.

## Recursos exclusivos

| Tipo              | Nome/endereço                   |
| ----------------- | ------------------------------- |
| Sandbox direct    | `recrutatech-direct`            |
| Sandbox clone     | `recrutatech-clone`             |
| Container host    | `recrutatech-host-guard`        |
| Container sandbox | `recrutatech-sandbox-container` |
| Mock permitido    | `127.0.0.1:18080`               |
| Mock bloqueado    | `127.0.0.1:18081`               |
| Estado efêmero    | `.demo-state/`                  |

## Estrutura e fluxo

- `RUNBOOK.md`: sequência da demonstração, scripts, prompts para o OpenCode e validação de cada etapa.
- `helpers/mock-server.ps1`: servidor HTTP mínimo com `TcpListener`, sem URL ACL/admin.
- `scripts/00`–`03`: inspecionar e preparar fixtures, container e mocks.
- `scripts/04`–`12`: criar/configurar e provar os seis cenários.
- `scripts/90-reset-demo-state.ps1`: restaura somente fixture, logs e container interno conhecido.
- `scripts/99-cleanup.ps1`: pede `LIMPAR-DEMO` e remove somente nomes/PIDs exatos.
- `workspace/`: repositório Git independente e descartável.
- `host-only/`: fixture irmão do workspace, propositalmente não compartilhado.

Preparação: rode os scripts `00`, `01`, `02` e `03` separadamente, leia a saída, depois siga o runbook. Restauração: execute `90-reset-demo-state.ps1`; clone mode exige remover/recriar somente `recrutatech-clone`. Limpeza: execute `99-cleanup.ps1` e confirme os candidatos exibidos.

## IMPORTANT: direct mode is not read-only

Direct mode compartilha o workspace em leitura/escrita. Não há fronteira entre as edições do agente e o working tree do host: `message.txt` muda imediatamente no Windows. Por isso a demo compartilha somente o repositório fictício `workspace/`.

## IMPORTANT: clone mode is not zero risk

Clone mode reduz a exposição do working tree: o agente edita uma cópia privada e a origem aparece read-only em `/run/sandbox/source`. Ainda assim, rede permitida, credenciais/proxy, integrações e qualquer recurso explicitamente compartilhado continuam sendo superfícies de risco.

## Comandos oficiais e fontes

Sintaxe baseada na documentação oficial atual e nos arquivos de referência CLI do repositório `docker/docs`:

- `sbx create --name NAME opencode PATH`, `--clone` e `sbx run --name NAME`: [usage](https://docs.docker.com/ai/sandboxes/usage/) e `data/sbx_cli/sbx_create.yaml`/`sbx_run.yaml`.
- `sbx exec SANDBOX COMMAND [ARG...]`: `data/sbx_cli/sbx_exec.yaml`.
- `sbx ls [--quiet]`: `data/sbx_cli/sbx_ls.yaml`.
- `sbx rm SANDBOX`: `data/sbx_cli/sbx_rm.yaml`.
- `sbx policy allow|deny network --sandbox NAME RESOURCE`: [local access controls](https://docs.docker.com/ai/sandboxes/governance/access-controls/local/) e respectivos YAMLs CLI.
- `sbx policy check network --sandbox NAME TARGET` e `sbx policy ls NAME --wide`: `sbx_policy_check_network.yaml` e `sbx_policy_ls.yaml`.
- `localhost:<porta>` na política versus `host.docker.internal:<porta>` dentro da sandbox: [network access controls](https://docs.docker.com/ai/sandboxes/governance/access-controls/network/).
- isolamento, direct/clone, Docker privado e `/run/sandbox/source`: [isolation](https://docs.docker.com/ai/sandboxes/security/isolation/) e [development workflows](https://docs.docker.com/ai/sandboxes/workflows/development/).
- credenciais e risco residual: [credentials](https://docs.docker.com/ai/sandboxes/configuration/credentials/) e [security defaults](https://docs.docker.com/ai/sandboxes/security/defaults/).

Links adicionais consultados: [overview](https://docs.docker.com/ai/sandboxes/), [security](https://docs.docker.com/ai/sandboxes/security/) e [architecture](https://docs.docker.com/ai/sandboxes/architecture/).

## NEEDS-VALIDATION

1. A CLI local `sbx` não estava disponível; valide toda a sintaxe novamente com os `--help` listados nos cinco primeiros comandos do runbook. Se divergir, a CLI instalada vence.
2. Confirme que `curl` existe na sandbox do OpenCode com `sbx exec recrutatech-direct sh -lc 'command -v curl'`. Os checks de política continuam válidos sem curl, mas tráfego real requer uma ferramenta presente.
3. Confirme no ensaio que o proxy local alcança o `TcpListener` ligado em loopback. Se não alcançar, não improvise no palco: registre o resultado e ajuste conscientemente o bind do helper em todos os materiais.

## Riscos, limitações e troubleshooting

- Pull inicial de `alpine:3.20`, criação de VM e OpenCode dependem da internet/cache. Faça o ensaio antes do evento.
- Porta ocupada: `00-preflight.ps1` mostra `WARNING`; não mate o processo. Escolha outro par e atualize o kit inteiro.
- Mock falhou: valide primeiro `Invoke-WebRequest` no host. Falha local não é evidência de política.
- Política diz allow mas curl falha: separe DNS, ferramenta ausente, serviço parado e timeout; mostre `policy check --verbose` no ensaio.
- Sandbox não inicia/OpenCode demora: use as provas objetivas `sbx exec`, `sbx policy check`, `docker ps` e os arquivos do host.
- Docker Hub lento/rede do evento falha: pré-puxe `alpine:3.20` durante o ensaio; sem rede, omita apenas a criação dos containers e preserve as provas de filesystem/política.
- Cleanup usa nomes e PIDs exatos, não usa prune/reset/clean e nunca remove recursivamente.
