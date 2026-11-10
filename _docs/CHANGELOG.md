# Changelog — TranscreveAI

> **Para Agentes de IA:** Este arquivo é o registro oficial e imutável das mudanças do projeto. Você DEVE atualizá-lo a cada encerramento de tarefa significativa, bugfix ou nova feature, ANTES de concluir o seu trabalho.

## Diretrizes de Versionamento para a IA

1. **Semantic Versioning:** Siga o padrão `[MAJOR.MINOR.PATCH]`:
   - `MAJOR`: Mudanças incompatíveis na API/Fluxo ou refatorações estruturais massivas.
   - `MINOR`: Novas funcionalidades compatíveis com as versões anteriores.
   - `PATCH`: Correções de bugs ou pequenas melhorias na UI/UX sem impacto estrutural.
2. **Sincronia:** Sempre que houver uma mudança `MAJOR` ou `MINOR`, verifique se o arquivo `_docs/CONTEXTO.md` ou `_docs/ROADMAP.md` precisam ser atualizados.
3. **Formatação:** Mantenha os verbos no particípio passado (ex: Adicionado, Removido, Modificado, Corrigido).
4. **Git:** Cada versão fechada corresponde a um commit + tag anotada `vX.Y.Z` criados por `_docs/versionar.sh`.

---

## [Unreleased] - Em desenvolvimento
*(Mantenha esta seção no topo para registrar mudanças que ainda não geraram uma nova versão. Assim que fechar a versão, renomeie esse bloco para o número da versão e crie um novo `[Unreleased]` aqui em cima).*

### Adicionado
- 

### Alterado
- 

### Corrigido
- 

### Removido
- 

---

## [0.2.0] - 10/11/2026

### Adicionado
- Benchmark de motores de transcrição em `_testes/benchmark/` (CLI Swift `bench`, `rodar.sh`, `relatorio.py`): Apple Speech, Parakeet v3, Whisper Large v3 Turbo, Whisper Large v3 e whisper.cpp como base.
- Motores do app definidos pelo benchmark: Parakeet v3 como padrão do "Automático", Apple Speech como reserva sem download e Whisper Large v3 Turbo como opção de qualidade.

### Alterado
- `files/` passa a ser a pasta dos arquivos do app (versionada). Os áudios de teste vão para `_testes/audios/` (fora do git).

---

## [0.1.0] - 10/11/2026

### Adicionado
- Setup inicial do projeto e documentação em `_docs/` (`CONTEXTO`, `MEMORIA`, `SCRIPTS-LOGIC`, `REGRAS_CONDUTA` e o novo `ROADMAP`).
- Versionamento via git local (`_docs/versionar.sh`: commit + tag anotada).
- `.gitignore` com exclusões de Xcode/SwiftPM, modelos de IA baixados e áudios de teste (`files/`).
- Mockup interativo da UI (versões janela e menu bar), com o formato menu bar escolhido. Fica fora do repositório, no canvas "TranscreveAI Mockup".

---
<!--
TEMPLATE DE VERSÃO PARA O AGENTE COPIAR/COLAR:

## [X.X.X] - DD/MM/AAAA

### Adicionado
- 

### Alterado
- 

### Corrigido
- 

### Removido
- 

-->
