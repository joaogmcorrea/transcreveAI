# Scripts & Lógica — TranscreveAI

> **Para Agentes de IA:** Este documento mapeia **todos os arquivos de script** do projeto e descreve o que cada um faz. **Consulte antes de modificar qualquer código** e **atualize ao criar/alterar arquivos**.

---

## Status: v0.5.0 — Texto ao vivo, botão direito do Finder e fila (18/11/2026)

O app transcreve: Parakeet v3 no "Automático", com o Apple Speech de reserva enquanto o Parakeet baixa. O painel mostra o progresso e o texto em parágrafos com tempo, que aparece enquanto o resto é transcrito (os dois motores entregam aos poucos, *17/11/2026*). *(17/11/2026)* Botão direito do Finder (extensão `TranscreveFinder`: Copiar o texto / Exportar como .txt) e fila de vários áudios. O ícone da barra mostra o anel de progresso, um ✓ e a bolinha vermelha de "não visto". Os formatos que o macOS não abre passam pelo FFmpeg embutido. Os motores ficam no pacote local `files/Pacotes/TranscreveMotores`. *(14/11/2026)* A interface fala português, inglês e espanhol (catálogos `.xcstrings`), clicar no texto copia tudo, e o site em `_site/` é montado para o servidor pelo `gerar.py`.

---

## Scripts de Projeto (`_docs/`)

| Arquivo | Tipo | Descrição |
|---------|------|-----------|
| `_docs/versionar.sh` | Bash | Versionamento via git local. Uso: `./_docs/versionar.sh <X.Y.Z> ["mensagem"]`. Inicializa o repositório se necessário, faz `git add -A`, cria o commit e a tag anotada `vX.Y.Z`. Falha se a tag já existir. Exclusões ficam no `.gitignore`. |
| `_dev/distribuir.sh` | Bash | Instalador e atualizações (mesma lógica do Cutline). Compila em Release (DerivedData `TranscreveAI-dist`). Assina com o certificado "TranscreveAI" do Acesso às Chaves, se houver (Sparkle e a extensão do Finder de dentro para fora, mantendo o sandbox dela; *17/11/2026*), ou ad-hoc. Monta `_dev/dist/TranscreveAI-<v>.dmg` (app + atalho para Aplicativos), assina o DMG com a chave EdDSA de `_privado/` (`sign_update --ed-key-file`) e escreve `appcast.xml` (com `novidades-<v>.<idioma>.md` em Markdown), mais uma cópia `appcast-<v>.xml` para cada versão já lançada. `--publicar` cria a release `v<v>` no GitHub com o DMG, a cópia `TranscreveAI.dmg` (nome fixo) e os appcasts; as notas vêm de `notas-<v>.md`. |
| `_dev/ffmpeg/compilar.sh` | Bash | Compila o FFmpeg mínimo do app (versão fixa no script; LGPL 2.1, sem `--enable-gpl` nem bibliotecas externas). Só os demuxers e decoders de áudio, o muxer WAV e o `pcm_s16le`, arm64 + x86_64 (`--disable-x86asm`), `lipo`, `strip`. Saída em `files/Vendor/ffmpeg/` (binário versionado + `LICENSE-ffmpeg.txt` + `VERSAO`). Fonte e compilação em `~/Library/Caches/TranscreveAI-ffmpeg`. |
| `_dev/gifs/animacoes.swift` | Swift (AppKit) | *(18/11/2026: no estado "transcrevendo", os parágrafos aparecem conforme o progresso — `aparecidos`, `alturaDosAparecidos` — e `saindo` faz a barra sumir e a caixa subir até o lugar do resultado; a cena `soltar` ganhou o passo "Read it while it transcribes".)* *(10/11/2026)* Desenha, quadro a quadro, as 3 animações do README em estilo de vídeo-tutorial flat (`soltar`, `dock`, `painel-fechado`): mesa, barra de menus, Finder, Dock e um painel que imita `PainelView.swift` (textos, medidas, estados vazio/arrastando/transcrevendo/pronto) e o ícone da barra (anel, %, ✓, bolinha). Linha do tempo por cena com `fase`/`suave`/`mola`, cursor por `Trecho` (curva quadrática), legendas de passo e interface desenhada em inglês *(11/11/2026, pedido do owner: o README é em inglês; o app real continua em português)*. 800×500 pt a 2×, 25 quadros/s; o fim cruza com o primeiro quadro para o GIF repetir sem salto. Textos das transcrições inventados. `QUADRO=<s>` desenha só um quadro (`previa.png`) para conferir. |
| `_dev/gifs/gerar.sh` | Bash | Compila o `animacoes.swift`, desenha os quadros em `~/Library/Caches/TranscreveAI-gifs/quadros/` e monta `_dev/gifs/<nome>.gif` com o FFmpeg (1200 px, paleta de 128 cores, *dither* bayer 5: cerca de 2 MB cada; 2,3 MB desde a v0.5.0. Animação que mexe no painel em todo quadro faz o GIF crescer muito). Argumentos opcionais escolhem as animações. **Refazer quando a interface do painel ou do ícone mudar.** |
| `_site/index.html` (+ `_site/cutline.png`) | HTML + CSS + JS | *(18/11/2026: imita a v0.5.0. Transcrevendo e pronto são uma caixa só, como a `Leitura` do app: os parágrafos aparecem enquanto a barra anda (`step` revela por fração do tempo, `S.seen` evita repetir a animação e a rolagem é mantida); clicar copia o que já saiu; no fim, `settle` encolhe a barra e a caixa fica. Fila: `receive(keys, dest, place)` com `S.queue`, `S.batch` ("Transcrevendo 2 de 3…", "Na fila: …", ícone com o progresso da leva) e `S.note` no fim. Botão direito (`showContext`, submenu em `openSub`) nos áudios da mesa e do Finder: Copiar o texto / Exportar como .txt sem abrir o painel (✓ sem bolinha); `exportTxt` põe `<nome>.txt` (ou `<nome> 2.txt`) ao lado do áudio, e dois cliques nele abrem o TextEdit. Seleção de vários (⌘/Shift + clique, ⌘A), arrastar vários (`.ghost .count`) e segurar o dedo no celular. Linha do Finder em Ajustes › Geral (`S.prefs.finderExt`).)* *(11/11/2026)* O site, num arquivo só: uma mesa de macOS escura que se usa, no estilo do vorssaint.com. Textos dos três idiomas no objeto `T` do script (nada em inglês fixo no HTML, só o `<main>` escondido para leitores de tela e buscadores); idioma por `?lang=`, depois a escolha salva, depois o navegador. `AUDIO` tem os três exemplos (texto inventado; `secs` = o tempo que o app levou de verdade), `FILES` e `FOLDERS` montam a mesa, o Finder e a pilha do Dock. `S` guarda o estado do app imitado (rodando, painel, trabalho, histórico, preferências com os padrões do app). Arrastar: `bindItem` (mouse e toque); dois cliques (ou um toque, ou um clique na pilha) abrem; o painel abre sozinho ao arrastar um áudio se "Abrir ao arrastar" estiver ligado. Um arquivo de verdade solto na página não é lido nem enviado. Versão do app pela API do GitHub. Ao mudar a interface do app (painel, menus, Ajustes), atualizar aqui também. Prévia: `python3 -m http.server --directory _site`. *(14/11/2026)* No site publicado, o `<html>` traz `data-root` (caminho até a raiz) e, em `/pt/` e `/es/`, `data-lang`: o idioma sai de `?lang=`, depois da URL, depois da escolha salva, depois do navegador; escolher no menu muda a URL (`history.replaceState`). `BASE`/`CUTLINE_PNG` são fixados na abertura, para imagens montadas depois da troca de URL não apontarem para a pasta errada. Sem `data-root` (a prévia da fonte), a URL não muda. |
| `_site/gerar.py` | Python 3 (stdlib) | *(14/11/2026)* Monta o site publicável em `_site/dist/` e `_site/transcreveai-site.zip` (fora do git). Para cada idioma de `PAGES` (en `/`, pt `/pt/`, es `/es/`): troca o cabeçalho (título, descrição, `canonical`, `hreflang`, ícones, Open Graph/Twitter com a imagem do idioma, JSON-LD com `SoftwareApplication`), o `<html lang>` + `data-lang`/`data-root`, o `<main class="sr-only">` e, nas subpastas, o caminho do `cutline.png`. Para se a página não tiver um trecho esperado (`take`). Versão de reserva pela API do GitHub. Escreve `robots.txt`, `sitemap.xml` (com `hreflang`), `llms.txt`, `site.webmanifest` e o `.htaccess` (sem listagem, cabeçalhos de segurança, cache: HTML sempre confere, imagens uma semana; HTTPS fica com o Cloudflare). `--site` troca o endereço (padrão `SITE`); `--imagens` roda o `imagens.mjs` antes. Passos para subir: `_site/PUBLICAR.md`. |
| `_site/imagens.mjs` | Node 24 (sem dependências) | *(14/11/2026)* Desenha `_site/imagens/` com o Chrome sem janela pelo protocolo do DevTools (WebSocket embutido do Node): ícones a partir da marca do favicon (`favicon.ico` com 16/32/48 em PNG, `favicon-96`, `apple-touch-icon` 180 sem cantos, `icon-192`, `icon-512`) e as imagens de compartilhamento `og-image(-pt\|-es).png` (1200×630 = 960×504 a 1,25×): serve `_site/` num servidor local, abre `?lang=`, dá dois cliques de verdade no áudio da mesa, espera a transcrição terminar (o botão "Novo", `[data-new]`; desde a v0.5.0 a caixa de texto aparece antes do fim) e fotografa (com a área de transferência liberada, sai o aviso "Copiado"). Sem ganchos de teste na página. `CHROME=` troca o navegador. |
| `files/TranscreveAI/Localizable.xcstrings` (+ `InfoPlist.xcstrings` e o `Localizable.xcstrings` do pacote TranscreveMotores) | String Catalog | *(11/11/2026)* Os textos do app em pt-BR (origem, com valores explícitos), inglês e espanhol. Texto novo na interface: literal do SwiftUI ou `String(localized:)` (no pacote, `bundle: .module`), e a tradução en/es no catálogo. Nomes de produto (Parakeet v3, Apple Speech, Whisper) não se traduzem. |

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
| `files/TranscreveAI.xcodeproj` | Xcode | *(17/11/2026)* Segundo alvo, `TranscreveFinder` (a extensão do Finder), dependência do app e copiado para `Contents/PlugIns`. Alvo `TranscreveAI` (`io.github.joaogmcorrea.transcreveai`). `MARKETING_VERSION` fica no **projeto** (Debug e Release) e o `CURRENT_PROJECT_VERSION` acompanha: é ele que o Sparkle compara. Dependências SPM: Sparkle 2.10.1 e o pacote local `Pacotes/TranscreveMotores`. Fase "Copiar FFmpeg": `Vendor/ffmpeg/ffmpeg` → `Contents/Helpers/` com *Code Sign On Copy*. `LSUIElement = YES` (sem Dock). |
| `files/Vendor/ffmpeg/` | Binário | FFmpeg mínimo universal gerado por `_dev/ffmpeg/compilar.sh`, com a licença LGPL e a versão. Não editar à mão: recompilar pelo script. |
| `files/TranscreveAI-Info.plist` | Plist | *(17/11/2026)* `CFBundleURLTypes` com o esquema `transcreveai` (pedidos da extensão do Finder). Mesclado com o gerado pelo Xcode. Sparkle (`SUFeedURL` = `releases/latest/download/appcast-$(MARKETING_VERSION).xml`, `SUPublicEDKey`, verificação antes de extrair) e `CFBundleDocumentTypes` (áudio/vídeo, para "Abrir com"). Fica fora de `TranscreveAI/` para a pasta sincronizada não copiá-lo como recurso. |

---

## Motores (`files/Pacotes/TranscreveMotores/`)
Pacote Swift local (Swift 6, sem isolamento padrão: o trabalho pesado fica fora da main thread). Depende do FluidAudio com `traits: []` (só reconhecimento de fala; sem TTS, separação de falantes e a normalização de texto de 57 MB). Testar pelo terminal: `swift run --package-path files/Pacotes/TranscreveMotores --scratch-path ~/Library/Caches/TranscreveAI-motores transcrever <áudio> [parakeet|apple] [idioma]`. Com `TRANSCREVE_FRASES=1`, mostra as frases com os tempos.

| Arquivo | Tipo | Descrição |
|---------|------|-----------|
| `Package.swift` | Swift (SPM) | Biblioteca `TranscreveMotores` e o executável `transcrever`. |
| `Sources/TranscreveMotores/Modelos.swift` | Swift | `Segmento` (início, fim, texto), `Motor` (parakeet, apple), `Etapa` (convertendo, preparandoModelo, transcrevendo(fração)), `Progresso` (etapa + prévia: as frases que já saíram, nos dois motores) e `ErroDeTranscricao` (mensagens em pt-BR). |
| `Sources/TranscreveMotores/LeitorDeAmostras.swift` | Swift | *(17/11/2026)* Lê o áudio aos poucos já em 16 kHz mono Float32 (`proximoBloco()`, cerca de 1 s por vez; `acabou`). Mistura os canais em mono e usa um único `AVAudioConverter` na qualidade padrão, como o FluidAudio faz nos áudios de mais de 30 s (a "Mastering" deixava a leitura tão lenta quanto a transcrição). Leitura que falha no finalzinho de MP3/AAC conta como fim. |
| `Sources/TranscreveMotores/AudioDeEntrada.swift` | Swift | `preparar(_:ffmpeg:)`: usa o arquivo direto se o `AVAudioFile` abrir (no macOS 27: MP3, M4A/AAC, MP4/MOV, WAV, AIFF, FLAC, OGG, Opus). Senão, converte para WAV 16 kHz mono temporário com o FFmpeg (`Process`). `AudioPronto.descartar()` apaga o temporário. |
| `Sources/TranscreveMotores/MotorParakeet.swift` | Swift (actor) | `MotorParakeet.compartilhado`. O modelo fica em `~/Library/Application Support/TranscreveAI/Modelos/parakeet-tdt-0.6b-v3` (~470 MB). `baixado`/`pronto`; `preparar(progresso:)` baixa e carrega uma vez (chamadas simultâneas esperam o mesmo preparo; `Preparo.baixando(fração)` ou `.compilando`). *(17/11/2026)* `transcrever` trabalha aos pedaços: `Pedacos` corta o áudio (lido pelo `LeitorDeAmostras`) com as emendas no trecho de 200 ms mais quieto dos 5 s antes do alvo (14 s, depois 4 min, depois 10 min); cada pedaço leva 1 s a mais de cada lado e passa inteiro pelo `AsrManager.transcribe([Float])`. O próximo pedaço é lido numa tarefa separada enquanto o atual é transcrito (o cortador passa de uma tarefa à outra, nunca em duas ao mesmo tempo). De cada pedaço ficam as palavras que começam entre as suas emendas; `Emenda.costurar` tira a palavra repetida dos dois lados e copia a caixa (maiúscula/minúscula) que o pedaço anterior deu à primeira palavra. Os tokens do FluidAudio já vêm com espaço no lugar do "▁". A cada pedaço, as frases são refeitas de todos os tokens e vão no `Progresso`. |
| `Sources/TranscreveMotores/MotorApple.swift` | Swift | `SpeechTranscriber` (preset `.transcription`) + `SpeechAnalyzer`. Idioma `nil` = **pt-BR** (não detecta sozinho; usar o idioma do sistema errava num Mac em inglês). Instala o idioma pelo `AssetInventory` se faltar. Entrega frases aos poucos (prévia e progresso pelo fim de cada frase). Devolve à frase anterior o ponto que chega no começo da seguinte. Cancelável. |
| `Sources/TranscreveMotores/Paragrafos.swift` | Swift | `frases(tokens:)`: tokens SentencePiece ("▁" = começo de palavra) viram frases, fechadas em `.?!…` ou numa pausa de mais de 1,2 s; pontuação solta gruda na frase anterior. `agrupar(_:)`: parágrafos quebrados numa pausa de 1,2 s ou a cada ~300 caracteres. `texto(_:)`: texto corrido. |
| `Sources/transcrever/main.swift` | Swift | O comando de teste. Usa o FFmpeg de `TRANSCREVE_FFMPEG` ou do Homebrew. Mostra também quando o primeiro texto apareceu *(17/11/2026)*. |

---

## App (`files/TranscreveAI/App/`)
Entrada do app, estado compartilhado e atualizações.

| Arquivo | Tipo | Descrição |
|---------|------|-----------|
| `TranscreveAIApp.swift` | Swift | `@main`, só com a cena `Settings` vazia (exigida pelo SwiftUI). O app de verdade começa no `AppDelegate`. |
| `AppDelegate.swift` | Swift | Liga o Sparkle (`Atualizacoes.controlador`), cria a `BarraDeMenus` e aquece o Parakeet (`estado.aquecerMotor()`). `application(_:open:)` recebe os arquivos de "Abrir com". *(17/11/2026)* Os pedidos do Finder (`transcreveai://copiar` ou `exportar`, `?arquivo=` repetido) chegam por um tratador do evento "abrir endereço" instalado em `applicationWillFinishLaunching`; só passam se o remetente (`keySenderPIDAttr` + `proc_pidpath`) estiver numa `.appex` com o identificador da extensão (`MenuDoFinder.ehAExtensao`), senão vai um registro de erro (categoria `finder`). `MenuDoFinder`: `ativo`, `abrirAjustesDoSistema()` e `ativarNaPrimeiraVez()` (`pluginkit -e use`, uma vez só, chave `menuDoFinderAtivado`). Argumentos de teste: `--abrir-painel`, `--arquivo <caminho…>` (painel aberto; vários = fila), `--arquivo-fundo <caminho>` (transcreve com o painel fechado), `--menu-icone`, `--ajustes` e `--historico`. |
| `EstadoApp.swift` | Swift | `@Observable`, conduz a transcrição. `fase`: `.vazio`, `.trabalhando(Trabalho)` (motor, etapa, `paragrafos` = o texto que já saiu, download), `.pronto(Transcricao)` (parágrafos, motor, segundos, copiado) e `.erro`. *(17/11/2026)* `receber(_:destino:)` com `Destino` (`.painel`; `.copiar` e `.exportarTxt`, do botão direito do Finder) e a `fila` de `Pedido`s: o primeiro começa; durante uma transcrição, todos entram no fim da fila. `terminou` passa ao próximo ou fecha a leva: som, `notaDaFila` (o que foi copiado ou exportado e o que falhou), `Fim.entregue` (copiado ou exportado pelo Finder: ✓ sem bolinha) ou `.erro` se algo falhou. `entregar` copia ("Copiar ao terminar" no painel; no Finder, vários áudios vão juntos com o nome em cima) ou exporta (`Exportacao.txt`). `posicaoNaFila` ("2 de 3"); o ícone recebe o progresso da leva inteira. Cada chamada a um motor tem uma `rodada`: avisos de progresso atrasados de outro áudio (ou do Parakeet depois que o Apple Speech assumiu) são ignorados. `recebimentos` conta as entregas aceitas. `copiarResultado()` (clique no texto) copia também durante a transcrição (o que já saiu); `copiar(_:)` (histórico) e o fim com cópia chamam `avisarCopiado()` ("Copiado" por 2 s). Automático: Parakeet se `pronto` ou `baixado`; senão Apple Speech e `baixarParakeetEmSegundoPlano()` (`notaDoModelo`); se o Parakeet falhar, o Apple Speech tenta. `beginActivity` (sem App Nap nem sono durante a transcrição). Guarda cada resultado no `Historico`; `abrir(_:)` reabre uma transcrição guardada, `mostrandoHistorico` alterna o painel para a lista. FFmpeg: `Contents/Helpers/ffmpeg` (no DEBUG, o do Homebrew de reserva). |
| `Atualizacoes.swift` | Swift | Sparkle 2, mesma lógica do Cutline. `SPUStandardUpdaterController` que só inicia fora do DEBUG (`Atualizacoes.ativo`). `LembretesDeAtualizacao` liga os "lembretes discretos" (app sem Dock) e ativa o app antes de mostrar a janela da atualização. |

---

## UI (`files/TranscreveAI/UI/`)
Ícone e painel da barra de menus (mockup, página "Menu bar"). Futuramente: progresso no ícone, transcrição clicável, recentes e anel de ações.

| Arquivo | Tipo | Descrição |
|---------|------|-----------|
| `BarraDeMenus.swift` | Swift (AppKit) | *(17/11/2026)* `Fim.entregue` mostra o ✓ sem a bolinha vermelha; o painel aberto por um arraste fecha só se `recebimentos` não mudou (um áudio na fila não troca o arquivo atual); "Abrir arquivo…" aceita vários. `NSStatusItem` com o símbolo `waveform` (template). A ação dispara no mouse down (`sendAction(on:)`). Clique esquerdo alterna o painel; botão direito ou Control + clique mostra o menu curto (Procurar atualizações…, Ajustes…, Abrir ao iniciar o Mac, Sair), com o truque `item.menu = menu; performClick; item.menu = nil`. **Abrir ao arrastar:** com o `DetectorDeArraste`, abre o painel sem ativar o app quando um áudio começa a ser arrastado (preferência `abrirAoArrastar`, ligada por padrão) e fecha 0,5 s depois de soltar se o arquivo não veio para o painel nem para o ícone. **Progresso no ícone** (`variableLength`): com o painel fechado, anel desenhado (template) + " 63%"; ao terminar, ✓ por 4 s; depois, se a pessoa ainda não abriu o painel, uma **bolinha vermelha** (`NSView` vermelha por cima do botão, para o símbolo continuar template e na cor certa). **Soltar no ícone:** a janela do ícone é registrada para `.fileURL` e tem esta classe como delegate (`NSDraggingDestination`). Fecha com Esc ou **no mouse down** fora do painel (monitor global; cliques sobre o próprio ícone são ignorados ali, porque no macOS 26+ eles também chegam ao monitor). Quem arrasta um áudio do Finder até o painel aberto não perde nada: o painel reabre sozinho pelo "Abrir ao arrastar". Abre o seletor de arquivos, as atualizações e a janela de Ajustes. `mostrarPainel` tenta de novo enquanto o ícone ainda não tem posição na tela. |
| `DetectorDeArraste.swift` | Swift (AppKit) | Sem Acessibilidade. Enquanto o botão do mouse está pressionado (`NSEvent.pressedMouseButtons`, conferido a cada 50 ms; um vigia de 4×/s cobre o caso sem evento), dois caminhos: (1) **área de arraste comum**: se o `changeCount` de `NSPasteboard(name: .drag)` mudou desde o repouso (anotado com o botão solto, nunca no clique) e há áudio → `aoComecar` (Finder, Mesa, capturas de tela); (2) **apanhador**: se o clique caiu numa janela do **Dock** ou do **Finder** (dono pela `windowNumber` do evento ou pelo ponto na lista de janelas) e o ponteiro andou 6 pt, arma o `ApanhadorDeArraste`. Ao soltar: desarma e `aoTerminar`. `arquivos(em:)` lê `public.file-url` ou `NSFilenamesPboardType`. Registros em nível debug (categoria `arraste`). |
| `ApanhadorDeArraste.swift` | Swift (AppKit) | `NSPanel` transparente (alfa 0,01; alfa zero não recebe arraste), da tela inteira, nível `popUpMenu`, que não vira janela-chave. Aparece por um instante para *receber* o arraste do Dock, que usa uma área de arraste própria, invisível a outros programas: `draggingEntered` lê `draggingPasteboard`, avisa, devolve `[]` (nunca aceita) e sai da frente no ciclo seguinte. Também sai ao soltar o botão ou depois de 4 s. |
| `PainelFlutuante.swift` | Swift (AppKit) | `NSPanel` sem borda (nível `popUpMenu`) com `NSVisualEffectView` (`.popover`) e máscara de cantos de 16 pt. Largura fixa de 380. A altura segue o conteúdo SwiftUI (`onGeometryChange`) e o topo fica preso 6 pt abaixo do ícone. |
| `PainelView.swift` | SwiftUI | Cabeçalho (nome do app ou do arquivo e o menu "…", com Copiar ao terminar, Som ao terminar, Abrir ao arrastar um áudio, Abrir ao iniciar o Mac, Procurar atualizações…, Ajustes… e Sair), área tracejada (`dropDestination` e clique), menus de modelo e de idioma (o Whisper Turbo aparece desativado, "em breve"); durante um arraste com arquivo na tela, o painel inteiro mostra "Solte para transcrever". *(17/11/2026)* `.trabalhando` e `.pronto` caem num caso só, `Leitura`, para a caixa de texto ser a mesma do começo ao fim (quem lê no meio não volta ao topo): `Andamento` em cima (título por etapa, "Transcrevendo 2 de 3…", porcentagem, barra própria que não anima atrasada, "Na fila: …"), a caixa com os parágrafos e o tempo (rolagem até 312 pt; clique copia, com cursor de link; o rodapé diz "Clique para copiar o que já saiu" durante a transcrição e "Clique para copiar" no fim) e o rodapé (Cancelar, ou Novo), com `notaDaFila`/`notaDoModelo` no fim; aberta do histórico, mostra a data no lugar do tempo de transcrição. `AvisoCopiado` aparece embaixo do painel por 2 s. `Falha` (mensagem, nota da fila, Novo, Tentar de novo). Histórico: `Recentes` (3 últimas, com "Ver tudo"), `ListaDoHistorico` (busca, Voltar, rolagem até 360 pt) e `LinhaDoHistorico` (clique abre; botão copia; lixeira ao passar o mouse; menu de contexto: Abrir, Copiar o texto, Mostrar o áudio no Finder, Apagar). |
| `AjustesView.swift` | SwiftUI | *(17/11/2026)* Em Geral, "Transcrever pelo botão direito do Finder" (Ligado/Desligado, relido quando o app volta à frente, e o botão que abre os Ajustes do Sistema); altura 704. Janela de Ajustes, com **tamanho fixo** (`AjustesView.tamanho`, `sizingOptions = []`): com `preferredContentSize`, o Form agrupado entrava num ciclo de layout que derrubava o app. Seções: Geral (abrir ao iniciar, abrir ao arrastar, copiar e som ao terminar), Transcrição (modelo e idioma padrão, estado do Parakeet), Histórico (guardar, apagar ao desligar ou reiniciar, contagem, Mostrar no Finder, Limpar histórico… com confirmação) e Atualizações (ajuste do Sparkle, versão, Procurar agora; desligado no DEBUG). |

---

## Audio (`files/TranscreveAI/Audio/`)
Leitura e decodificação: AVFoundation primeiro, FFmpeg para formatos não nativos (a partir da v0.4); conversão para o formato PCM pedido pelo motor.

| Arquivo | Tipo | Descrição |
|---------|------|-----------|
| `FormatosAudio.swift` | Swift | *(17/11/2026: a extensão do Finder tem uma cópia de `aceita`; mudar as duas juntas.)* `aceita(_:)` (UTType `audio`/`audiovisualContent` + extensões extras: opus, ogg, webm, wma, mkv…), `tipos` para o seletor, `duracao(de:)` (AVURLAsset; o Opus do WhatsApp também é lido) e `formatar(duracao:)`. |

---

## Transcription (`files/TranscreveAI/Transcription/`)
Vazia por enquanto: os motores moram no pacote `TranscreveMotores` (acima) e a escolha do motor fica no `EstadoApp`. Aqui entram o WhisperKit e o benchmark local do "Automático" (v0.7).

| Arquivo | Tipo | Descrição |
|---------|------|-----------|
| _(nenhum arquivo ainda)_ | | |

---

## Export (`files/TranscreveAI/Export/`)
Geração de `.txt` (só texto) e `.md` (título, metadados e `[mm:ss]` por parágrafo).

| Arquivo | Tipo | Descrição |
|---------|------|-----------|
| `Exportacao.swift` | Swift | *(17/11/2026)* `Exportacao.txt(_:ao:)`: grava `<nome do áudio>.txt` (só o texto, parágrafos separados por linha em branco) na pasta do áudio; se o nome existe, `<nome> 2.txt`…; sem permissão, em Downloads. Usado pelo botão direito do Finder; o painel ganha a exportação na v0.6. |

---

## Extensão do Finder (`files/TranscreveFinder/`)
*(17/11/2026)* Alvo `TranscreveFinder` (`com.apple.product-type.app-extension`, `io.github.joaogmcorrea.transcreveai.finder`, Swift 5), embutido em `Contents/PlugIns` pela fase "Embutir extensões" do app. Sandbox obrigatório (`files/TranscreveFinder.entitlements`); `files/TranscreveFinder-Info.plist` traz o `NSExtension` (`com.apple.FinderSync`, classe `FinderSync`). Liga e desliga em Ajustes do Sistema › Geral › Itens de Início e Extensões (ou `pluginkit -e use|ignore -i io.github.joaogmcorrea.transcreveai.finder`).

| Arquivo | Tipo | Descrição |
|---------|------|-----------|
| `FinderSync.swift` | Swift (FinderSync) | Vigia `/` e os volumes montados. Nos áudios e vídeos selecionados (a mesma regra de `FormatosAudio.aceita`, copiada), mostra "Transcrever com o TranscreveAI" com o submenu "Copiar o texto" / "Exportar como .txt" e abre `transcreveai://copiar|exportar?arquivo=…` (o app transcreve). O Finder chama `menu(for:)` e as ações numa fila do XPC, fora da thread principal: por isso o alvo compila em **Swift 5, sem isolamento padrão** (o app é Swift 6 com `MainActor`); com o Swift 6, o `assumeIsolated` derrubava a extensão a cada clique. |
| `Localizable.xcstrings` | String Catalog | Os três textos do menu em pt-BR, inglês e espanhol. |

---

## Storage (`files/TranscreveAI/Storage/`)
Histórico de transcrições, preferências e resultados de benchmark em Application Support.

| Arquivo | Tipo | Descrição |
|---------|------|-----------|
| `Historico.swift` | Swift | `@Observable`, `Historico.compartilhado`. Em `~/Library/Application Support/TranscreveAI/Historico`: `indice.json` (lista de `Resumo`: id, nome, caminho, data, duração, motor, segundos, começo do texto) e um `<id>.json` por transcrição, com os parágrafos. Guarda as 500 mais recentes. **Só na sessão** (padrão, `historicoSoNaSessao`): `sessao.txt` guarda o `kern.boottime`; ao abrir, se ele mudou (o Mac desligou ou reiniciou), apaga tudo. `adicionar`, `paragrafos(de:)`, `apagar`, `limpar`, `filtrar(_:)` (nome + começo do texto, sem acento nem caixa) e `quando(_:)` ("Hoje, 10:12", "Ontem…", "9 nov, …"). Respeita `guardarHistorico`. |
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
Áudio (arrastar no ícone/painel, Finder, anel) → fila → Audio (AVFoundation | FFmpeg → PCM, lido aos poucos) → Transcription (motor ativo; Automático = mais rápido; aos pedaços) → Segmentos com tempo → UI (texto ao vivo, lista clicável) + Storage (histórico)

Botão direito do Finder (17/11/2026)
TranscreveFinder.appex → transcreveai://copiar|exportar?arquivo=… → AppDelegate (confere o remetente) → EstadoApp.receber(destino:) → fila → área de transferência | <nome>.txt ao lado do áudio → ✓ no ícone + som

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
