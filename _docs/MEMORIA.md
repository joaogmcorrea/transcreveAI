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
