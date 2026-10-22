# Operação do painel. Rode o instalar.ps1 antes, uma vez.
#
#   .\painel.ps1 compile
#   .\painel.ps1 flash -Porta COM3        # primeira gravação, por cabo
#   .\painel.ps1 ota                      # atualizações seguintes, por Wi-Fi
#   .\painel.ps1 logs -Porta COM3         # logs por cabo
#   .\painel.ps1 logs-wifi                # logs por Wi-Fi
#   .\painel.ps1 clean                    # limpa a build
#
# Trocar de arquivo de configuração:
#   .\painel.ps1 flash -Config painel-minimo.yaml
#
# As duas variáveis de ambiente abaixo são OBRIGATÓRIAS — veja a explicação
# no instalar.ps1 e no README.md (seção "Erros que você vai encontrar").

param(
    [Parameter(Position = 0)]
    [ValidateSet('compile', 'flash', 'ota', 'logs', 'logs-wifi', 'clean')]
    [string]$Acao = 'compile',

    [string]$Config = 'painel-minimo.yaml',
    [string]$Porta  = 'COM3',
    [string]$Alvo   = ''
)

$ErrorActionPreference = 'Stop'

$env:ESPHOME_ESP_IDF_PREFIX = 'C:\esp\idf'
$env:ESPHOME_BUILD_PATH     = 'C:\esp\build'

$raiz    = $PSScriptRoot
$esphome = Join-Path $raiz '.venv\Scripts\esphome.exe'

if (-not (Test-Path $esphome)) {
    throw "ESPHome não encontrado. Rode primeiro:  .\instalar.ps1"
}

Set-Location (Join-Path $raiz 'esphome')

if (-not (Test-Path $Config)) {
    throw "Configuração '$Config' não existe em $raiz\esphome"
}
if (-not (Test-Path 'secrets.yaml')) {
    throw "secrets.yaml não existe. Copie o secrets.example.yaml e preencha o Wi-Fi."
}

# Descobre o endereço de rede a partir do nome do dispositivo no YAML,
# para o OTA funcionar sem precisar digitar o host.
if (-not $Alvo) {
    $nome = (Select-String -Path $Config -Pattern '^\s*name:\s*(\S+)' | Select-Object -First 1).Matches.Groups[1].Value
    $Alvo = "$nome.local"
}

switch ($Acao) {
    'compile'   { & $esphome compile $Config }
    'flash'     { & $esphome run     $Config --device $Porta }
    'ota'       { & $esphome run     $Config --device $Alvo }
    'logs'      { & $esphome logs    $Config --device $Porta }
    'logs-wifi' { & $esphome logs    $Config --device $Alvo }
    'clean'     { & $esphome clean   $Config }
}

exit $LASTEXITCODE
