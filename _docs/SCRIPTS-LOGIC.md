# Scripts & Lógica — TranscreveAI

> **Para Agentes de IA:** Este documento mapeia **todos os arquivos de script** do projeto e descreve o que cada um faz. **Consulte antes de modificar qualquer código** e **atualize ao criar/alterar arquivos**.

---

## Status: v0.2.0 — Benchmark de motores (10/11/2026)

Ainda não há código do app. Existem a documentação em `_docs/`, o script de versionamento e o benchmark de motores em `_testes/benchmark/`. O código Swift ficará em `files/` (projeto Xcode a criar), dividido nas camadas abaixo. Preencha cada tabela quando os primeiros arquivos existirem.

---

## Scripts de Projeto (`_docs/`)

| Arquivo | Tipo | Descrição |
|---------|------|-----------|
| `_docs/versionar.sh` | Bash | Versionamento via git local. Uso: `./_docs/versionar.sh <X.Y.Z> ["mensagem"]`. Inicializa o repositório se necessário, faz `git add -A`, cria o commit e a tag anotada `vX.Y.Z`. Falha se a tag já existir. Exclusões ficam no `.gitignore`. |

---

## Testes — Benchmark de motores (`_testes/benchmark/`)
Mede a velocidade e a qualidade de cada motor em pt-BR. Build, modelos e WAVs ficam em `~/Library/Caches/TranscreveBench`, fora do Dropbox. Os resultados vão para `_testes/resultados/` (fora do git).

| Arquivo | Tipo | Descrição |
|---------|------|-----------|
| `_testes/benchmark/Package.swift` | Swift (SPM) | Pacote `TranscreveBench`, macOS 26+. Dependências: WhisperKit 1.1.1 e FluidAudio 0.18.3. |
| `_testes/benchmark/Sources/bench/main.swift` | Swift | CLI `bench <motor> <audio.wav> <saida>`, com motores `apple` (SpeechAnalyzer/SpeechTranscriber pt-BR), `parakeet` (FluidAudio TDT v3), `whisper-turbo` e `whisper-large` (WhisperKit, VAD chunking, greedy). Grava `<motor>.txt` e `<motor>.json` (carga, transcrição, × tempo real). `bench wer <ref> <hip>` calcula o WER por palavras. |
| `_testes/benchmark/rodar.sh` | Bash | `preparar` compila, baixa os modelos (incluindo o ggml do whisper.cpp) e aquece cada motor com um áudio sintético. Sem argumento: converte cada áudio de `_testes/audios/` para WAV 16 kHz mono (`ffmpeg`), roda todos os motores, mais o `whisper-cli` como base, medindo a memória com `/usr/bin/time -l`, e gera o relatório. Variável `MOTORES` filtra os motores. |
| `_testes/benchmark/relatorio.py` | Python 3 (stdlib) | Gera `_testes/resultados/relatorio.md` com o resumo, as tabelas por áudio e a sugestão para o "Automático" (mais rápido com erro até 3 pp acima do melhor). Usa `referencia.txt` (WER real) ou, sem ela, a divergência vs. Whisper Large v3. |

---

## App (`files/App/`)
Entrada do app, `MenuBarExtra`, ícone/status item (incluindo progresso no ícone e arrastar sobre ele).

| Arquivo | Tipo | Descrição |
|---------|------|-----------|
| _(nenhum arquivo ainda)_ | | |

---

## UI (`files/UI/`)
Painel da barra de menus (arrastar, progresso, prévia ao vivo, transcrição clicável, recentes), menus de modelo/idioma/opções e anel de ações.

| Arquivo | Tipo | Descrição |
|---------|------|-----------|
| _(nenhum arquivo ainda)_ | | |

---

## Audio (`files/Audio/`)
Leitura e decodificação: AVFoundation primeiro, FFmpeg para formatos não nativos; conversão para o formato PCM pedido pelo motor.

| Arquivo | Tipo | Descrição |
|---------|------|-----------|
| _(nenhum arquivo ainda)_ | | |

---

## Transcription (`files/Transcription/`)
Motores de transcrição (Apple Speech, WhisperKit, Parakeet) atrás de uma interface comum, benchmark local e seleção do modo "Automático".

| Arquivo | Tipo | Descrição |
|---------|------|-----------|
| _(nenhum arquivo ainda)_ | | |

---

## Export (`files/Export/`)
Geração de `.txt` (só texto) e `.md` (título, metadados e `[mm:ss]` por parágrafo).

| Arquivo | Tipo | Descrição |
|---------|------|-----------|
| _(nenhum arquivo ainda)_ | | |

---

## Storage (`files/Storage/`)
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
