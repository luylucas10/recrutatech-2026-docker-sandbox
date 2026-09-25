$DemoRoot = Split-Path -Parent $PSScriptRoot
$ports = 18080, 18081

function Show-Check($Level, $Message) { Write-Host "[$Level] $Message" }

# --------------------------------------------------
# PASSO 1 — plataforma e ferramentas (somente leitura)
# Resultado esperado: Windows, PowerShell, sbx, Docker e Git disponíveis.
# --------------------------------------------------
if ($IsWindows) { Show-Check OK "Windows $([Environment]::OSVersion.Version)" } else { Show-Check FAIL 'Execute no Windows 11.' }
Show-Check OK "PowerShell $($PSVersionTable.PSVersion)"

$sbx = Get-Command sbx -ErrorAction SilentlyContinue
if ($sbx) { Show-Check OK "sbx encontrado: $($sbx.Source)"; sbx version } else { Show-Check FAIL 'sbx não está no PATH. Instale/atualize Docker Sandboxes.' }

$docker = Get-Command docker -ErrorAction SilentlyContinue
if ($docker) {
    Show-Check OK "Docker CLI encontrado: $($docker.Source)"
    docker version
    if ($LASTEXITCODE -eq 0) { Show-Check OK 'Docker daemon do host respondeu.' } else { Show-Check FAIL 'Inicie o Docker Desktop e confirme o Engine.' }
} else { Show-Check FAIL 'Docker CLI não está no PATH.' }

$git = Get-Command git -ErrorAction SilentlyContinue
if ($git) { Show-Check OK (git --version); git -C $DemoRoot status --short --branch } else { Show-Check FAIL 'Git não está no PATH.' }

# --------------------------------------------------
# PASSO 2 — políticas atuais (somente leitura)
# Resultado esperado: tabela de políticas ou aviso claro se sbx faltar.
# --------------------------------------------------
if ($sbx) { sbx policy ls --wide }

# --------------------------------------------------
# PASSO 3 — pasta e portas (somente leitura)
# Resultado esperado: demo existe; 18080 e 18081 estão livres antes do mock.
# --------------------------------------------------
if (Test-Path -LiteralPath $DemoRoot -PathType Container) { Show-Check OK "Demo: $DemoRoot" } else { Show-Check FAIL "Pasta ausente: $DemoRoot" }
foreach ($port in $ports) {
    $listener = Get-NetTCPConnection -State Listen -LocalPort $port -ErrorAction SilentlyContinue
    if ($listener) { Show-Check WARNING "Porta $port ocupada. Encerre o processo responsável ou escolha novas portas em todo o kit." }
    else { Show-Check OK "Porta $port livre." }
}
