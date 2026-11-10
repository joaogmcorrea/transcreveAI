# Scripts & Lógica — TranscreveAI

> **Para Agentes de IA:** Este documento mapeia **todos os arquivos de script** do projeto e descreve o que cada um faz. **Consulte antes de modificar qualquer código** e **atualize ao criar/alterar arquivos**.

---

## Status: v0.3.0 — Esqueleto do app de menu bar (10/11/2026)

O app existe em `files/`: o ícone na barra de menus, o painel com a área de arrastar (no painel e no ícone), os menus de modelo e idioma, os Ajustes e as atualizações pelo Sparkle (mesma lógica do Cutline). Ainda não transcreve (v0.4). O instalador sai do `_dev/distribuir.sh`.

---

## Scripts de Projeto (`_docs/`)

| Arquivo | Tipo | Descrição |
|---------|------|-----------|
| `_docs/versionar.sh` | Bash | Versionamento via git local. Uso: `./_docs/versionar.sh <X.Y.Z> ["mensagem"]`. Inicializa o repositório se necessário, faz `git add -A`, cria o commit e a tag anotada `vX.Y.Z`. Falha se a tag já existir. Exclusões ficam no `.gitignore`. |
| `_dev/distribuir.sh` | Bash | Instalador e atualizações (mesma lógica do Cutline). Compila em Release (DerivedData `TranscreveAI-dist`). Assina com o certificado "TranscreveAI" do Acesso às Chaves, se houver (Sparkle de dentro para fora), ou ad-hoc. Monta `_dev/dist/TranscreveAI-<v>.dmg` (app + atalho para Aplicativos), assina o DMG com a chave EdDSA de `_privado/` (`sign_update --ed-key-file`) e escreve `appcast.xml` (com `novidades-<v>.<idioma>.md` em Markdown), mais uma cópia `appcast-<v>.xml` para cada versão já lançada. `--publicar` cria a release `v<v>` no GitHub com o DMG, a cópia `TranscreveAI.dmg` (nome fixo) e os appcasts; as notas vêm de `notas-<v>.md`. |

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

## Projeto Xcode (`files/`)
Swift 6, isolamento padrão `MainActor`, macOS 26+, sem sandbox, assinatura ad-hoc. Pasta sincronizada: todo arquivo novo dentro de `files/TranscreveAI/` entra no alvo sozinho, sem mexer no `project.pbxproj`. Compilar pela linha de comando: `xcodebuild -project files/TranscreveAI.xcodeproj -scheme TranscreveAI -configuration Debug build`.

| Arquivo | Tipo | Descrição |
|---------|------|-----------|
| `files/TranscreveAI.xcodeproj` | Xcode | Alvo `TranscreveAI` (`io.github.joaogmcorrea.transcreveai`). `MARKETING_VERSION` fica no **projeto** (Debug e Release) e o `CURRENT_PROJECT_VERSION` acompanha: é ele que o Sparkle compara. Dependência SPM: Sparkle 2.10.1. `LSUIElement = YES` (sem Dock). |
| `files/TranscreveAI-Info.plist` | Plist | Mesclado com o gerado pelo Xcode. Sparkle (`SUFeedURL` = `releases/latest/download/appcast-$(MARKETING_VERSION).xml`, `SUPublicEDKey`, verificação antes de extrair) e `CFBundleDocumentTypes` (áudio/vídeo, para "Abrir com"). Fica fora de `TranscreveAI/` para a pasta sincronizada não copiá-lo como recurso. |

---

## App (`files/TranscreveAI/App/`)
Entrada do app, estado compartilhado e atualizações.

| Arquivo | Tipo | Descrição |
|---------|------|-----------|
| `TranscreveAIApp.swift` | Swift | `@main`, só com a cena `Settings` vazia (exigida pelo SwiftUI). O app de verdade começa no `AppDelegate`. |
| `AppDelegate.swift` | Swift | Liga o Sparkle (`Atualizacoes.controlador`) e cria a `BarraDeMenus`. `application(_:open:)` recebe os arquivos de "Abrir com". Argumentos de teste: `--abrir-painel`, `--arquivo <caminho>` e `--menu-icone` (abre o menu do botão direito). |
| `EstadoApp.swift` | Swift | `@Observable`: `arquivo` (`ArquivoAudio`: url, duração, tamanho) e `aviso`. `receber(_:)` aceita o primeiro áudio da lista e lê a duração em segundo plano. |
| `Atualizacoes.swift` | Swift | Sparkle 2, mesma lógica do Cutline. `SPUStandardUpdaterController` que só inicia fora do DEBUG (`Atualizacoes.ativo`). `LembretesDeAtualizacao` liga os "lembretes discretos" (app sem Dock) e ativa o app antes de mostrar a janela da atualização. |

---

## UI (`files/TranscreveAI/UI/`)
Ícone e painel da barra de menus (mockup, página "Menu bar"). Futuramente: progresso no ícone, transcrição clicável, recentes e anel de ações.

| Arquivo | Tipo | Descrição |
|---------|------|-----------|
| `BarraDeMenus.swift` | Swift (AppKit) | `NSStatusItem` com o símbolo `waveform` (template). A ação dispara no mouse down (`sendAction(on:)`). Clique esquerdo alterna o painel; botão direito ou Control + clique mostra o menu curto (Procurar atualizações…, Abrir ao iniciar o Mac, Sair), com o truque `item.menu = menu; performClick; item.menu = nil`. **Abrir ao arrastar:** com o `DetectorDeArraste`, abre o painel sem ativar o app quando um áudio começa a ser arrastado (preferência `abrirAoArrastar`, ligada por padrão) e fecha 0,5 s depois de soltar se o arquivo não veio para o painel nem para o ícone. **Soltar no ícone:** a janela do ícone é registrada para `.fileURL` e tem esta classe como delegate (`NSDraggingDestination`). Fecha com Esc ou clique fora (monitor global). Só conta o clique que começou fora do ícone depois que o painel abriu, porque o monitor global também recebe o clique do próprio ícone no macOS 26+. Um clique fora que vira arraste não fecha. Abre o seletor de arquivos, as atualizações e a janela de Ajustes. `mostrarPainel` tenta de novo enquanto o ícone ainda não tem posição na tela. |
| `DetectorDeArraste.swift` | Swift (AppKit) | Monitor global de mouse (sem Acessibilidade). A cada clique guarda o `changeCount` de `NSPasteboard(name: .drag)`; no primeiro `leftMouseDragged` em que ele mudou, lê as URLs de arquivo e, se houver áudio, chama `aoComecar`. No `leftMouseUp`, chama `aoTerminar`. Arquivos "prometidos" (Mail, alguns navegadores) ainda não contam. |
| `PainelFlutuante.swift` | Swift (AppKit) | `NSPanel` sem borda (nível `popUpMenu`) com `NSVisualEffectView` (`.popover`) e máscara de cantos de 16 pt. Largura fixa de 380. A altura segue o conteúdo SwiftUI (`onGeometryChange`) e o topo fica preso 6 pt abaixo do ícone. |
| `PainelView.swift` | SwiftUI | Cabeçalho (nome do app ou do arquivo e o menu "…", com Copiar ao terminar, Abrir ao arrastar um áudio, Abrir ao iniciar o Mac, Procurar atualizações…, Ajustes… e Sair), área tracejada (`dropDestination` e clique), menus de modelo e de idioma. Com arquivo: "Áudio recebido", Novo e Mostrar no Finder; durante um arraste, o painel inteiro mostra "Solte para transcrever". |
| `AjustesView.swift` | SwiftUI | Janela de Ajustes: "Procurar atualizações automaticamente" (ajuste do Sparkle), versão e "Procurar agora". Desligado no DEBUG. |

---

## Audio (`files/TranscreveAI/Audio/`)
Leitura e decodificação: AVFoundation primeiro, FFmpeg para formatos não nativos (a partir da v0.4); conversão para o formato PCM pedido pelo motor.

| Arquivo | Tipo | Descrição |
|---------|------|-----------|
| `FormatosAudio.swift` | Swift | `aceita(_:)` (UTType `audio`/`audiovisualContent` + extensões extras: opus, ogg, webm, wma, mkv…), `tipos` para o seletor, `duracao(de:)` (AVURLAsset; o Opus do WhatsApp também é lido) e `formatar(duracao:)`. |

---

## Transcription (`files/TranscreveAI/Transcription/`)
Motores de transcrição (Apple Speech, WhisperKit, Parakeet) atrás de uma interface comum, benchmark local e seleção do modo "Automático".

| Arquivo | Tipo | Descrição |
|---------|------|-----------|
| _(nenhum arquivo ainda)_ | | |

---

## Export (`files/TranscreveAI/Export/`)
Geração de `.txt` (só texto) e `.md` (título, metadados e `[mm:ss]` por parágrafo).

| Arquivo | Tipo | Descrição |
|---------|------|-----------|
| _(nenhum arquivo ainda)_ | | |

---

## Storage (`files/TranscreveAI/Storage/`)
Histórico de transcrições, preferências e resultados de benchmark em Application Support.

| Arquivo | Tipo | Descrição |
|---------|------|-----------|
| `Preferencias.swift` | Swift | Chaves do UserDefaults (`Preferencia`), `ModeloTranscricao` (Automático, Parakeet v3, Apple Speech, Whisper Turbo; nome, rótulo curto, descrição, motor efetivo), `IdiomaAudio` e `InicioAutomatico` (`SMAppService.mainApp`). |

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
