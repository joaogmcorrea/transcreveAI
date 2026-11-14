# TranscreveAI - Transcrição de áudio local, rápida e minimalista na barra de menus do macOS

> **Para Agentes de IA:** Antes de modificar qualquer código, **LEIA `_docs/SCRIPTS-LOGIC.md`** para entender a estrutura dos scripts, e **`_docs/MEMORIA.md`** para rever os conhecimentos acumulados de sessões anteriores. Este documento (`CONTEXTO.md`) serve como a visão geral de arquitetura, fluxo e status atual do projeto. Mantenha-o atualizado ao final de implementações importantes.

## Contexto do Projeto

### O que é
App nativo para macOS (Swift + SwiftUI) que vive na **barra de menus**. O usuário arrasta um arquivo de áudio, de qualquer formato, para o ícone ou para o painel. O app transcreve tudo no próprio Mac e mostra o texto pronto para copiar (um trecho ou tudo) ou exportar como `.txt` ou `.md`. Uso pessoal: o único usuário é o owner.

### Motivação
- **Lentidão das alternativas:** MacWhisper e Whisper Transcription funcionam bem, mas são lentos para transcrever e têm interface carregada.
- **Zero atrito:** transcrever deve ser "soltar o áudio e ter o texto", sem configurar nada antes.
- **Velocidade e privacidade:** o padrão é sempre o modelo mais rápido medido no Mac, e nenhum áudio ou texto sai da máquina.

### Fluxo Principal
1. **Usuário:** arrasta um áudio para o ícone da barra de menus ou para o painel. Também pode usar "Abrir arquivo…", a seleção do Finder ou o anel de ações.
2. **App:** decodifica o áudio (AVFoundation e, para formatos não nativos, FFmpeg) e transcreve com o modelo ativo ("Automático" = o mais rápido instalado). O progresso aparece no painel e no ícone da barra, com prévia do texto ao vivo.
3. **Usuário:** clica no texto para copiar tudo (aviso "Copiado" por 2 s; o botão "Copiar tudo" saiu em 11/11/2026), clica num trecho para copiar (planejado) ou exporta `.txt` / `.md`. Com "Copiar ao terminar" ligado (padrão), o texto já vai para a área de transferência e uma notificação avisa que terminou.
4. **Anel de ações:** segurando ⌥ Espaço em qualquer app, abre um menu radial em volta do cursor (inspirado no Actions Ring do Logi Options+) com: transcrever a seleção do Finder, abrir arquivo, copiar a última transcrição, colar no app atual, exportar `.md` e exportar `.txt`. Soltar um áudio no centro do anel também transcreve.
5. **Ciclo de Vida:** as transcrições ficam num histórico local ("Recentes" no painel). Nada é enviado para a nuvem. Política de retenção do histórico a definir.

---

## Status Atual (14/11/2026)

> **Agentes de IA:** Atualizem esta seção a cada nova fase completada, versão lançada ou marco importante atingido. Adicionem a nova fase no topo e movam as anteriores para baixo.

### Fase: v0.4.1 — App em três idiomas, clicar para copiar e site (14/11/2026)
- **App em inglês, português e espanhol** *(pedido do owner)*: segue o idioma do macOS. Catálogo de textos com o português como origem. Sem teste à mão.
- **Clicar no texto copia** *(pedido do owner)*: "Clique para copiar" com o mouse em cima e o aviso "Copiado" por 2 s, no lugar do botão "Copiar tudo". O texto do resultado deixou de ser selecionável. Compilado, sem teste à mão.
- **Site** em `_site/` *(pedido do owner)*: uma mesa de macOS que se pode usar (como o vorssaint.com), não uma landing tradicional. Conferido no navegador (1440×900 e celular, nos três idiomas). **Pronto para subir** *(14/11/2026)*: `python3 _site/gerar.py` gera `_site/transcreveai-site.zip`, com `/`, `/pt/` e `/es/`, imagens de compartilhamento, favicons, sitemap e `.htaccess`; passos em `_site/PUBLICAR.md`. Endereço `transcreveai.joaocorrea.design`, confirmado pelo owner *(14/11/2026)*. Publicar junto com esta versão. Link do site no README e no campo "Website" do repositório no GitHub *(14/11/2026, pedido do owner)*.
- **Número 0.4.1, não 0.5.0** *(14/11/2026, escolha do owner)*: o ROADMAP segue com a v0.5.0 para o trecho clicável e a exportação.
- **Release publicada no GitHub** (v0.4.1, 14/11/2026): os apps na v0.4.0 e na v0.3.0 recebem o aviso do Sparkle. **Sem teste à mão:** os três idiomas e o clicar para copiar no app. No Mac do owner (en-BR primeiro na lista de idiomas), o app passa a abrir em inglês.

### Fase: v0.4.0 — Transcrição, histórico e Ajustes (10/11/2026)
- **Transcreve de verdade:** "Automático" = Parakeet v3 (224× tempo real num áudio de 3 min no M4 Pro). Na primeira vez, o Apple Speech transcreve enquanto o Parakeet baixa (470 MB) e compila (cerca de 14 s, uma vez por app). O Parakeet fica carregado na memória depois disso e é aquecido na abertura do app. Escolher o Apple Speech à mão mostra a prévia ao vivo. O Whisper Turbo aparece como "em breve" (v0.6).
- **Painel:** transcrevendo (etapa, porcentagem, prévia, Cancelar), pronto (parágrafos com tempo, texto selecionável, "Copiado") e erro (Tentar de novo). **Ícone:** anel com porcentagem, ✓ ao terminar e bolinha vermelha de "não visto". **Som** ao terminar.
- **Histórico** *(pedido do owner)*: as 3 recentes no painel, "Ver tudo" com busca, reabrir, copiar e apagar, guardado só neste Mac (500 mais recentes) e, por padrão, **só até desligar ou reiniciar** (pedido do owner). Lixeira ao passar o mouse. **Ajustes** de verdade (geral, modelo e idioma padrão, histórico, atualizações), também no botão direito do ícone. Abrir ao arrastar agora vale também para as pilhas do Dock (testado pelo owner). Corrigido: abrir os Ajustes derrubava o app.
- **FFmpeg embutido** para WebM, WMA, MKV e AMR; os motores ficam no pacote local `files/Pacotes/TranscreveMotores`, testável pelo terminal (`transcrever`).
- **Testado pelo owner** *(10/11/2026)*: som e bolinha vermelha, fechar ao clicar fora, histórico com lixeira, Ajustes, arrastar do Dock e, depois da release, soltar direto no ícone da barra. **Sem teste à mão:** áudios longos (30 min ou mais).
- **Release publicada no GitHub** (v0.4.0, 10/11/2026), ainda com assinatura ad-hoc: os apps na v0.3.0 recebem o aviso do Sparkle.

### Fase: v0.3.0 — Esqueleto do app de menu bar, primeira release (10/11/2026)
- **App em `files/`**: ícone na barra de menus (`NSStatusItem`) e painel sem borda embaixo dele (`NSPanel` + SwiftUI), como no mockup. Aceita áudio solto no painel, no ícone da barra ou por "Abrir com". Tem os menus de modelo e de idioma, e o "…" com Copiar ao terminar, Abrir ao iniciar o Mac, Procurar atualizações, Ajustes e Sair. Ainda não transcreve (v0.4).
- **Atualizações pelo Sparkle 2**, com a mesma lógica do Cutline: `_dev/distribuir.sh`, chave EdDSA em `_privado/` e um `appcast-<versão>.xml` por versão. O pipeline foi testado localmente (DMG assinado e assinatura conferida). **Primeira release publicada no GitHub** (v0.3.0, 10/11/2026), com assinatura ad-hoc: na primeira abertura é preciso usar "Abrir Mesmo Assim".
- **Abrir ao arrastar** *(10/11/2026)*: o painel abre sozinho quando um áudio começa a ser arrastado em qualquer app e fecha se o arquivo for solto em outro lugar (opção no menu "…"). **Botão direito no ícone:** Procurar atualizações…, Abrir ao iniciar o Mac e Sair.
- **Bug corrigido** *(10/11/2026)*: o painel fechava logo depois do clique no ícone (no macOS 26+, o clique também chega ao monitor global).
- **Testado pelo owner** *(10/11/2026)*: clique no ícone, abrir ao arrastar e soltar no painel. Soltar direto no ícone da barra foi testado depois, na v0.4.0 *(10/11/2026)*.

### Fase: v0.2.0 — Prova de velocidade dos motores (10/11/2026)
- **Benchmark** em `_testes/benchmark/`, rodado em 3 notas de voz pt-BR no M4 Pro. Velocidade de transcrição: Parakeet v3 145× tempo real, Apple Speech 73×, whisper.cpp Turbo 25×, Whisper Turbo 22×, Whisper Large v3 3×. O Whisper Large v3 cortou parte de um áudio e o whisper.cpp alucinou uma repetição.
- **Motores aprovados**: "Automático" = Parakeet v3, com Apple Speech de reserva (sem download, usado enquanto o Parakeet baixa) e Whisper Large v3 Turbo como opção de qualidade. Whisper Large v3 e whisper.cpp ficaram fora do app. Detalhes em `_docs/MEMORIA.md`, Sessão 2.

### Fase: Setup Inicial — Documentação e mockup de UI (10/11/2026)
- **Mockup interativo da UI**: canvas externo "TranscreveAI Mockup" com duas versões, janela e menu bar. **Formato escolhido: menu bar** (página "Menu bar" do canvas). A página "Janela" fica só como referência.
- **Documentação e versionamento**: `_docs/` preenchido com o escopo do projeto e git iniciado na `v0.1.0`.

### Pendências para Futuro (Roadmap Curto)
- [x] Benchmark de motores em pt-BR (concluído na v0.2.0, 10/11/2026).
- [x] Criar o projeto Xcode (app de menu bar, macOS 26+), com atualizações pelo Sparkle (v0.3.0, 10/11/2026).
- [ ] Criar o certificado de assinatura "TranscreveAI" no Acesso às Chaves antes do anel (v0.8), para o macOS não pedir de novo a permissão de Acessibilidade a cada versão.
- [x] Pipeline de áudio: AVFoundation + FFmpeg embutido (v0.4.0, 10/11/2026).
- [ ] Painel: transcrição clicável e exportação `.txt` / `.md` (v0.5). Área de arrastar, progresso e prévia ao vivo prontos na v0.4.0 *(10/11/2026)*.
- [ ] Notificação ao terminar (v0.7). Progresso no ícone, som e "Copiar ao terminar" prontos na v0.4.0 *(10/11/2026)*.
- [ ] Anel de ações com atalho global ⌥ Espaço.
- [ ] Repetir o benchmark com áudio longo (30 min ou mais) e transcrição de referência antes da v1.0.

Lista completa e ordenada em `_docs/ROADMAP.md`.

---

## Decisões Técnicas

### Stack
- **Linguagem/Framework Core:** Swift 6+ e SwiftUI, com AppKit onde o SwiftUI não cobre (arrastar sobre o `NSStatusItem`, painel flutuante do anel, atalho global). Alvo: macOS 26 (Tahoe) ou superior, exigido pelo motor nativo `SpeechAnalyzer`.
- **Banco de Dados:** sem banco servidor. Histórico e preferências salvos localmente em Application Support. A escolha entre SwiftData e JSON fica para a implementação.
- **Styling:** SwiftUI nativo seguindo as Human Interface Guidelines do macOS.
- **Bibliotecas Externas:**
  - **FluidAudio (Parakeet TDT v3, CoreML)**: **motor padrão do "Automático"** (decidido em 10/11/2026). Foi o mais rápido no benchmark (145× tempo real no M4 Pro); baixa cerca de 470 MB uma única vez.
  - **Apple Speech (`SpeechAnalyzer` / `SpeechTranscriber`)**: motor nativo, sem download (73× tempo real). É a reserva, usada na primeira execução enquanto o Parakeet baixa e compila.
  - **WhisperKit (Argmax)**: só o Whisper Large v3 Turbo (cerca de 1,6 GB, 22× tempo real), como opção de qualidade baixada sob demanda. O Whisper Large v3 completo e o whisper.cpp ficaram fora: foram lentos ou instáveis no benchmark.
  - **FFmpeg 9.0.2 (LGPL 2.1)**: binário mínimo próprio (só decodifica áudio e grava WAV, universal, 8,2 MB), em `Contents/Helpers/ffmpeg` e chamado como processo separado. Compilado por `_dev/ffmpeg/compilar.sh`. No macOS 27 ele só é preciso para WebM, WMA, MKV e AMR: o sistema já abre MP3, M4A/AAC, MP4/MOV, WAV, AIFF, FLAC, OGG e **Opus (WhatsApp)** *(10/11/2026)*.
  - **Sparkle 2 (2.10.1, SPM)**: atualizações automáticas pelo GitHub Releases, conferidas com EdDSA (`SUPublicEDKey`), com a mesma lógica do Cutline. Desligado nos builds de debug *(10/11/2026)*.
  - **Atalho global do anel**: biblioteca a definir (ex.: KeyboardShortcuts) ou API nativa. "Segurar e soltar" exige monitor global de eventos.

### Hospedagem / Infraestrutura
- **Ambiente de Deploy:** **fora da App Store e sem sandbox**, porque o atalho global e o "Colar no app" precisam da permissão de Acessibilidade. Instalador DMG no GitHub Releases (`joaogmcorrea/transcreveAI`), atualizado pelo Sparkle 2 com a mesma lógica do Cutline *(10/11/2026)*.
- **Processo de Deploy:** `./_dev/distribuir.sh --publicar` depois do commit e da tag da versão (skill `versionamento`). O script gera o DMG assinado com EdDSA, o `appcast.xml` e as cópias `appcast-<versão>.xml`, e cria a release. Quem atualiza os apps instalados é a **release**, não o push. A chave privada fica em `_privado/` e **não pode se perder**: sem ela, os apps instalados não aceitam novas versões *(10/11/2026)*.
- **Versionamento local:** git (commit + tag `vX.Y.Z` via `_docs/versionar.sh`).
- **Site:** `_site/index.html` é a fonte (prévia local: `python3 -m http.server --directory _site`, *11/11/2026*). `python3 _site/gerar.py` monta o site publicável em `_site/dist/` e no zip (fora do git); sobe para a mesma Hostinger do Cutline (LiteSpeed, `.htaccess`), atrás do Cloudflare, em `public_html/transcreveai/`. Endereço `https://transcreveai.joaocorrea.design`, confirmado pelo owner (constante `SITE`; outro: `--site`). Passo a passo em `_site/PUBLICAR.md` *(14/11/2026)*.
- **Licença:** MIT, em nome de João Corrêa (`LICENSE` na raiz), escolhida pelo owner. Os componentes de terceiros mantêm as suas (`files/LICENCAS.md`) *(10/11/2026)*.

### Design System / UI
- **Cores Principais:**
  - `--accent`: cor de destaque do sistema (azul `#0071E3` no mockup).
  - `--surface`: painel `#262628` no escuro e `#F6F6F8` no claro (materiais nativos no app real).
  - `--bg`: segue a aparência do sistema (claro/escuro).
- **Tipografia:** `SF Pro` (fonte do sistema) para a interface e `SF Mono` para prévias de arquivo.
- **Estética e Práticas:** minimalismo extremo. Uma única área de arrastar. Segue o modo claro/escuro do sistema. A tela principal mostra só arrastar, modelo, idioma e recentes; o resto fica no menu "…" ou em Ajustes. Textos em pt-BR, inglês e espanhol, conforme o idioma do macOS *(11/11/2026; antes, só pt-BR)*.
- **Site:** imita o macOS escuro (fonte do sistema, azul de destaque do macOS, botões de janela coloridos, vidro, menus e Dock). Do design system do site do Cutline (`Vibecoding/Cutline/_design/site-design-system/`), só o papel de parede (o KV: preto, brilho violeta e a grade do tapete) e as cores dos ícones, a pedido do owner *(11/11/2026)*.

---

## Estrutura de Dados

### Tabelas/Coleções do Banco (se aplicável)
```text
Transcricao      — arquivo de origem (nome, duração, tamanho), idioma, modelo usado, tempo de processamento, data; tem vários Segmento
Segmento         — início/fim em segundos e texto; base para copiar por trecho e para os tempos do .md
Preferencias     — modelo (Automático por padrão), idioma, copiar ao terminar, abrir ao iniciar, atalho do anel
BenchmarkModelo  — modelo e velocidade medida no Mac do usuário (× tempo real); alimenta o modo Automático
```

### Regras de Negócio Core
- **Velocidade primeiro:** o modelo padrão é sempre "Automático", que usa o modelo instalado mais rápido medido no próprio Mac. O usuário pode trocar manualmente pelo seletor.
- **100% local:** nenhum áudio ou texto sai do Mac. A rede só é usada para baixar modelos opcionais, com consentimento.
- **Qualquer formato:** tenta o AVFoundation primeiro e cai para o FFmpeg embutido (WAV 16 kHz mono temporário, apagado no fim). Se nada decodificar, mostra um erro claro.
- **Idioma no Apple Speech:** ele não detecta o idioma sozinho; no "Auto" usa **pt-BR** (o idioma do sistema errava num Mac em inglês). O Parakeet detecta sozinho *(10/11/2026)*.
- **Segundo plano:** fechar o painel só esconde a janela; a transcrição continua (sem App Nap nem sono do Mac) até terminar ou até o Cancelar. Ao terminar com o painel fechado: som, ✓ no ícone e bolinha vermelha até abrir o painel *(10/11/2026)*.
- **Exportação:** `.txt` = só o texto, em parágrafos. `.md` = título, metadados (duração, idioma, data) e `**[mm:ss]**` em cada parágrafo.
- **Copiar ao terminar:** ligado por padrão. Ao concluir, a transcrição inteira (parágrafos separados por linha em branco) vai para a área de transferência. **Som ao terminar** (Glass; Basso no erro) também vem ligado.

---

## Estrutura de Pastas

> **Convenção para Agentes:** Os arquivos do app (projeto Xcode e código Swift) ficam em `files/`. Testes e benchmark ficam em `_testes/`, e os áudios de teste em `_testes/audios/` (fora do git). A documentação fica em `_docs/`. Modelos, builds e WAVs temporários ficam em `~/Library/Caches/TranscreveBench`, nunca dentro do Dropbox. A estrutura interna de `files/` é a planejada; ajuste aqui se mudar.

```text
TranscreveAI/
├── _docs/                 # Documentação iterativa do projeto para IAs
├── .agent/                # Regras, skills e workflows para outros agentes
├── .gitignore             # Exclusões do versionamento
├── README.md              # Apresentação pública no GitHub (10/11/2026)
├── LICENSE                # Licença MIT do projeto, em nome de João Corrêa (10/11/2026)
├── _testes/               # Testes e benchmark
│   ├── benchmark/         # Pacote Swift do benchmark de motores (v0.2.0)
│   ├── audios/            # Áudios de teste (fora do git)
│   └── resultados/        # Saídas e relatório do benchmark (fora do git)
├── _dev/                  # Distribuição (distribuir.sh, dist/), a receita do FFmpeg (ffmpeg/compilar.sh) e os GIFs do README (gifs/, 10/11/2026)
├── _site/                 # Site: index.html (fonte, a mesa de macOS), cutline.png, gerar.py → dist/ + zip (fora do git), imagens.mjs → imagens/, PUBLICAR.md (14/11/2026)
├── _privado/              # Chave EdDSA das atualizações (fora do git; fazer backup)
└── files/                 # ← ARQUIVOS DO APP AQUI
    ├── TranscreveAI.xcodeproj
    ├── TranscreveAI-Info.plist   # Chaves do Sparkle e tipos de arquivo
    ├── LICENCAS.md + LICENSE-*.txt   # Licenças de terceiros (Sparkle, FluidAudio, fastcluster)
    ├── Pacotes/TranscreveMotores/   # Pacote Swift local: Parakeet, Apple Speech, conversão, parágrafos e o CLI `transcrever`
    ├── Vendor/ffmpeg/     # FFmpeg mínimo (binário + licença + versão), gerado por _dev/ffmpeg/compilar.sh
    └── TranscreveAI/      # Pasta sincronizada do alvo (arquivo novo entra sozinho)
        ├── App/           # Entrada do app, estado e atualizações (Sparkle)
        ├── UI/            # Ícone da barra, painel, Ajustes; depois transcrição e anel
        ├── Audio/         # Formatos aceitos (a conversão fica no pacote TranscreveMotores)
        ├── Transcription/ # WhisperKit e benchmark local do Automático (v0.6); os motores atuais estão no pacote
        ├── Export/        # Geração de .txt e .md: v0.5
        └── Storage/       # Preferências e histórico (10/11/2026)
```

---

## Documentação do Projeto

| Arquivo | Propósito para a IA |
|---------|-----------|
| `_docs/CONTEXTO.md` | Este arquivo. Visão macro, status de desenvolvimento e stack tech. |
| `_docs/MEMORIA.md` | Diario de bordo da IA: Troubleshooting, erros passados a não repetir e dev notes. |
| `_docs/SCRIPTS-LOGIC.md` | Mapeamento exato de onde está rodando cada função, scripts base e endpoints. |
| `_docs/ROADMAP.md` | Lista completa e ordenada de milestones futuros do projeto. |
| `_docs/REGRAS_CONDUTA.md` | Restrições rígidas específicas do projeto (ex: "Nunca usar shadow DOM"). |
| `README.md` | Apresentação pública do projeto no GitHub, **em inglês** (pedido do owner; os docs seguem em pt-BR; o app passou a ter inglês e espanhol em 11/11/2026): o que faz, como usar, motores, formatos, privacidade, instalar e compilar. Atualizar quando uma versão mudar o que o app faz *(10/11/2026)*. |

---

## Sobre o Usuário (Owner)

- **Nome:** João Corrêa
- **Papel:** Owner e único usuário do app. Desenvolve com assistência de IA e valida a UI por mockups interativos antes da implementação.
- **Ambiente:** Mac
- **Preferências Técnicas:** Foco absurdo em velocidade de transcrição e em UI mínima. App nativo em Swift. Tudo local. Mockup aprovado antes de qualquer tela nova.
