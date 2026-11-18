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

---

## [0.5.0] - 18/11/2026

### Adicionado
- Texto ao vivo enquanto transcreve (pedido do owner, 17/11/2026): o Parakeet passou a entregar o texto aos pedaços, e o painel mostra os parágrafos na mesma caixa do resultado enquanto o resto é transcrito. O primeiro texto aparece em cerca de 0,1 s, qualquer que seja a duração do áudio. Clicar no texto durante a transcrição copia o que já saiu (escolha do owner). A caixa é a mesma quando termina: quem estava lendo no meio não volta para o topo.
- Botão direito do Finder (pedido do owner, 17/11/2026, como o PowerClick): "Transcrever com o TranscreveAI" › "Copiar o texto" ou "Exportar como .txt", em áudios e vídeos. Transcreve em segundo plano, sem abrir o painel (progresso e ✓ no ícone da barra, som ao terminar). O `.txt` fica ao lado do áudio (`nome.txt`, ou `nome 2.txt` se já existir). Extensão do Finder (alvo `TranscreveFinder`), ligada sozinha na primeira abertura e também em Ajustes › Geral. O app só aceita pedidos da própria extensão. Testado pelo owner (o item aparece e funciona); sem teste à mão dentro do Dropbox e com vários arquivos.
- Fila (escolha do owner): vários áudios de uma vez (Finder, arrastar, "Abrir arquivo…" com seleção múltipla) são transcritos um depois do outro; um áudio que chega durante uma transcrição entra no fim da fila. O painel mostra "Transcrevendo 2 de 3…" e quem vem depois; o ícone mostra o progresso da fila inteira. No "Copiar o texto" com vários áudios, vai tudo junto, cada texto com o nome do arquivo em cima.

### Alterado
- O áudio é lido e convertido aos poucos, junto com a transcrição: 10 min de áudio passaram de 2,7 s para 2,4 s; 60 min ficaram iguais (13,0 s antes, 13,2 s agora), no M4 Pro.
- Um áudio solto durante uma transcrição entra na fila, em vez de cancelar a atual.
- Os GIFs do README mostram o texto aparecendo durante a transcrição.
- Número da versão: 0.5.0 (escolha do owner); os marcos seguintes do ROADMAP andaram uma casa (trecho clicável e exportação no painel na v0.6.0, Whisper na v0.7.0, notificação na v0.8.0, anel na v0.9.0).

---

## [0.4.1] - 14/11/2026

### Adicionado
- README do repositório no GitHub, em inglês (só no repositório, o app não muda): o que faz, como usar, motores e velocidade, formatos, privacidade, instalar e compilar.
- Licença MIT do projeto (`LICENSE` na raiz), pedido do owner. As licenças de terceiros continuam em `files/LICENCAS.md`.
- GIFs animados no README, em estilo de vídeo-tutorial flat (pedido do owner): soltar e transcrever, arrastar da pilha do Dock e painel fechado com o progresso no ícone. Desenhados quadro a quadro por `_dev/gifs/animacoes.swift`, sem gravação de tela. Tudo em inglês, legendas e interface desenhada (pedido do owner, 11/11/2026).
- App em inglês, português e espanhol (pedido do owner, 11/11/2026): segue o idioma do macOS, ou o idioma escolhido para o app em Ajustes do Sistema › Geral › Idioma e Região. Sem teste à mão.
- Site em `_site/` (pedido do owner, 11/11/2026): uma mesa de macOS que se pode usar, no estilo do vorssaint.com, sem cara de landing page. Arquivos de exemplo na mesa, no Finder e na pilha de Downloads do Dock para arrastar até o ícone da barra; o painel, os menus, os Ajustes, o histórico e o Sair imitam o app. No Dock: baixar o DMG, os Ajustes do app, GitHub, Buy Me a Coffee (buymeacoffee.com/joaocorrea), a pilha de Downloads e o Cutline (à direita da pilha); no celular, o Dock cabe sem espremer os ícones a partir de 320 px. Do design system do Cutline, só o papel de parede e as cores dos ícones; o resto segue o macOS. Inglês, português e espanhol. Ainda não está no ar.
- Site pronto para subir ao servidor (pedido do owner, 14/11/2026): `_site/gerar.py` monta `_site/dist/` e `_site/transcreveai-site.zip` com uma URL por idioma (`/`, `/pt/`, `/es/`), cada uma com título, descrição, `canonical`, `hreflang`, Open Graph e dados estruturados próprios; imagem de compartilhamento por idioma (a própria página com uma transcrição pronta), favicons, `robots.txt`, `sitemap.xml`, `llms.txt`, `site.webmanifest` e `.htaccess` para a Hostinger. Trocar o idioma na barra de menus da página muda a URL. Imagens desenhadas por `_site/imagens.mjs` (Chrome sem janela). Passos em `_site/PUBLICAR.md`. Endereço: transcreveai.joaocorrea.design (escolhido pelo owner).
- Link do site no README e no campo "Website" do repositório no GitHub (pedido do owner, 14/11/2026).

### Alterado
- Copiar o texto (pedido do owner, 11/11/2026): clicar na transcrição copia tudo (com o mouse em cima, aparece "Clique para copiar" no rodapé) e o aviso "Copiado" aparece por 2 s embaixo no painel, também ao copiar pelo histórico e ao terminar com "Copiar ao terminar". Saiu o botão "Copiar tudo"/"Copiado"; o texto do resultado deixou de ser selecionável. No app e no site; GIFs do README refeitos. Sem teste à mão no app.

### Corrigido
- 

---

## [0.4.0] - 10/11/2026

### Adicionado
- Transcrição de verdade: Parakeet v3 no "Automático" (o mais rápido) e Apple Speech de reserva enquanto o Parakeet baixa (470 MB, uma vez). Painel com progresso, prévia ao vivo (Apple Speech), parágrafos com tempo e texto selecionável. Sem teste à mão com áudios longos.
- Progresso no ícone da barra (anel com porcentagem), ✓ ao terminar e bolinha vermelha até abrir o painel. Som ao terminar (opção no "…").
- "Copiar ao terminar" passou a copiar o texto ao concluir.
- FFmpeg embutido (9.0.2, LGPL) para WebM, WMA, MKV e AMR; o macOS já abre MP3, M4A, MP4, WAV, FLAC, OGG e Opus.
- Licenças de terceiros em `files/LICENCAS.md`.
- Histórico local das transcrições (pedido do owner): as 3 recentes no painel, "Ver tudo" com busca, reabrir, copiar e apagar; guarda as 500 mais recentes, só neste Mac. "Copiar tudo" no resultado.
- Ajustes de verdade: geral, modelo e idioma padrão, histórico (guardar, limpar) e atualizações. Também no botão direito do ícone.
- Lixeira ao passar o mouse nos itens do histórico (pedido do owner).

### Alterado
- A transcrição continua em segundo plano com o painel fechado, sem App Nap nem sono do Mac.
- O painel fecha no instante do clique fora (antes, só quando o botão do mouse era solto, o que dava um atraso). Pedido do owner.
- O histórico vale só para a sessão do Mac: ao desligar ou reiniciar, é apagado (pedido do owner; opção em Ajustes › Histórico).
- "Abrir ao arrastar um áudio" também funciona arrastando das pilhas do Dock, não só do Finder (pedido do owner; testado pelo owner). O Dock não usa a área de arraste comum: uma janela transparente aparece por um instante para receber o arraste e ler o arquivo.

### Corrigido
- Abrir os Ajustes derrubava o app (ciclo de layout da janela); agora ela tem tamanho fixo. Achado pelo owner ("não acontece nada").

---

## [0.3.0] - 10/11/2026

### Adicionado
- App de barra de menus em `files/` (projeto Xcode, macOS 26+): ícone na barra e painel embaixo dele, como no mockup. Aceita áudio solto no painel, no ícone ou por "Abrir com". Menus de modelo e de idioma, menu "…" e janela de Ajustes. Testado pelo owner, menos soltar direto no ícone.
- Atualizações pelo Sparkle 2 com a mesma lógica do Cutline: `_dev/distribuir.sh` (DMG, appcast assinado com EdDSA e uma cópia por versão), "Procurar atualizações…" e ajuste para procurar automaticamente. Chave privada em `_privado/`, fora do git.
- O painel abre sozinho quando um áudio começa a ser arrastado em qualquer app (Finder, Mesa, Downloads) e fecha se ele for solto em outro lugar. Opção "Abrir ao arrastar um áudio" no menu "…", ligada por padrão. Testado pelo owner.
- Menu do botão direito no ícone da barra: Procurar atualizações…, Abrir ao iniciar o Mac e Sair do TranscreveAI.
- Primeira release no GitHub (DMG + appcast): a partir desta versão, os apps instalados recebem as próximas atualizações.

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
