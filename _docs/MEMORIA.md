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
