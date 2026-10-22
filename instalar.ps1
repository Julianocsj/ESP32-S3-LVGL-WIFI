# Instalação do zero: cria a venv, instala o ESPHome, clona o repo de
# componentes e prepara o secrets.yaml. Rode UMA VEZ.
#
#   .\instalar.ps1
#
# Depois disso, use o painel.ps1 para compilar/gravar.

$ErrorActionPreference = 'Stop'
$raiz = $PSScriptRoot

function Passo($txt) { Write-Host "`n==> $txt" -ForegroundColor Cyan }

# ── 1. Python ────────────────────────────────────────────────────────────────
Passo "Verificando Python"
$py = Get-Command python -ErrorAction SilentlyContinue
if (-not $py) {
    throw "Python não encontrado. Instale de https://python.org (marque 'Add python.exe to PATH') e rode de novo."
}
python --version

# ── 2. Toolchain fora do perfil do usuário ───────────────────────────────────
# Por que C:\esp e não a pasta padrão: o ESP-IDF converte caminhos que contêm
# espaço para o formato antigo 8.3 ("Joao Silva" -> "JOAOSI~1"). O gcc Xtensa
# então recebe a mesma biblioteca por dois nomes diferentes e aborta com
#   "Both 'XTENSA_GNU_CONFIG' and -dynconfig= specified but pointed different files"
# Se o seu usuário do Windows não tem espaço no nome isso não aconteceria, mas
# deixamos fixo para funcionar em qualquer máquina.
Passo "Preparando C:\esp (toolchain e build)"
New-Item -ItemType Directory -Force 'C:\esp' | Out-Null
Write-Host "OK — o toolchain (~6 GB) será baixado aqui na primeira compilação."

# ── 3. Ambiente virtual + ESPHome ────────────────────────────────────────────
Passo "Criando ambiente virtual e instalando ESPHome"
if (-not (Test-Path "$raiz\.venv")) { python -m venv "$raiz\.venv" }
& "$raiz\.venv\Scripts\python.exe" -m pip install --upgrade pip --quiet
# O hardware exige ESPHome 2026.7.0 ou mais novo (min_version do arquivo do board)
& "$raiz\.venv\Scripts\python.exe" -m pip install --upgrade esphome
& "$raiz\.venv\Scripts\esphome.exe" version

# ── 4. Repo de componentes LVGL ──────────────────────────────────────────────
Passo "Clonando esphome-modular-lvgl-buttons"
$repo = "$raiz\esphome\esphome-modular-lvgl-buttons"
if (Test-Path $repo) {
    Write-Host "Já existe, atualizando..."
    git -C $repo pull --ff-only
} else {
    git clone --depth 1 https://github.com/agillis/esphome-modular-lvgl-buttons.git $repo
}

# ── 5. secrets.yaml ──────────────────────────────────────────────────────────
Passo "Preparando secrets.yaml"
$sec = "$raiz\esphome\secrets.yaml"
if (Test-Path $sec) {
    Write-Host "Já existe — não vou sobrescrever."
} else {
    Copy-Item "$raiz\esphome\secrets.example.yaml" $sec
    Write-Host "Criado a partir do exemplo."
}

Write-Host "`n================================================================" -ForegroundColor Green
Write-Host " Instalação concluída." -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green
Write-Host @"

PRÓXIMOS PASSOS:

  1. Edite  esphome\secrets.yaml  com o seu Wi-Fi (rede de 2.4 GHz!)

  2. Edite  esphome\painel-minimo.yaml  trocando os entity_id de exemplo
     pelos do SEU Home Assistant

  3. Descubra a porta COM da placa:
       Get-PnpDevice -Class Ports | Where-Object FriendlyName -match 'CH340|CP210|USB'

  4. Grave:
       .\painel.ps1 flash -Porta COM3 -Config painel-minimo.yaml

  5. No Home Assistant, adicione o dispositivo E marque a permissão
     "Permitir que o dispositivo execute ações do Home Assistant"
     (sem ela os toques não fazem nada — leia o README.md)

"@
