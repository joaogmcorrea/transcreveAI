# Memória do Projeto — TranscreveAI

> **Para Agentes de IA:** Este documento atua como o **Cérebro Secundário** do projeto. Aqui você acumula todos os conhecimentos, padrões arquiteturais e decisões descobertas durante o desenvolvimento. 
> 
> **MANDATÓRIO:** 
> 1. **Consulte este documento no início de qualquer nova task** para entender o histórico e não repetir erros passados.
> 2. **Atualize este documento ao final de cada sessão/task** com novas descobertas, decisões e problemas em aberto.

---

<!--
=========================================
TEMPLATE PARA NOVAS SESSÕES (COPIE ESTE BLOCO E COLOQUE NO TOPO)
=========================================

## Sessão [X] — [DD/MM/AAAA] ([Breve resumo do que foi feito])

### Objetivo
- [O que o usuário pediu para ser feito na task atual]

### Descobertas
- [Peculiaridades do ambiente, libs externas ou código base que a IA não sabia]
- 

### Decisões Tomadas
- [Decisões de design de código (ex: "preferido usar CSS Grid pela animação", "usado localStorage para X")]
- 

### Arquivos Modificados/Criados
- `[arquivo 1]` — [motivo simples]
- `[arquivo 2]` — [motivo simples]

### Padrões Identificados
- [Padrões do projeto (ex: "Sempre usar early return em validadores", "Todos os botões usam classe .btn-primary")]
- 

### Problemas Conhecidos ou Riscos Futuros
- [Algo que ficou pendente, com bug menor ou hardcoded que precisa de refatoração no futuro]
- 

### Dicas para Próximas Sessões
- [Anotação direta de "IA para IA" (ex: "Cuidado ao alterar o script X, ele quebra o script Y")]
- 

---
-->

## Sessão 6 — 14/11/2026 (Site pronto para subir ao servidor, v0.4.1)

### Objetivo
Pedido do owner: "deixe a landing page pronta para fazer deploy no meu servidor".

### Descobertas
- **O servidor é a Hostinger do Cutline** (LiteSpeed, lê `.htaccess`), atrás do Cloudflare; o Cutline fica em `public_html/cutline/` e é servido em `cutline.joaocorrea.design` (ver `Vibecoding/Cutline/_docs/SITE.md`). O Cutline sobe à mão o conteúdo de uma pasta gerada (`build.py` → `site/`); o TranscreveAI segue o mesmo caminho, com um zip para o "Extrair" do Gerenciador de Arquivos.
- **Trocar a URL com `history.replaceState` muda a base dos caminhos relativos:** uma `<img src="cutline.png">` montada depois de ir de `/` para `/pt/` pediria `/pt/cutline.png`. Por isso a página fixa a raiz (`BASE`) na abertura e monta a imagem com o endereço completo. A imagem que já estava no HTML não é afetada (o endereço foi resolvido ao carregar).
- **Imagem de compartilhamento sem gancho de teste:** o Chrome sem janela, pelo protocolo do DevTools (Node 24 tem `WebSocket` embutido), dá dois cliques de verdade (`Input.dispatchMouseEvent`) no áudio da mesa. A transcrição de exemplo leva 3,4 s, dentro dos 5 s de ativação do clique, então o "Copiado" aparece se a área de transferência for liberada (`Browser.grantPermissions` com `clipboardSanitizedWrite`). 960×504 a 1,25× dá 1200×630 no layout de computador (acima de 760 px).
- **O `.ico` aceita PNG dentro:** dá para escrever o `favicon.ico` sem ImageMagick (cabeçalho de 6 bytes + 16 por imagem).

### Decisões Tomadas
- **Endereço `transcreveai.joaocorrea.design`**, no padrão do Cutline, confirmado pelo owner (14/11/2026). Mudar: `SITE` no `gerar.py` ou `--site`.
- **Uma URL por idioma** (`/`, `/pt/`, `/es/`), como no Cutline. `/` (x-default) continua detectando o idioma (escolha salva, navegador); `/pt/` e `/es/` abrem no próprio idioma mesmo com outra escolha salva. Escolher no menu muda a URL.
- **Sem redirecionamento para HTTPS no `.htaccess`:** com o Cloudflare em SSL "Flexible", entraria em laço; fica com o "Always Use HTTPS" do Cloudflare. **Sem CSP:** a página é toda inline, e o Cloudflare injeta o beacon do Web Analytics.
- `_site/dist/` e o zip ficam fora do git; `_site/imagens/` entra (desenhá-las precisa do Chrome).
- **Versão 0.4.1, não 0.5.0** (escolha do owner): a regra do CHANGELOG pediria subir o MINOR, mas o ROADMAP reserva a v0.5.0 para o trecho clicável e a exportação, e o CONTEXTO cita v0.6 (Whisper) e v0.8 (anel). Uma versão entre marcos usa o PATCH para não renumerar o plano.
- **Link do site** no README e no campo "Website" do repositório (`gh repo edit --homepage`), pedido do owner.
- **`xcodebuild -quiet` mostra "error: the following command failed with exit code 0"** quando um passo de compilação só emite avisos: não é falha (o build termina com código 0 e o app sai).

### Problemas Conhecidos ou Riscos Futuros
- O site fala de coisas que a v0.4.0 ainda não tem (app em três idiomas, clicar para copiar): publicar junto com a próxima versão.
- O `.htaccess` não foi testado num LiteSpeed (só a sintaxe do Apache, que ele lê). Conferir os cabeçalhos com `curl -I` depois de subir.

## Sessão 5 — 11/11/2026 (App em três idiomas e landing page)

### Objetivo
Pedido do owner: "deixe o app em ingles, portugues e espanhol" e "crie uma landing page para ele, similar à essa https://vorssaint.com porém incorporando um pouco do design system que usamos no cutline".

### Descobertas
- **vorssaint.com** é uma mesa de macOS inteira desenhada no navegador: barra de menus com o idioma (EN), ícones na mesa (Ajustes, Download, GitHub), Dock e a janela de Ajustes do app aberta, com barra lateral. No celular continua mesa, com os ícones e o Dock.
- **Design system do site do Cutline:** `Vibecoding/Cutline/_design/site-design-system/` (README, `tokens.css`, `components.css`, `patterns.md`, `check.py`). O `check.py` aceita um HTML e confere tokens, cores e durações soltas; `/* check: allow */` libera uma linha.
- **A Vinila é por domínio:** o kit do Adobe Fonts do Cutline (`jjn5pbx`) só vale para `cutline.joaocorrea.design` e `localhost` e não pode ser reaproveitado. Sem kit, a página mostra as fontes de reserva (Arial no tamanho da Vinila).
- **O app não tem ícone próprio** (sem `Assets.xcassets`): a landing usa uma marca provisória (onda branca num quadrado violeta).
- **Armadilha de layout:** numa janela `display: grid` com altura fixa, a linha implícita cresce com o conteúdo e a rolagem interna não acontece; precisa de `grid-template-rows: minmax(0, 1fr)`. Um `<span>` de barra precisa de `display: block` para a largura valer.
- **Armadilha de arraste:** depois de soltar fora do próprio botão, o `click` não vem, e a trava que engole o clique do arraste ficava ligada e engolia o próximo clique. Solução: soltar a trava num `setTimeout(0)`.
- **Painel do navegador em 2º plano:** a rolagem suave e as transições podem não andar; para conferir, rolar com `scrollTop` e ler o estado por JavaScript.
- **Tradução do app:** `files/TranscreveAI/` é pasta sincronizada, então os `.xcstrings` entram no alvo sozinhos. Os literais do SwiftUI já eram extraídos pelo compilador; faltavam os `String` em variável, enums, `NSMenuItem`, `NSOpenPanel`, dicas e acessibilidade (agora com `String(localized:)`). O catálogo precisa de valores `pt-BR` explícitos (iguais às chaves): sem eles não sai `pt-BR.lproj` e quem tem "pt-BR, en" veria inglês. O pacote TranscreveMotores ganhou `defaultLocalization: "pt-BR"` e catálogo próprio (`bundle: .module`); o CLI `transcrever` mostra os erros no idioma do sistema.
- **Idioma escolhido pelo macOS:** (pt-BR, en) dá português; (en-BR, pt-BR) dá inglês; es-MX dá espanhol; só francês dá pt-BR (a região de desenvolvimento). **O Mac do owner lista en-BR primeiro**: o app vai aparecer em inglês para ele; para manter em português, Ajustes do Sistema › Geral › Idioma e Região › Aplicativos › TranscreveAI › Português. Decimais e horas seguem a região do Mac, não só o idioma ("3,4 s" com inglês num Mac com região Brasil).
- **Info.plist:** não há textos de permissão; o único texto traduzível é o tipo de documento "Áudio" (`InfoPlist.xcstrings`). Os catálogos foram conferidos por um script que cruza as chaves extraídas pelo compilador com as traduções e os especificadores (no scratchpad da sessão, não no repositório).

### Decisões Tomadas
- **Landing = uma mesa de macOS** (primeira versão, substituída no mesmo dia pelo redesenho abaixo).
- **Bolinha vermelha:** fica vermelha porque é assim no app (exceção ao "nada de vermelho" do Cutline).
- **Arquivo de verdade solto na página:** não é lido nem enviado; o painel diz que é só uma demonstração e oferece o download.
- **Idioma do app:** segue o macOS (sem seletor no app), com o português como língua de origem do catálogo. No seletor de idioma do áudio, os nomes ficam no próprio idioma (Português, English, Español), como no seletor do sistema; só "Auto" é traduzido.
- **Copiar (11/11/2026, owner):** clicar no texto copia tudo e o aviso "Copiado" aparece por 2 s (app, site e GIFs). Escolha: o texto deixou de ser selecionável, porque o clique da seleção e o clique de copiar brigariam. O "Clique para copiar" fica no rodapé, não sobre o texto (no canto, cobria a primeira linha). No navegador do painel, a API da área de transferência é negada: o site usa `execCommand("copy")` primeiro, no clique, e a API como reserva.
- **Espanhol:** "tu Mac", nunca "la Mac"/"esta Mac" (mesma regra do Cutline: nada de artigo antes de "Mac"); "la app" no feminino; "tú".

### Redesenho do site, a pedido do owner (11/11/2026)
- O owner não quer landing tradicional (hero, argumentos, seções): quer **a tela de um Mac que se usa**, com mensagens sutis, como o vorssaint.com. A primeira versão misturava os dois (janela de "Ajustes" com hero e seções) e foi refeita.
- **O que tem:** barra de menus (o app da frente muda: Finder, TextEdit, TranscreveAI), ícone do app com o menu do botão direito, idioma (EN/PT/ES) e relógio; arquivos na mesa (TranscreveAI.dmg baixa de verdade, dois áudios, Leia-me no TextEdit); Finder com Recentes, Aplicativos, Mesa, Documentos e Downloads; Dock com o download do DMG, os Ajustes do app (engrenagem; reabre o app se ele foi fechado), GitHub, Buy Me a Coffee (bloco amarelo com uma xícara, leva a buymeacoffee.com/joaocorrea; rótulo nos três idiomas), a pilha de Downloads em leque (arrastar um áudio dela abre o painel sozinho) e, à direita dela, o Cutline (abre o site dele). Sem Finder nem Lixo no Dock, a pedido do owner (11/11/2026); o Finder continua no "Escolher áudio" e no "Mostrar no Finder" dos Ajustes.
- **O app imitado:** painel com o "…" (Copiar ao terminar, Som, Abrir ao arrastar, Abrir ao iniciar, Procurar atualizações, Ajustes, Sair), menus de modelo e idioma, Recentes e "Ver tudo" com busca, clicar na área abre o Finder em modo "Escolher áudio", Ajustes como os do app (os interruptores valem na demonstração), "Procurar atualizações" com o alerta do Sparkle, Sair tira o ícone da barra e o Dock abre de novo. Apple Speech leva o dobro do tempo e mostra a prévia ao vivo. Arquivo que não é áudio solto no ícone dá o erro do app.
- **Do design system do Cutline, só** o papel de parede (o KV) e as cores dos ícones; o resto é macOS (o violeta como cor de interface "não tem nada a ver com o macOS", disse o owner). Sem Vinila, então o kit de fonte deixou de ser pendência.
- **Armadilha:** um `id` repetido entre o sprite de ícones (`<symbol id="clock">`) e um elemento (`#clock`) fez o relógio sumir: o `querySelector` achou o símbolo primeiro. Conferir ids duplicados ao mexer na página.

- **Armadilha do Dock no celular (11/11/2026):** o desenho da pasta (58 px) é mais largo que o bloco da pilha (44 px no celular). Num `display: grid` ele vazava só para a direita e encostava no Cutline. Agora o bloco é `flex` centrado e a pasta `flex: none`, o que divide o excesso para os dois lados. O Dock tem `width: max-content` e os ícones `flex: none`, para nunca espremer. Com 7 ícones, de 372 px para baixo o Dock usa ícones de 40 px; acima disso, 46 px no celular e 56 px no computador. Conferido em 320, 360, 375, 768 e 1440 px.

### Problemas Conhecidos ou Riscos Futuros
- O site ainda não tem endereço. Não tem imagem de compartilhamento (`og:image`) nem uma URL por idioma (`/pt/`, `/es/` com `hreflang`), como a do Cutline. *(14/11/2026: resolvido pelo `_site/gerar.py`, Sessão 6; endereço `transcreveai.joaocorrea.design`, confirmado pelo owner.)*
- A landing já fala do app em três idiomas: publicar junto com a versão que traz a tradução.

## Sessão 4 — 10/11/2026 (Transcrição, histórico e Ajustes, v0.4.0)

> **Depois da release** *(10/11/2026)*: README em inglês, licença MIT e GIFs do README. Os GIFs são **desenhados** (`_dev/gifs/animacoes.swift`), não gravados: gravar a tela mostraria a mesa, as janelas e os ícones do usuário, e simular arrastes exigiria permissão de Acessibilidade. O owner pediu "estilo video-tutorial flat". Um GIF de 1200 px com *dither* `sierra2_4a` ficou com 3,3 MB; com `bayer:bayer_scale=5` e 128 cores, 2 MB, sem faixas visíveis nas sombras (`dither=none` mostra faixas). Cuidado no desenho: `NSGraphicsContext(bitmapImageRep:)` já desenha em pontos; aplicar a escala 2× de novo dobra tudo. *(11/11/2026)* O owner pediu os GIFs **todos em inglês**, não só as legendas: menus, Finder, painel, nomes de arquivo e transcrições. O README diz que o app real é em português. Ao mudar textos, conferir com `QUADRO` se o parágrafo não quebra em 3 linhas (o painel cresce e cobre mais da cena).

### Objetivo
- v0.4.0: transcrever de verdade (Parakeet v3 + Apple Speech de reserva), com progresso no painel e no ícone e FFmpeg embutido. Pedidos do usuário no meio: som ao terminar, bolinha vermelha de "não visto", garantia de que a transcrição continua com o painel fechado, fechar sem atraso ao clicar fora, histórico (com lixeira e só da sessão), Ajustes de verdade (também no botão direito) e abrir ao arrastar das pilhas do Dock.

### Descobertas
- **Formatos nativos no macOS 27** (testado com `AVAudioFile` e `AVAssetReader`): MP3, M4A/AAC, MP4, FLAC, OGG/Vorbis e **Opus em OGG (WhatsApp)** abrem direto. **WebM, WMA e MKV não** (e AMR não foi testado: o FFmpeg do Homebrew não tem o encoder). O FFmpeg ficou só para esses.
- **FluidAudio traz 57 MB a mais** (normalização de texto NeMo, TTS, separação de falantes). Com `traits: []` na dependência sai só o ASR. Como o Xcode não escolhe traits num pacote remoto, os motores foram para um pacote local (`files/Pacotes/TranscreveMotores`) que declara a dependência assim. Bônus: dá para testar pelo terminal (`transcrever`). App de debug: 14 MB.
- **Download do Parakeet:** `AsrModels.downloadAndLoad(to:)` recebe a pasta do próprio modelo (`.../Modelos/parakeet-tdt-0.6b-v3`), não a pasta-mãe. O `fractionCompleted` vai de 0 a 50% no download e de 50 a 100% na compilação (`DownloadPhase.downloading`/`.compiling`). Download de cerca de 34 s; a compilação para o Neural Engine leva cerca de 14 s **na primeira carga de cada app** (o terminal e o app compilam cada um a sua), e depois só 0,1–0,2 s.
- **Apple Speech + idioma do sistema = desastre:** num Mac em inglês, com áudio em português, o texto sai ilegível. O motor não detecta o idioma, então no "Auto" usa pt-BR.
- **Glitches de pontuação:** o Parakeet às vezes solta um "." numa pausa (vira frase própria), e o Apple Speech começa um resultado com o ponto do anterior (". Parte dois"). Os dois foram corrigidos no pacote. O Apple Speech também pula números em fala sintética ("Parte" sem o número); o Parakeet acerta.
- **Velocidade no app real:** Parakeet a 224× tempo real (3 min em 0,77 s); Apple Speech a cerca de 85× (3 min em 1,7 s, com prévia ao vivo).
- **Barra de progresso nativa** (`ProgressView(value:)`) anima atrasada em relação ao número; trocada por uma barra própria.
- **Ícone com bolinha:** desenhar o símbolo + bolinha numa imagem colorida deixa o símbolo cinza (perde o tratamento de template da barra). Solução: símbolo template e uma `NSView` vermelha por cima do botão.
- **Painel aberto por argumento logo na abertura** pode precisar de mais tentativas até o ícone ter posição (o limite subiu para 5 s).
- **Ajustes "não fazia nada" (relato do usuário) = o app caía:** `NSHostingController` com `sizingOptions = [.preferredContentSize]` + `Form` agrupado com `fixedSize` → `NSGenericException` ("more Update Constraints in Window passes than there are views"). Janela de tamanho fixo resolve. Sintoma enganoso: o app some da barra, e para quem usa parece que nada aconteceu. Diagnóstico: rodar o binário direto e ler a saída (o log mostra a exceção).
- **Histórico só da sessão (pedido do usuário):** o `kern.boottime` muda a cada desligar ou reiniciar; anotado em `sessao.txt`, se não bate ao abrir, o histórico é apagado (padrão ligado; Ajustes permite manter). Testado com `CFFIXED_USER_HOME` apontando para uma pasta pessoal de mentira, para não tocar no histórico real. Cuidado: o `sed` em `sysctl -n kern.boottime` precisa pegar o `sec` do começo, não o `usec`.
- **Arrastar do Dock não abria o painel (relato do usuário; resolvido, testado por ele):** a primeira hipótese (o Dock não entrega os eventos) estava **errada**. Um diagnóstico separado (`swiftc`, registrando a cada 50 ms o botão, os eventos globais e o `changeCount`) mostrou que o mouse down, o movimento e o `pressedMouseButtons` chegam normalmente, mas que **o `changeCount` de `NSPasteboard(name: .drag)` nunca muda** num arraste vindo do Dock. O Dock usa uma área de arraste própria, com nome que outros processos não enxergam (o dev do Yoink relatou o mesmo em 2011). Solução: o `ApanhadorDeArraste`, uma janela transparente da tela inteira, armada só quando o clique cai numa janela do Dock ou do Finder e o ponteiro anda 6 pt. Quem *recebe* o arraste ganha a área certa em `draggingPasteboard`. Ela lê, avisa e sai da frente. Detalhes: com o Dock em ocultar automaticamente, a lista de janelas não mostra o Dock enquanto ele está escondido; a origem do clique sai da `windowNumber` do evento global. O `log show` não mostrou os registros deste build de teste (ficaram em nível debug).
- **Diagnosticar arrastes:** os registros `info`/`debug` não ficam guardados; use `log stream --debug --predicate 'subsystem == "io.github.joaogmcorrea.transcreveai"'` durante o teste e **sem** `| tail` (só mostra no fim). Um diagnóstico em processo separado foi o que resolveu.
- **Histórico (pedido do usuário):** índice + um JSON por transcrição em Application Support/TranscreveAI/Historico, limite de 500. Os testes automáticos gravam no histórico real do usuário: apagar as entradas de teste depois (as do scratchpad).
- **Fechar ao clicar fora tinha atraso (relato do usuário):** o fechamento esperava o mouse up para não atrapalhar o arraste de um arquivo até o painel aberto. Agora fecha no mouse down (esquerdo, direito ou outro). O arraste continua coberto porque o `DetectorDeArraste` reabre o painel quando um arraste de áudio começa. Com "Abrir ao arrastar" desligado, resta soltar no ícone.

### Decisões Tomadas
- **Automático:** Parakeet se estiver pronto ou baixado; senão Apple Speech neste arquivo + download do Parakeet em segundo plano (nota no painel). Se o Parakeet falhar no Automático, o Apple Speech tenta.
- **Segundo plano garantido:** fechar o painel não interrompe nada (a tarefa vive no `EstadoApp`); `ProcessInfo.beginActivity(.userInitiated, .idleSystemSleepDisabled)` durante a transcrição evita App Nap e sono do Mac.
- **Fim:** som Glass (Basso no erro), opção "Som ao terminar" no "…" (ligada); "Copiar ao terminar" passou a funcionar; ícone com ✓ por 4 s e depois bolinha vermelha até abrir o painel.
- **FFmpeg próprio** (9.0.2, LGPL, sem dependências, universal, 8,2 MB) como programa separado em `Contents/Helpers`, com a receita em `_dev/ffmpeg/compilar.sh` e o binário versionado em `files/Vendor/ffmpeg/`. Licenças de terceiros em `files/LICENCAS.md`.
- **Resultado na v0.4:** texto selecionável em parágrafos com tempo e "Copiar tudo" (entrou junto com o histórico). Clique para copiar trecho e Exportar ficam para a v0.5 (roadmap).

### Problemas Conhecidos ou Riscos Futuros
- Sem teste à mão com áudios longos (30 min ou mais). Soltar direto no ícone da barra foi testado pelo usuário depois da release. A prévia ao vivo só existe no Apple Speech; o Parakeet entrega tudo no fim (rápido o bastante).
- O apanhador do arraste só arma para cliques no Dock e no Finder. Arrastes de áudio vindos de outros apps que também usem área própria não abrem o painel (nenhum caso conhecido).
- O Parakeet usa cerca de 143 MB de memória enquanto está carregado (fica carregado de propósito).

### Dicas para Próximas Sessões
- Testar motores sem o app: `swift run --package-path files/Pacotes/TranscreveMotores --scratch-path ~/Library/Caches/TranscreveAI-motores transcrever <áudio> [parakeet|apple] [idioma]` (`TRANSCREVE_FRASES=1` mostra os tempos).
- Testar o app sem clicar: `--arquivo <caminho>` (painel aberto) e `--arquivo-fundo <caminho>` (painel fechado, para ver o ícone). `defaults write io.github.joaogmcorrea.transcreveai modelo apple` força o Apple Speech; `somAoTerminar -bool false` silencia os testes.
- Evitar testes com o painel aberto enquanto o usuário usa o Mac: ele cobre a tela e um clique dele fecha o painel.

---

## Sessão 3 — 10/11/2026 (Esqueleto do app de menu bar e atualizações, v0.3.0)

### Objetivo
- Criar o projeto Xcode do app de barra de menus (v0.3.0) e tratar as atualizações com a mesma lógica do Cutline (pedido do usuário).

### Descobertas
- **Lógica de atualização do Cutline** (lida em `../Cutline`): Sparkle 2 (2.10.1) com `SPUStandardUpdaterController(startingUpdater: !DEBUG)`. O `SUFeedURL` aponta para `releases/latest/download/appcast-$(MARKETING_VERSION).xml`: cada versão lê o próprio appcast, e o contador de downloads do GitHub mostra quantos apps de cada versão existem. Por isso toda release leva uma cópia do appcast para cada versão já lançada. Também usa `SUPublicEDKey`, `SUEnableAutomaticChecks` e `SUVerifyUpdateBeforeExtraction`. A chave privada é a semente do CryptoKit em base64, guardada em `_privado/` (`sign_update --ed-key-file`). O `distribuir.sh` monta o DMG e o appcast e, com `--publicar`, cria a release. Lá, "versionar = publicar": é a release, não o push, que atualiza os apps.
- **Diferença de estrutura:** no Cutline o repositório público é só `files/`, e a raiz é um git privado local. No TranscreveAI a raiz inteira é o repositório público (decisão da Sessão 1). O `_dev/` e o `_privado/` seguem a mesma ideia, com `/_privado/` e os DMGs/appcasts no `.gitignore`.
- **`MenuBarExtra` não serve:** ele não expõe o `NSStatusItem`, então não dá para soltar arquivos no ícone. A solução é `NSStatusItem` + `NSPanel` próprio. Para soltar no ícone, a janela do botão é registrada para `.fileURL` e a `BarraDeMenus` vira o delegate dela (o `NSWindow` repassa os eventos de arrastar ao delegate).
- **Bug achado pelo usuário (corrigido):** no macOS 26+, o clique no ícone da barra também chega ao monitor **global** de eventos, como se viesse de outro app. A ação do botão dispara no mouse down. Por isso o "soltar" (mouse up) do próprio clique que abriu o painel era lido como "clique fora" e o fechava na hora: ele só ficava aberto se a pessoa arrastasse antes de soltar. Correção: só fecha um clique que **começou** fora do ícone depois que o painel abriu (`cliqueForaPendente`) e ignora eventos sobre o ícone.
- **Abrir ao arrastar (pedido do usuário):** a técnica do Dropover/Yoink. Um monitor global de mouse (não exige Acessibilidade) compara o `changeCount` de `NSPasteboard(name: .drag)` entre o mouse down e o primeiro mouse dragged. Se mudou e tem URL de arquivo de áudio, é um arraste de áudio. O painel abre sem ativar o app (`orderFrontRegardless`), para não atrapalhar o arraste. Arquivos prometidos (Mail, alguns navegadores) não trazem URL e ficaram de fora. Confirmado pelo usuário em 10/11/2026: funciona arrastando do Finder.
- **Menu do botão direito no ícone:** `sendAction(on: [.leftMouseDown, .rightMouseDown])` e, no botão direito, `item.menu = menu; button.performClick(nil); item.menu = nil` (menu no lugar certo e ícone destacado). O usuário pediu os itens como "check for updates / close / open on startup"; ficaram em pt-BR pela regra da interface.
- **Logo depois da abertura**, a janela do ícone ainda está em `y = 0`: abrir o painel ali o joga para fora da tela. O `mostrarPainel` tenta de novo a cada 0,1 s até o ícone ter posição.
- **O AVFoundation do macOS 27 lê a duração do Opus do WhatsApp.** Falta confirmar se ele também decodifica o áudio (v0.4).
- **App sem Dock + Sparkle:** é preciso implementar `supportsGentleScheduledUpdateReminders` no `SPUStandardUserDriverDelegate` e ativar o app antes da janela da atualização.
- **Assinatura ad-hoc:** a cada versão, o macOS pode pedir de novo as permissões (Acessibilidade, no anel da v0.8). O Cutline resolve com um certificado autoassinado no Acesso às Chaves. Aqui o `distribuir.sh` procura o certificado "TranscreveAI".

### Decisões Tomadas
- Bundle ID `io.github.joaogmcorrea.transcreveai` (o mesmo padrão do Cutline). `MARKETING_VERSION` no projeto, com `CURRENT_PROJECT_VERSION = $(MARKETING_VERSION)`.
- O "…" do painel ganhou "Procurar atualizações…" e "Ajustes…". Os Ajustes abrem numa `NSWindow` própria, porque o `openSettings` do SwiftUI não funciona confiavelmente fora das cenas.
- Clique fora fecha o painel, mas um clique fora que vira arraste não fecha (para trazer um arquivo do Finder até o painel aberto).
- O arquivo recebido mostra "Áudio recebido" até a transcrição chegar, na v0.4.

### Arquivos Modificados/Criados
- `files/` — projeto Xcode, `TranscreveAI-Info.plist` e os fontes em `TranscreveAI/{App,UI,Audio,Storage}`.
- `_dev/distribuir.sh` — o mesmo do Cutline, adaptado.
- `_privado/` — par de chaves EdDSA (fora do git).
- `.gitignore`, `_docs/*`.

### Problemas Conhecidos ou Riscos Futuros
- Testado pelo usuário: clique no ícone (depois da correção), abrir ao arrastar e soltar no painel. Sem teste à mão: soltar direto no ícone da barra (testado na Sessão 4).
- A v0.3.0 é a primeira release (10/11/2026). Só os apps instalados a partir dela recebem atualizações; a cópia de debug do DerivedData não se atualiza (o Sparkle fica desligado no DEBUG).
- **PKG em vez de DMG (dúvida do usuário):** não muda o aviso do Gatekeeper nem a permissão de Acessibilidade, que depende da assinatura do app, e pioraria o Sparkle (senha a cada atualização). Fica o DMG, como no Cutline. O que tira os avisos é o Developer ID com notarização; o que estabiliza a Acessibilidade é um certificado fixo (o autoassinado "TranscreveAI" basta).
- **A chave de `_privado/` precisa de backup.** Ela está no Dropbox; se se perder, os apps instalados não aceitam versões novas.

### Dicas para Próximas Sessões
- Para ver o painel sem clicar: rode o app com `--abrir-painel` ou `--arquivo <caminho>` e tire uma foto com `screencapture -x -R 1200,0,720,620`.
- Para testar o pipeline de distribuição sem publicar: `./_dev/distribuir.sh` (gera tudo em `_dev/dist/`). Para conferir a assinatura: CryptoKit `isValidSignature` com o `SUPublicEDKey`.

---

## Sessão 2 — 10/11/2026 (Benchmark de motores, v0.2.0)

### Objetivo
- Medir velocidade e qualidade dos motores candidatos em pt-BR e escolher o padrão do modo "Automático".

### Descobertas
- **Máquina de teste:** M4 Pro, 24 GB, macOS 27.0.1, Xcode 27.2, Swift 6.4.2. O Apple Speech (`SpeechTranscriber`) suporta pt-BR e o modelo já vem instalado.
- **Áudios:** 3 notas de voz do WhatsApp (Opus; 22 s, 40 s e 88 s), fala informal. Ainda falta testar um áudio longo (30 min ou mais).
- **Velocidade (transcrição, sem a carga do modelo):** Parakeet v3 **145×** tempo real · Apple Speech **73×** · whisper.cpp Turbo 25× · Whisper Turbo (WhisperKit) 22× · Whisper Large v3 (WhisperKit) **3×**.
- **Carga do modelo:** Apple 0,1 s (sem download) · Parakeet 0,2 s com cache (42 s na primeira compilação) · WhisperKit cerca de 5–6 s a cada carga (cerca de 150 s na primeira compilação) · whisper.cpp 0,6 s.
- **Memória do processo:** Apple 21 MB (o trabalho roda num processo do sistema) · Parakeet 143 MB · Whisper Turbo 306 MB · Whisper Large 759 MB · whisper.cpp 1,9 GB.
- **Falhas observadas:** o Whisper Large v3 **cortou a segunda metade** do áudio de 40 s (85 de cerca de 132 palavras) e foi o mais lento. O whisper.cpp **repetiu uma frase inventada** (alucinação) no áudio de 88 s. Apple e Parakeet não tiveram cortes nem repetições.
- **Qualidade (avaliação qualitativa, sem referência):** Whisper Turbo e Parakeet têm boa pontuação e texto fiel nos áudios mais claros. O Apple Speech acerta bem as palavras, mas pontua pouco em trechos longos. Todos erram em nomes próprios e na fala mais informal.
- **Armadilha do benchmark:** usar o Whisper Large v3 como pseudo-referência favorece os outros Whisper e pune quem acerta o trecho que ele cortou. Só um `referencia.txt` (transcrição correta) mede a qualidade de verdade. O Whisper escreve números como algarismos ("1, 2, 3"), o que também conta como erro no WER.
- **Dropbox:** modelos e builds ficam em `~/Library/Caches/TranscreveBench` para não sincronizar cerca de 7 GB.

### Decisões Tomadas
- **Aprovado pelo usuário (10/11/2026):** "Automático" = **Parakeet v3**. Na primeira execução, enquanto ele baixa (cerca de 470 MB) e compila, o app usa o **Apple Speech**. Manter o **Whisper Turbo** como opção de qualidade. **Retirar** do app o Whisper Large v3 (lento e com corte) e o whisper.cpp (alucinação, 1,9 GB de RAM, sem ganho de velocidade sobre o WhisperKit).

### Arquivos Modificados/Criados
- `_testes/benchmark/` — `Package.swift`, `Sources/bench/main.swift`, `rodar.sh`, `relatorio.py`.
- `.gitignore` — `_testes/audios/` e `_testes/resultados/` fora do git. `files/` volta a ser versionada (pasta do app).

### Padrões Identificados
- O relatório sinaliza "incompleto" (menos de 75% da mediana de palavras) e "repetição" (6 palavras repetidas). A sugestão do "Automático" ignora os motores com alertas.

### Problemas Conhecidos ou Riscos Futuros
- Os áudios curtos não mostram o comportamento em gravações longas (memória, cortes, deriva). Rodar de novo com um áudio de 30 min ou mais antes da v1.0.
- O Parakeet v3 é multilíngue europeu: confirmar a qualidade em sotaques e gírias brasileiras com mais amostras.

### Dicas para Próximas Sessões
- Para repetir o teste: coloque áudios em `_testes/audios/` (com `nome.txt` de referência, se houver) e rode `./_testes/benchmark/rodar.sh`. Se o cache foi apagado, rode `preparar` antes.
- Nunca copie trechos dos áudios de teste para os docs: o repositório é público.

---

## Sessão 1 — 10/11/2026 (Setup, escopo e mockup da UI)

### Objetivo
- Definir o app: transcrição de arquivos de áudio de qualquer formato, nativo em Swift, com tela extremamente simplificada.
- Validar a UI com um mockup antes de iniciar o código.

### Descobertas
- **Referências do usuário:** MacWhisper e Whisper Transcription. São bons, mas lentos para transcrever e com muita coisa na tela. É exatamente o que o TranscreveAI deve evitar.
- **"Action ring da Loggi":** interpretado como o Actions Ring do Logi Options+ (Logitech), um menu radial em volta do cursor. Virou o "anel de ações" (⌥ Espaço).
- **Motor nativo da Apple:** o `SpeechAnalyzer` (macOS 26+) roda no próprio Mac sem baixar modelo e é candidato a motor mais rápido. A qualidade em pt-BR ainda não foi medida.
- **Formatos:** o AVFoundation lê MP3, M4A, AAC, WAV, AIFF, FLAC, MP4 e MOV, mas não lê OGG, Opus, WebM, WMA nem MKV. Para esses é preciso o FFmpeg.
- **Permissões:** o atalho global e o "Colar no app" exigem a permissão de Acessibilidade, o que conflita com o sandbox da App Store.

### Decisões Tomadas
- **Formato: app de menu bar.** O usuário comparou os mockups de janela e de menu bar e escolheu o menu bar.
- **Stack:** Swift + SwiftUI nativo, macOS 26+.
- **Modelos:** seletor com "Automático" como **padrão** (usa sempre o mais rápido instalado, medido no Mac). Opções provisórias até o benchmark: Apple Speech, Parakeet v3, Whisper Large v3 Turbo e Whisper Large v3.
- **Resultado:** clicar num trecho copia o trecho. Há também "Copiar tudo" e "Exportar" (`.txt` só texto; `.md` com título, metadados e `[mm:ss]`).
- **Menu bar:** progresso aparece no ícone quando o painel está fechado, notificação ao terminar, "Copiar ao terminar" ligado por padrão e lista de 3 recentes no painel.
- **Anel de ações (⌥ Espaço):** transcrever seleção do Finder, abrir arquivo, copiar última, colar no app, exportar `.md`, exportar `.txt`.
- **FFmpeg embutido** (build LGPL) para cobrir todos os formatos.
- **Distribuição:** uso próprio, fora da App Store e sem sandbox. **Processamento 100% local.**
- **Visual:** nativo do macOS (SF Pro, segue claro/escuro do sistema).
- **Git:** fora do versionamento ficam builds do Xcode/SwiftPM, modelos baixados e `files/` (áudios de teste).

### Arquivos Modificados/Criados
- `_docs/CONTEXTO.md`, `_docs/CHANGELOG.md`, `_docs/MEMORIA.md`, `_docs/SCRIPTS-LOGIC.md`, `_docs/REGRAS_CONDUTA.md` — preenchidos com o escopo.
- `_docs/ROADMAP.md` — criado (era citado no `CONTEXTO.md` e não existia).
- `.gitignore` — exclusões de Xcode/SwiftPM, modelos e `files/`.
- Mockup: canvas externo "TranscreveAI Mockup", fora do repositório.

### Padrões Identificados
- Toda tela nova começa por um mockup interativo aprovado pelo usuário.
- Textos da interface em pt-BR.
- Opções novas não entram na tela principal. Vão para o menu "…" ou para Ajustes.

### Problemas Conhecidos ou Riscos Futuros
- A qualidade do Apple Speech em pt-BR é desconhecida. Se for ruim, o "Automático" precisa considerar qualidade mínima, não só velocidade.
- Licença do FFmpeg: usar build LGPL com linkagem dinâmica e evitar componentes GPL.
- Modelos Whisper são grandes (centenas de MB a GBs). O download deve ser opcional e acontecer uma única vez.
- "Segurar ⌥ Espaço e soltar" exige monitor global de eventos (Acessibilidade / Monitoramento de Entrada). Validar a experiência de permissão.

### Dicas para Próximas Sessões
- Antes de mexer na UI, abra o mockup (página "Menu bar") e siga o que foi aprovado.
- O primeiro marco técnico é o benchmark de motores com áudios reais em `files/`. Ele define o motor padrão inicial.

---

## Sessão Inicial — 10/11/2026 (Setup de Gen AI)

### Objetivo
Implementar os arquivos de documentação base para guiar o contexto de Agentes de IA no desenvolvimento deste novo projeto.

### Descobertas
- Os arquivos foram copiados a partir do template otimizado de Gen AI (`CONTEXTO`, `MEMORIA`, `CHANGELOG`, `SCRIPTS-LOGIC`, `ROADMAP`, `REGRAS_CONDUTA`).

### Decisões Tomadas
- O desenvolvimento deste projeto adotará uma abordagem orientada à assistência de IAs autônomas, mantendo contexto rígido em arquivos Markdown (`_docs/`).
- O versionamento é feito com git local: cada versão é um commit + tag anotada `vX.Y.Z` (`_docs/versionar.sh`). Exclusões ficam no `.gitignore`.

### Padrões Identificados
- **Zero-knowledge loss:** Nenhuma decisão arquitetural deve ficar apenas no prompt. Se foi decidido, deve vir para a `MEMORIA.md`.
- **Arquivos imutáveis:** O comportamento raiz do sistema fica em `CONTEXTO.md`. A `MEMORIA.md` é estritamente incremental/aditiva.

### Dicas para Próximas Sessões
- Sempre que houver dúvidas sobre o estado atual do sistema, leia o `CONTEXTO.md`.
- Ao encontrar bugs repetitivos, anote o *root cause* em "Descobertas" para que outras sessões não o cometam.
- Para ver o histórico de versões: `git log --oneline --decorate`.
