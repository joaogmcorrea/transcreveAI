O texto agora aparece **enquanto o áudio é transcrito**, e dá para transcrever pelo **botão direito do Finder**, sem abrir o painel.

## O que tem nesta versão

- **Texto ao vivo.** Os parágrafos aparecem no painel enquanto o resto ainda está sendo transcrito: o primeiro em cerca de 0,1 s, mesmo num áudio de 1 hora. Clicar no texto durante a transcrição copia o que já saiu. Quem está lendo no meio não volta ao topo quando termina.
- **Botão direito do Finder.** Em áudios e vídeos: **Transcrever com o TranscreveAI › Copiar o texto** ou **Exportar como .txt**. Roda em segundo plano, com o progresso e o ✓ no ícone da barra; o `.txt` fica ao lado do áudio. A extensão do Finder liga sozinha na primeira abertura, e pode ser ligada ou desligada em **Ajustes › Geral**.
- **Fila.** Vários áudios de uma vez (Finder, arrastar ou "Abrir arquivo…") são transcritos um depois do outro. Um áudio solto durante uma transcrição agora espera a vez, em vez de cancelar a atual.
- **Mais rápido em áudios médios.** O áudio é lido aos poucos, junto com a transcrição: 10 min de áudio passaram de 2,7 s para 2,4 s no M4 Pro; 1 hora ficou igual (13,2 s).

## Instalar

1. Baixe o `TranscreveAI.dmg` abaixo e arraste o TranscreveAI para Aplicativos. Quem está na v0.4.1 ou antes recebe o aviso de atualização.
2. Na primeira abertura, o macOS avisa que não pode verificar o app (ele ainda não tem assinatura paga da Apple). Vá em **Ajustes do Sistema › Privacidade e Segurança** e clique em **Abrir Mesmo Assim**.
3. Se o item não aparecer no botão direito do Finder, ligue a extensão em **Ajustes do TranscreveAI › Geral** (ou em **Ajustes do Sistema › Geral › Itens de Início e Extensões**).

Requer macOS 26 ou mais novo.

## Ainda sem teste à mão

- O botão direito dentro da pasta do Dropbox (que tem extensão própria no Finder) e com vários arquivos selecionados.
- Áudios longos de verdade (30 min ou mais); o teste de 1 hora foi feito com notas de voz repetidas.

Licenças de terceiros (Sparkle, FluidAudio, FFmpeg) em `LICENCAS.md` no repositório.
