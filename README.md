# Painel de parede ESP32 + Home Assistant

Painel touch de 4" que controla o Home Assistant, feito com ESPHome + LVGL.
Este pacote tem tudo pronto: os componentes, dois exemplos de configuração e
os scripts de instalação e gravação.

---

## 1. O que comprar

**Guition ESP32-4848S040** — no AliExpress procure por "ESP32-4848S040" ou
"ESP32-S3 4 inch 480x480 smart display". Custa uns R$ 105 + impostos.

| | |
|---|---|
| MCU | ESP32-S3, 2 núcleos, 240 MHz |
| Flash / PSRAM | 16 MB / 8 MB octal |
| Tela | 4", 480 × 480, ST7701S (RGB) |
| Touch | GT911 capacitivo |
| Relés internos | 1 ou 3, dependendo da versão (GPIO40, GPIO02, GPIO01) |
| USB | CH340 |

⚠️ Vários anúncios dizem **"480x800"** na ficha técnica. Está errado, é
**480x480** — o próprio nome diz: **48**·**48**·S**040** = 480×480 e 4.0".

⚠️ Existem outros modelos parecidos (JC4827W543, 8048S050...). Este pacote é
para o **4848S040**. Para outro modelo, troque o arquivo em `packages: hardware:`
— o repo tem mais de 30 placas em `hardware/`.

Você também precisa de **Home Assistant** rodando na rede. Sem ele o painel
liga e navega, mas não controla nada.

---

## 2. Instalação (uma vez)

Precisa de **Python** (https://python.org, marque *Add python.exe to PATH*) e
**Git** (https://git-scm.com) instalados.

Descompacte esta pasta onde quiser e rode no PowerShell:

```powershell
.\instalar.ps1
```

Ele cria o ambiente virtual, instala o ESPHome, clona o repo de componentes
e prepara o `secrets.yaml`. A primeira compilação ainda vai baixar ~6 GB de
toolchain do ESP-IDF (só na primeira vez).

### Preencha o Wi-Fi

Abra `esphome\secrets.yaml` e coloque a sua rede. **Tem que ser 2.4 GHz** —
o ESP32-S3 não enxerga 5 GHz.

---

## 3. Adapte ao seu Home Assistant

Abra `esphome\painel-minimo.yaml` e troque os `entity_id` de exemplo pelos
seus. Procure por `TROQUE` no arquivo.

Para descobrir os seus entity_id: no HA vá em **Configurações → Dispositivos
e serviços → Entidades** e copie os nomes da coluna "ID da entidade".

### Os blocos disponíveis

Cada um é um arquivo em `esphome/custom/` que você inclui em `packages:`.
Todos precisam de um `uid` único (é o que separa um do outro no código).

| Bloco | Serve para | Interação |
|---|---|---|
| `tile_switch` | `light.*`, `switch.*`, `input_boolean.*` | toque alterna |
| `tile_light_sm` | igual, mas compacto | para grades de 3 colunas |
| `tile_climate` | `climate.*` | abre detalhe com setpoint e modos |
| `tile_cover` | `cover.*` (persianas) | toque alterna, segurar para |
| `tile_alarm` | `alarm_control_panel.*` | só mostra, abre outra página |
| `tile_nav` | nada — só navega | abre a página que você indicar |
| `row_binary` | `binary_sensor.*` | leitura (porta, presença) |
| `row_sensor` | sensor numérico | leitura (temperatura, potência) |
| `row_text` | estado em texto | leitura (person, media_player) |
| `row_switch` | linha com interruptor | toque alterna |

Exemplo de uso — uma luz na tela inicial:

```yaml
packages:
  cozinha: !include
    file: custom/tile_switch.yaml
    vars:
      uid: cozinha                       # único, sem espaços nem hífen
      entity_id: "light.cozinha"
      row: 1
      column: 0
      text: "Cozinha"
      icon: $mdi_ceiling_light
```

E uma linha de leitura numa página de lista:

```yaml
  porta_garagem: !include
    file: custom/row_binary.yaml
    vars:
      uid: porta_garagem
      entity_id: "binary_sensor.porta_garagem"
      page_id: estado_page               # em qual página a linha aparece
      text: "Garagem"
      icon: $mdi_garage
      status_on: "Aberta"
      status_off: "Fechada"
      on_color: "0xE24B4A"               # vermelho quando aberta
```

Os `vars` de cada bloco estão documentados no comentário no topo do próprio
arquivo em `custom/`.

### Ícones

Use `$mdi_alguma_coisa`. A lista completa de nomes válidos fica em
`esphome/esphome-modular-lvgl-buttons/common/theme/mdi_glyph_substitutions.yaml`
(são 7447).

**Todo ícone que você usar precisa estar na lista `glyphs:` da fonte do
tamanho certo**, lá no fim do YAML. Se esquecer, aparece um quadradinho vazio
no lugar do ícone. Qual tamanho:

- tiles da tela inicial → `mdi_icons_40`
- botões da barra de topo → `mdi_icons_32`
- linhas e tiles compactos → `mdi_icons_28`

---

## 4. Gravar

Descubra a porta COM da placa:

```powershell
Get-PnpDevice -Class Ports | Where-Object FriendlyName -match 'CH340|CP210|USB'
```

Grave (a primeira vez tem que ser por cabo):

```powershell
.\painel.ps1 flash -Porta COM3 -Config painel-minimo.yaml
```

Se o esptool não conseguir entrar em modo de gravação sozinho: segure o botão
**BOOT** da placa, dê um toque no **RST**, solte o BOOT e rode de novo.

Depois do primeiro flash, nunca mais precisa de cabo:

```powershell
.\painel.ps1 ota -Config painel-minimo.yaml
```

---

## 5. Ligar no Home Assistant

**Configurações → Dispositivos e serviços → ESPHome** — ele aparece sozinho.
Se não aparecer, adicione pelo IP ou por `painel.local`.

### ⚠️ O passo que todo mundo esquece

Depois de adicionar, clique no dispositivo → **Configurar** e marque:

> **"Permitir que o dispositivo execute ações do Home Assistant"**

Sem isso os tiles mostram o estado certo (acendem laranja quando a luz está
ligada) mas **o toque não faz nada**. Por segurança o HA bloqueia por padrão
que um dispositivo dispare ações. No log do painel aparece:

```
[W][api]: Home Assistant action 'homeassistant.toggle' dropped;
          client has not subscribed to actions (yet)
```

Se você vir essa linha, é exatamente isso.

---

## 6. Erros que você vai encontrar

### `cc1.exe: fatal error: Both 'XTENSA_GNU_CONFIG' and "-dynconfig=" specified but pointed different files`

O ESP-IDF converte caminhos que contêm espaço para o formato antigo 8.3
(`C:\Users\Joao Silva` vira `C:\Users\JOAOSI~1`). O gcc então recebe a mesma
biblioteca por dois nomes diferentes e recusa compilar.

Por isso o `painel.ps1` força o toolchain e a build para fora do perfil:

```
ESPHOME_ESP_IDF_PREFIX = C:\esp\idf
ESPHOME_BUILD_PATH     = C:\esp\build
```

**Sempre compile pelo `painel.ps1`.** Chamando o `esphome.exe` direto, sem
essas variáveis, o erro volta.

### `Couldn't find ID 'esphome_img'`

Seu bloco `image:` está na sintaxe curta (mapa). Ela não faz merge com a lista
de imagens do pacote `pages/loading.yaml` e apaga as imagens da tela de boot.
Use a forma de lista:

```yaml
image:
  - platform: file
    type: RGB565
    transparency: alpha_channel
    file: "custom/minha_imagem.png"
    id: minha_imagem
    resize: 64x64
```

### A tela fica preta mas o painel responde

O `rotation` do board. Neste modelo **só `"0"` funciona** — `180` deixa a tela
preta. Está fixo no `packages: hardware: vars: rotation: "0"`.

### O primeiro toque não faz nada

É proposital. Com a tela apagada pelo timeout, o primeiro toque só acende a
tela — ele não passa para o botão embaixo. Evita ligar uma luz sem querer ao
encostar no painel.

### Sem logs pela serial

O `logger:` está com `baud_rate: 0`, que desliga a serial para economizar CPU.
Para depurar por cabo, comente essa linha e regrave. Ou use os logs por Wi-Fi:

```powershell
.\painel.ps1 logs-wifi -Config painel-minimo.yaml
```

---

## 7. Previsão do tempo (opcional)

A página de previsão precisa de uma automação no HA, porque a entidade
`weather.*` não expõe os próximos dias como atributo — só pelo serviço
`weather.get_forecasts`. O painel publica uma action `set_forecast` e o HA
empurra os 5 dias.

Está pronta em `ha-automacao-previsao.yaml`. Ajuste o nome da sua entidade de
clima e o nome do painel, e cole em **Configurações → Automações → Criar →
Editar em YAML**.

---

## 8. O que tem em cada arquivo

```
painel-esp32/
├── instalar.ps1                  rode uma vez
├── painel.ps1                    compile / flash / ota / logs
├── ha-automacao-previsao.yaml    automação do HA para a previsão
└── esphome/
    ├── painel-minimo.yaml        COMECE POR AQUI
    ├── painel.yaml               exemplo completo: 42 entidades, 8 páginas
    ├── secrets.example.yaml      copie para secrets.yaml
    ├── custom/                   os blocos reutilizáveis
    └── extras/                   páginas prontas de impressora 3D,
                                  aspirador robô e uso do Claude
```

O `painel.yaml` é um exemplo completo de escritório: luzes em grade 3×4,
4 ar-condicionados, página de segurança com alarme e sensores de porta,
temperaturas e geração solar. Serve de referência para montar o seu — copie
os pedaços que fizerem sentido.

Em `extras/` estão três páginas que não entraram nesse painel mas funcionam:
impressora 3D, aspirador robô com seleção de cômodos, e uso da
assinatura do Claude. Para usar, mova para `custom/` e inclua em `packages:`.

---

## Créditos

- **[agillis/esphome-modular-lvgl-buttons](https://github.com/agillis/esphome-modular-lvgl-buttons)**
  — a base de tudo: arquivos de hardware, tema, tela de boot, backlight,
  navegação por swipe.
- Os blocos `tile_switch`, `tile_climate`, `tile_cover`, `row_switch`,
  `chip_zone`, `page_weather` e as páginas em `extras/` vieram do painel de um
  amigo, que montou o design "laranja" em cima do repo do agillis.
- Os blocos `tile_nav`, `tile_alarm`, `tile_light_sm`, `row_binary`,
  `row_sensor` e `row_text` foram feitos depois, para cobrir entidades de
  leitura (portas, presença, sensores, alarme) que o repo original não tinha.
