# TranscreveAI

Transcrição de áudio local, rápida e minimalista, na barra de menus do macOS.

Solte um áudio no ícone e o texto aparece em segundos. O áudio nunca sai do seu Mac.

**[Baixar a versão mais recente (DMG)](https://github.com/joaogmcorrea/transcreveAI/releases/latest/download/TranscreveAI.dmg)** · [Todas as versões](https://github.com/joaogmcorrea/transcreveAI/releases) · Requer macOS 26 ou mais novo

---

## Por quê

Os apps de transcrição costumam ser lentos e cheios de opções na tela. O TranscreveAI faz uma coisa só: recebe um áudio e devolve o texto, o mais rápido possível. Fica na barra de menus, sem janela e sem ícone no Dock.

## Como usar

Há quatro jeitos de entregar um áudio:

- **Clique no ícone** da barra de menus e solte o arquivo no painel (ou clique na área para escolher o arquivo).
- **Solte direto no ícone** da barra.
- **Comece a arrastar** um áudio no Finder, na Mesa ou nas pilhas do Dock: o painel abre sozinho e fecha se você soltar em outro lugar.
- **Abrir com › TranscreveAI** no Finder.

Pode fechar o painel no meio da transcrição. O ícone mostra o progresso, toca um som ao terminar e fica com uma bolinha vermelha até você ver o resultado. O texto já vai para a área de transferência ("Copiar ao terminar", ligado por padrão).

O botão direito no ícone abre Procurar atualizações…, Ajustes…, Abrir ao iniciar o Mac e Sair. Esc ou um clique fora fecham o painel.

## O que faz

- **Transcrição local:** nada vai para a nuvem.
- **Texto em parágrafos** com o tempo de cada um, selecionável, e "Copiar tudo".
- **Histórico** com busca: reabrir, copiar e apagar (lixeira ao passar o mouse). Por padrão, ele é apagado quando você desliga ou reinicia o Mac. Dá para mudar isso em Ajustes › Histórico.
- **Modelo e idioma** no rodapé do painel e em Ajustes. Idiomas: Auto, Português, English e Español.
- **Atualizações automáticas** pelo [Sparkle](https://sparkle-project.org), conferidas com assinatura EdDSA.

## Motores

| Modelo | Para quê | Download |
|---|---|---|
| **Automático** (padrão) | Usa sempre o mais rápido instalado. Hoje é o Parakeet v3. | — |
| **Parakeet v3** (NVIDIA, pelo [FluidAudio](https://github.com/FluidInference/FluidAudio)) | O mais rápido. Detecta o idioma sozinho. | 470 MB, uma vez |
| **Apple Speech** | Nativo do macOS. Mostra a prévia ao vivo. | Sem download |
| **Whisper Large v3 Turbo** | Alternativa de qualidade | Em breve |

Na primeira transcrição, o Apple Speech cuida do arquivo enquanto o Parakeet baixa e é preparado para o Neural Engine (cerca de 14 s, uma vez só). Daí em diante, o Automático usa o Parakeet.

### Velocidade

Benchmark com 3 notas de voz em português num Mac com M4 Pro. Os números são o tempo de áudio transcrito por segundo de trabalho: 145× quer dizer 1 minuto de áudio em menos de meio segundo.

| Motor | Velocidade |
|---|---|
| Parakeet v3 | 145× |
| Apple Speech | 73× |
| whisper.cpp (Turbo) | 25× |
| Whisper Large v3 Turbo | 22× |
| Whisper Large v3 | 3× |

Dentro do app, com o modelo já carregado, o Parakeet transcreveu 3 minutos de áudio em 0,77 s (224×). Ainda falta medir com áudios longos (30 minutos ou mais), antes da v1.0. O whisper.cpp e o Whisper Large v3 ficaram fora do app.

## Formatos

- **Pelo próprio macOS:** MP3, M4A/AAC, MP4/MOV, WAV, AIFF, FLAC, OGG e Opus (áudio do WhatsApp).
- **Pelo FFmpeg embutido** (9.0.2, LGPL): WebM, WMA, MKV e AMR.

## Privacidade

O áudio e o texto ficam no Mac. O app só usa a internet para:

- baixar o modelo Parakeet uma vez, do Hugging Face;
- baixar o pacote de idioma do Apple Speech, se o macOS ainda não tiver;
- procurar atualizações no GitHub.

O histórico fica em `~/Library/Application Support/TranscreveAI/Historico`, e o modelo em `~/Library/Application Support/TranscreveAI/Modelos`.

## Instalar

1. Baixe o [`TranscreveAI.dmg`](https://github.com/joaogmcorrea/transcreveAI/releases/latest/download/TranscreveAI.dmg) e arraste o TranscreveAI para Aplicativos.
2. Na primeira abertura, o macOS avisa que não pode verificar o app, porque ele ainda não tem assinatura paga da Apple. Vá em **Ajustes do Sistema › Privacidade e Segurança** e clique em **Abrir Mesmo Assim**.
3. O ícone aparece na barra de menus. As próximas versões chegam sozinhas.

## Compilar

Testado com o Xcode 27.2 e o macOS 26 ou mais novo.

```bash
git clone https://github.com/joaogmcorrea/transcreveAI.git
cd transcreveAI
open files/TranscreveAI.xcodeproj
```

- O binário do FFmpeg já vem no repositório (`files/Vendor/ffmpeg/`). Para recompilar: `_dev/ffmpeg/compilar.sh`.
- Para testar os motores pelo terminal, sem o app:

  ```bash
  swift run --package-path files/Pacotes/TranscreveMotores transcrever caminho/do/audio.m4a parakeet
  ```

  O motor pode ser `parakeet` ou `apple`, seguido do idioma, se quiser.
- As releases saem por `_dev/distribuir.sh`. Ele precisa da chave EdDSA do projeto, que não está no repositório.

## Estrutura

| Pasta | O que tem |
|---|---|
| `files/` | O app: projeto Xcode, código SwiftUI/AppKit, FFmpeg e licenças |
| `files/Pacotes/TranscreveMotores/` | Os motores de transcrição (pacote Swift, testável pelo terminal) |
| `_dev/` | Scripts de distribuição e da compilação do FFmpeg, e as notas de cada versão |
| `_docs/` | Contexto, decisões, changelog e roadmap (em português) |
| `_testes/benchmark/` | O benchmark dos motores |

## Próximos passos

- **v0.5:** clicar num trecho para copiar e exportar `.txt` / `.md`.
- **v0.6:** Whisper Large v3 Turbo.
- **v0.7:** notificação ao terminar.
- **v0.8:** anel de ações com o atalho ⌥ Espaço.
- **v1.0:** polimento e testes com áudios longos.

O roadmap completo fica em [`_docs/ROADMAP.md`](_docs/ROADMAP.md), e o que mudou em cada versão, em [`_docs/CHANGELOG.md`](_docs/CHANGELOG.md).

## Licenças de terceiros

Sparkle (MIT), FluidAudio (Apache 2.0), FFmpeg (LGPL 2.1) e o modelo Parakeet TDT 0.6B v3 (CC BY 4.0). Os detalhes estão em [`files/LICENCAS.md`](files/LICENCAS.md).

---

Feito por [João Corrêa](https://github.com/joaogmcorrea).
