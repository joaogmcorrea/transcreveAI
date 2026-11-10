O TranscreveAI agora **transcreve**. O "Automático" usa o Parakeet v3, o mais rápido no benchmark (cerca de 220× o tempo real num M4 Pro: 3 min de áudio em menos de 1 s), tudo no próprio Mac.

## O que tem nesta versão

- **Transcrição local.** Na primeira vez, o Parakeet v3 é baixado (470 MB, uma vez só) e, enquanto isso, o Apple Speech transcreve o arquivo. O texto sai em parágrafos com o tempo de cada um e pode ser selecionado.
- **Qualquer formato.** O macOS abre MP3, M4A, MP4, WAV, FLAC, OGG e Opus (áudio do WhatsApp); o FFmpeg embutido (9.0.2, LGPL) cuida de WebM, WMA, MKV e AMR.
- **Segue com o painel fechado.** O ícone da barra mostra o progresso, um ✓ ao terminar e uma bolinha vermelha até você abrir o resultado. Toca um som ao terminar (dá para desligar no "…"). O Mac não dorme no meio.
- **Copiar ao terminar** (ligado por padrão) e "Copiar tudo" no resultado.
- **Histórico:** as 3 últimas no painel e "Ver tudo" com busca; reabrir, copiar e apagar (lixeira ao passar o mouse). Por padrão vale só até desligar ou reiniciar o Mac; dá para manter em Ajustes › Histórico.
- **Ajustes de verdade:** geral, modelo e idioma padrão, histórico e atualizações. Também no botão direito do ícone.
- **Abrir ao arrastar** agora funciona também arrastando das pilhas do Dock.
- O painel fecha no instante do clique fora.

## Corrigido

- Abrir os Ajustes fechava o app.

## Instalar

1. Baixe o `TranscreveAI.dmg` abaixo e arraste o TranscreveAI para Aplicativos. Quem está na v0.3.0 recebe o aviso de atualização.
2. Na primeira abertura, o macOS avisa que não pode verificar o app (ele ainda não tem assinatura paga da Apple). Vá em **Ajustes do Sistema › Privacidade e Segurança** e clique em **Abrir Mesmo Assim**.

Requer macOS 26 ou mais novo.

## Ainda sem teste à mão

- Áudios longos (30 min ou mais).
- Soltar o arquivo direto no ícone da barra.

Licenças de terceiros (Sparkle, FluidAudio, FFmpeg) em `LICENCAS.md` no repositório.
