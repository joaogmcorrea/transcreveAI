# Pôr o site no ar

O site é estático: três páginas (`/` em inglês, `/pt/` e `/es/`), as imagens e os arquivos para buscadores. Vai para a mesma Hostinger do Cutline (LiteSpeed, lê `.htaccess`), atrás do Cloudflare. Endereço: **https://transcreveai.joaocorrea.design** (constante `SITE` no `gerar.py`; outro endereço: `--site`).

> **Quando publicar:** junto com a versão do app que traz os três idiomas e o "clique para copiar". O site já mostra as duas coisas, e a v0.4.0 ainda não as tem.

## 1. Montar

```bash
python3 _site/gerar.py
```

Escreve `_site/dist/` e `_site/transcreveai-site.zip` (o conteúdo de `dist/`, sem pasta em volta). Se a cara da página mudou (painel, mesa, Dock), desenhe de novo as imagens de compartilhamento antes: `python3 _site/gerar.py --imagens` (precisa do Google Chrome e do Node 24+).

## 2. Primeira vez: subdomínio, DNS e HTTPS

1. **Hostinger** (hPanel › Domínios › Subdomínios): criar `transcreveai` em `joaocorrea.design`, com a pasta `public_html/transcreveai` (a do Cutline é `public_html/cutline`).
2. **Cloudflare** (DNS de `joaocorrea.design`): criar o registro `transcreveai` igual ao do `cutline` (mesmo tipo e destino), com a nuvem laranja (proxied).
3. **HTTPS:** no hPanel, instalar o SSL do subdomínio (Segurança › SSL), para o Cloudflare em "Full" falar com o servidor. O redirecionamento para `https://` fica com o Cloudflare ("Always Use HTTPS"), não com o `.htaccess`.

## 3. Subir

1. hPanel › Gerenciador de Arquivos › `public_html/transcreveai/`.
2. Enviar `_site/transcreveai-site.zip`, clicar com o botão direito › **Extrair** nessa mesma pasta e apagar o zip.
3. Conferir que o `.htaccess` veio junto (é um arquivo oculto: ligar "mostrar arquivos ocultos").

Por SFTP também serve: o conteúdo de `_site/dist/` (incluindo o `.htaccess`) dentro de `public_html/transcreveai/`.

## 4. Conferir

- https://transcreveai.joaocorrea.design/, `/pt/` e `/es/` abrem no idioma certo; trocar o idioma na barra de menus da página muda a URL.
- `/robots.txt`, `/sitemap.xml` e `/llms.txt` abrem.
- Colar o link num chat (ou num depurador de Open Graph) e ver a imagem com o painel aberto.
- Google Search Console: adicionar `transcreveai.joaocorrea.design` e enviar o `sitemap.xml`.

## Atualizar depois

Rodar `gerar.py` de novo e subir o zip por cima (Extrair substitui os arquivos). As imagens ficam uma semana no cache: se a imagem de compartilhamento mudou, limpar o cache dela no Cloudflare (Caching › Purge).
