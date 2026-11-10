# Scripts & Lógica — TranscreveAI

> **Para Agentes de IA:** Este documento mapeia **todos os arquivos de script** do projeto e descreve o que cada um faz. **Consulte antes de modificar qualquer código** e **atualize ao criar/alterar arquivos**.

---

## Status: Setup Inicial / v0.1.0 (10/11/2026)

Ainda não há código-fonte. Existem apenas a documentação em `_docs/` e o script de versionamento. O código Swift ficará em `TranscreveAI/` (projeto Xcode a criar), dividido nas camadas abaixo. Preencha cada tabela quando os primeiros arquivos existirem.

---

## Scripts de Projeto (`_docs/`)

| Arquivo | Tipo | Descrição |
|---------|------|-----------|
| `_docs/versionar.sh` | Bash | Versionamento via git local. Uso: `./_docs/versionar.sh <X.Y.Z> ["mensagem"]`. Inicializa o repositório se necessário, faz `git add -A`, cria o commit e a tag anotada `vX.Y.Z`. Falha se a tag já existir. Exclusões ficam no `.gitignore`. |

---

## App (`TranscreveAI/App/`)
Entrada do app, `MenuBarExtra`, ícone/status item (incluindo progresso no ícone e arrastar sobre ele).

| Arquivo | Tipo | Descrição |
|---------|------|-----------|
| _(nenhum arquivo ainda)_ | | |

---

## UI (`TranscreveAI/UI/`)
Painel da barra de menus (arrastar, progresso, prévia ao vivo, transcrição clicável, recentes), menus de modelo/idioma/opções e anel de ações.

| Arquivo | Tipo | Descrição |
|---------|------|-----------|
| _(nenhum arquivo ainda)_ | | |

---

## Audio (`TranscreveAI/Audio/`)
Leitura e decodificação: AVFoundation primeiro, FFmpeg para formatos não nativos; conversão para o formato PCM pedido pelo motor.

| Arquivo | Tipo | Descrição |
|---------|------|-----------|
| _(nenhum arquivo ainda)_ | | |

---

## Transcription (`TranscreveAI/Transcription/`)
Motores de transcrição (Apple Speech, WhisperKit, Parakeet) atrás de uma interface comum, benchmark local e seleção do modo "Automático".

| Arquivo | Tipo | Descrição |
|---------|------|-----------|
| _(nenhum arquivo ainda)_ | | |

---

## Export (`TranscreveAI/Export/`)
Geração de `.txt` (só texto) e `.md` (título, metadados e `[mm:ss]` por parágrafo).

| Arquivo | Tipo | Descrição |
|---------|------|-----------|
| _(nenhum arquivo ainda)_ | | |

---

## Storage (`TranscreveAI/Storage/`)
Histórico de transcrições, preferências e resultados de benchmark em Application Support.

| Arquivo | Tipo | Descrição |
|---------|------|-----------|
| _(nenhum arquivo ainda)_ | | |

---

## Assets

| Arquivo | Descrição |
|---------|-----------|
| _(a criar: `Assets.xcassets` com ícone do app e ícone template da barra de menus)_ | |

---

## Fluxo de Dados

```
Transcrição
Áudio (arrastar no ícone/painel, Finder, anel) → Audio (AVFoundation | FFmpeg → PCM) → Transcription (motor ativo; Automático = mais rápido) → Segmentos com tempo → UI (prévia ao vivo, lista clicável) + Storage (histórico)

Ao terminar
Segmentos → "Copiar ao terminar" (área de transferência) → Notificação (se o painel estiver fechado)

Exportação
Transcrição → Export (.txt só texto | .md com título, metadados e [mm:ss]) → ~/Downloads (ou local escolhido)

Modo Automático
Primeiro uso / novo modelo instalado → benchmark curto local → BenchmarkModelo → Preferências (modelo mais rápido)
```

---

<!--
INSTRUÇÕES PARA ATUALIZAÇÃO:
- Ao adicionar arquivo, prefixar com o caminho a partir da pasta principal.
- Ao alterar a função de um arquivo, atualize a descrição.
-->
