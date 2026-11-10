# Roadmap — TranscreveAI

> **Para Agentes de IA:** Lista ordenada dos marcos do projeto. Ao concluir um marco, marque-o, registre a versão no `CHANGELOG.md` e atualize o "Status Atual" do `CONTEXTO.md`. A referência visual de todos os marcos de UI é o mockup aprovado (página "Menu bar" do canvas "TranscreveAI Mockup").

## v0.2.0 — Prova de velocidade
- [x] Teste comparando Apple Speech, Parakeet v3, Whisper Large v3 Turbo e Whisper Large v3 com áudios reais em pt-BR (`_testes/audios/`), via `_testes/benchmark/rodar.sh`.
- [x] Medir o tempo (× tempo real) de cada motor. Resultado na Sessão 2 da `MEMORIA.md`.
- [x] Aprovar o motor padrão e a lista final de modelos: Parakeet v3 (Automático), Apple Speech (reserva, sem download) e Whisper Large v3 Turbo (qualidade).

## v0.3.0 — Esqueleto do app de menu bar
- [ ] Projeto Xcode (macOS 26+), `MenuBarExtra` com painel e ícone template.
- [ ] Área de arrastar no painel e arrastar direto sobre o ícone da barra.

## v0.4.0 — Pipeline de áudio e transcrição
- [ ] Decodificação com AVFoundation + FFmpeg embutido (qualquer formato).
- [ ] Transcrição com Parakeet v3 (FluidAudio), com progresso no painel e prévia ao vivo. Na primeira execução, usar o Apple Speech enquanto o Parakeet baixa e compila.
- [ ] Progresso no ícone quando o painel está fechado.

## v0.5.0 — Resultado e exportação
- [ ] Lista de trechos clicável (copia o trecho) e "Copiar tudo".
- [ ] Exportar `.txt` e `.md` (⌘E / ⇧⌘E).
- [ ] Histórico local e lista de recentes no painel.

## v0.6.0 — Modelos e modo Automático
- [ ] Seletor de modelo e de idioma.
- [ ] Download do Whisper Large v3 Turbo (WhisperKit) sob demanda, uma única vez.
- [ ] Benchmark local e modo "Automático" (mais rápido instalado) como padrão.

## v0.7.0 — Fluxo sem abrir o painel
- [ ] "Copiar ao terminar" (ligado por padrão) e notificação ao terminar.
- [ ] Menu "…": Copiar ao terminar, Abrir ao iniciar o Mac, Ajustes, Sair.

## v0.8.0 — Anel de ações
- [ ] Atalho global ⌥ Espaço (segurar e soltar), com pedido de permissão de Acessibilidade.
- [ ] Ações: transcrever seleção do Finder, abrir arquivo, copiar última, colar no app, exportar `.md`, exportar `.txt`. Soltar um áudio no centro do anel transcreve.

## v1.0.0 — Polimento
- [ ] Ícone do app, estados de erro, testes com áudios longos e variados.
- [ ] Revisão final de velocidade e de UI contra o mockup.
- [ ] Repetir o benchmark com áudio longo (30 min ou mais) e `referencia.txt` para medir a qualidade real (WER).
