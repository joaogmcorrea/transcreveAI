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
3. **Usuário:** clica num trecho para copiar, usa "Copiar tudo" ou exporta `.txt` / `.md`. Com "Copiar ao terminar" ligado (padrão), o texto já vai para a área de transferência e uma notificação avisa que terminou.
4. **Anel de ações:** segurando ⌥ Espaço em qualquer app, abre um menu radial em volta do cursor (inspirado no Actions Ring do Logi Options+) com: transcrever a seleção do Finder, abrir arquivo, copiar a última transcrição, colar no app atual, exportar `.md` e exportar `.txt`. Soltar um áudio no centro do anel também transcreve.
5. **Ciclo de Vida:** as transcrições ficam num histórico local ("Recentes" no painel). Nada é enviado para a nuvem. Política de retenção do histórico a definir.

---

## Status Atual (10/11/2026)

> **Agentes de IA:** Atualizem esta seção a cada nova fase completada, versão lançada ou marco importante atingido. Adicionem a nova fase no topo e movam as anteriores para baixo.

### Fase: Setup Inicial — Documentação e mockup de UI (10/11/2026)
- **Mockup interativo da UI**: canvas externo "TranscreveAI Mockup" com duas versões, janela e menu bar. **Formato escolhido: menu bar** (página "Menu bar" do canvas). A página "Janela" fica só como referência.
- **Documentação e versionamento**: `_docs/` preenchido com o escopo do projeto e git iniciado na `v0.1.0`.

### Pendências para Futuro (Roadmap Curto)
- [ ] Benchmark de motores em pt-BR (velocidade × qualidade): Apple Speech, Parakeet v3, Whisper Large v3 Turbo e Whisper Large v3.
- [ ] Criar o projeto Xcode (app de menu bar com `MenuBarExtra`, macOS 26+).
- [ ] Pipeline de áudio: AVFoundation + FFmpeg embutido.
- [ ] Painel: área de arrastar, progresso, prévia ao vivo, transcrição clicável, exportação `.txt` / `.md`.
- [ ] Progresso no ícone, notificação e "Copiar ao terminar".
- [ ] Anel de ações com atalho global ⌥ Espaço.

Lista completa e ordenada em `_docs/ROADMAP.md`.

---

## Decisões Técnicas

### Stack
- **Linguagem/Framework Core:** Swift 6+ e SwiftUI, com AppKit onde o SwiftUI não cobre (arrastar sobre o `NSStatusItem`, painel flutuante do anel, atalho global). Alvo: macOS 26 (Tahoe) ou superior, exigido pelo motor nativo `SpeechAnalyzer`.
- **Banco de Dados:** sem banco servidor. Histórico e preferências salvos localmente em Application Support. A escolha entre SwiftData e JSON fica para a implementação.
- **Styling:** SwiftUI nativo seguindo as Human Interface Guidelines do macOS.
- **Bibliotecas Externas:**
  - **Apple Speech (`SpeechAnalyzer` / `SpeechTranscriber`)**: motor nativo, sem download de modelo. Candidato a padrão mais rápido, mas a qualidade em pt-BR ainda precisa ser medida.
  - **WhisperKit (Argmax)**: Whisper Large v3 e v3 Turbo em CoreML. Modelos opcionais baixados uma única vez.
  - **FluidAudio**: Parakeet TDT v3 em CoreML, opcional. A validar no benchmark.
  - **FFmpeg (build LGPL, linkagem dinâmica)**: decodifica formatos que o AVFoundation não lê (OGG, Opus, WebM, WMA, MKV etc.). Embutido no app.
  - **Atalho global do anel**: biblioteca a definir (ex.: KeyboardShortcuts) ou API nativa. "Segurar e soltar" exige monitor global de eventos.

### Hospedagem / Infraestrutura
- **Ambiente de Deploy:** local only. App para uso próprio, assinado localmente, **fora da App Store e sem sandbox**, porque o atalho global e o "Colar no app" precisam da permissão de Acessibilidade.
- **Processo de Deploy:** build pelo Xcode e cópia para `/Applications`.
- **Versionamento local:** git (commit + tag `vX.Y.Z` via `_docs/versionar.sh`).

### Design System / UI
- **Cores Principais:**
  - `--accent`: cor de destaque do sistema (azul `#0071E3` no mockup).
  - `--surface`: painel `#262628` no escuro e `#F6F6F8` no claro (materiais nativos no app real).
  - `--bg`: segue a aparência do sistema (claro/escuro).
- **Tipografia:** `SF Pro` (fonte do sistema) para a interface e `SF Mono` para prévias de arquivo.
- **Estética e Práticas:** minimalismo extremo. Uma única área de arrastar. Segue o modo claro/escuro do sistema. A tela principal mostra só arrastar, modelo, idioma e recentes; o resto fica no menu "…" ou em Ajustes. Textos em pt-BR.

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
- **Qualquer formato:** tenta o AVFoundation primeiro e cai para o FFmpeg. Se nada decodificar, mostra um erro claro.
- **Exportação:** `.txt` = só o texto, em parágrafos. `.md` = título, metadados (duração, idioma, data) e `**[mm:ss]**` em cada parágrafo.
- **Copiar ao terminar:** ligado por padrão. Ao concluir, a transcrição inteira vai para a área de transferência.

---

## Estrutura de Pastas

> **Convenção para Agentes:** O código-fonte Swift fica em `TranscreveAI/` (projeto Xcode, ainda a criar). A documentação fica em `_docs/` e os áudios de teste em `files/` (fora do git). A estrutura interna abaixo é a planejada; ajuste aqui se mudar.

```text
TranscreveAI/
├── _docs/                 # Documentação iterativa do projeto para IAs
├── .agent/                # Regras, skills e workflows para outros agentes
├── .gitignore             # Exclusões do versionamento
├── files/                 # Áudios de teste locais (fora do git)
└── TranscreveAI/          # ← CÓDIGO FONTE AQUI (projeto Xcode)
    ├── App/               # Entrada do app, MenuBarExtra, ícone e status item
    ├── UI/                # Painel, lista de transcrição, anel de ações, componentes
    ├── Audio/             # Leitura e decodificação (AVFoundation + FFmpeg)
    ├── Transcription/     # Motores (Apple Speech, WhisperKit, Parakeet) e seleção automática
    ├── Export/            # Geração de .txt e .md
    └── Storage/           # Histórico, preferências e resultados de benchmark
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

---

## Sobre o Usuário (Owner)

- **Nome:** João Corrêa
- **Papel:** Owner e único usuário do app. Desenvolve com assistência de IA e valida a UI por mockups interativos antes da implementação.
- **Ambiente:** Mac
- **Preferências Técnicas:** Foco absurdo em velocidade de transcrição e em UI mínima. App nativo em Swift. Tudo local. Mockup aprovado antes de qualquer tela nova.
