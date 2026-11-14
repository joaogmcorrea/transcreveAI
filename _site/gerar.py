#!/usr/bin/env python3
"""Monta o site do TranscreveAI para subir ao servidor.

O index.html desta pasta é a fonte, em inglês, e também a prévia local (python3 -m http.server --directory _site).
Este script escreve em dist/ as três páginas do site, cada uma com a sua URL, título, descrição, imagem de
compartilhamento e dados para buscadores: inglês em /, português em /pt/ e espanhol em /es/. Junta os ícones e as
imagens de imagens/, a imagem do Cutline, robots.txt, sitemap.xml, llms.txt, site.webmanifest e o .htaccess
(Hostinger, LiteSpeed), e fecha tudo em transcreveai-site.zip. Como subir: PUBLICAR.md.

    python3 _site/gerar.py                    # dist/ e o zip
    python3 _site/gerar.py --imagens          # antes, desenha de novo imagens/ (node imagens.mjs; precisa do Chrome)
    python3 _site/gerar.py --site https://...  # outro endereço (o padrão é SITE, abaixo)

A versão mais nova vem da API do GitHub na hora (a página consulta de novo no navegador); sem rede, fica a do
index.html. Só a biblioteca padrão do Python.
"""
import argparse
import datetime
import html
import json
import re
import shutil
import subprocess
import sys
import urllib.request
import zipfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
SOURCE = HERE / "index.html"
IMAGES = HERE / "imagens"
OUT = HERE / "dist"
ZIP = HERE / "transcreveai-site.zip"

SITE = "https://transcreveai.joaocorrea.design"
REPO = "https://github.com/joaogmcorrea/transcreveAI"
DOWNLOAD = f"{REPO}/releases/latest/download/TranscreveAI.dmg"
RELEASE_API = "https://api.github.com/repos/joaogmcorrea/transcreveAI/releases/latest"
MIT = "https://opensource.org/license/mit"

PAGES = {
    "en": {
        "path": "",
        "html_lang": "en",
        "og_locale": "en_US",
        "title": "TranscreveAI: fast, on-device audio transcription for the Mac",
        "description": "A menu bar app that turns audio into text in seconds, on your Mac. "
                       "Try it right here: drag an audio file to the icon at the top of the screen.",
        "og_title": "TranscreveAI",
        "og_description": "Fast, on-device audio transcription in the Mac menu bar. Free and open source.",
        "og_image": "og-image.png",
        "og_image_alt": "A Mac desktop with the TranscreveAI panel open under the menu bar icon, showing a meeting "
                        "transcribed in 3.4 seconds and the Copied notice.",
        "main": """<h1>TranscreveAI</h1>
  <p>A free, open source menu bar app for macOS 26 or later that turns audio into text in seconds. Everything runs on your Mac. This page is a Mac desktop where you can try it: drag an audio file to the icon at the top of the screen.</p>
  <p><a href="{download}">Download TranscreveAI</a> · <a href="{repo}">Source code on GitHub</a></p>""",
    },
    "pt": {
        "path": "pt/",
        "html_lang": "pt-BR",
        "og_locale": "pt_BR",
        "title": "TranscreveAI: transcrição de áudio rápida e local para Mac",
        "description": "Um app de barra de menus que transforma áudio em texto em segundos, no seu Mac. "
                       "Experimente aqui mesmo: arraste um áudio até o ícone no alto da tela.",
        "og_title": "TranscreveAI",
        "og_description": "Transcrição de áudio rápida e local na barra de menus do Mac. Grátis e de código aberto.",
        "og_image": "og-image-pt.png",
        "og_image_alt": "Uma mesa de Mac com o painel do TranscreveAI aberto embaixo do ícone da barra de menus, "
                        "mostrando uma reunião transcrita em 3,4 segundos e o aviso Copiado.",
        "main": """<h1>TranscreveAI</h1>
  <p>Um app grátis e de código aberto para a barra de menus do macOS 26 ou mais recente, que transforma áudio em texto em segundos. Tudo roda no seu Mac. Esta página é uma mesa de Mac onde dá para experimentar: arraste um áudio até o ícone no alto da tela.</p>
  <p><a href="{download}">Baixar o TranscreveAI</a> · <a href="{repo}">Código no GitHub</a></p>""",
    },
    "es": {
        "path": "es/",
        "html_lang": "es",
        "og_locale": "es_LA",   # español neutro; o Open Graph pede uma região e não tem "es" sozinho
        "title": "TranscreveAI: transcripción de audio rápida y local para Mac",
        "description": "Una app de la barra de menús que convierte audio en texto en segundos, en tu Mac. "
                       "Pruébala aquí mismo: arrastra un audio hasta el ícono de arriba de la pantalla.",
        "og_title": "TranscreveAI",
        "og_description": "Transcripción de audio rápida y local en la barra de menús de tu Mac. Gratis y de código abierto.",
        "og_image": "og-image-es.png",
        "og_image_alt": "Un escritorio de Mac con el panel de TranscreveAI abierto debajo del ícono de la barra de "
                        "menús, con una reunión transcrita en 3,4 segundos y el aviso Copiado.",
        "main": """<h1>TranscreveAI</h1>
  <p>Una app gratuita y de código abierto para la barra de menús de macOS 26 o posterior, que convierte audio en texto en segundos. Todo corre en tu Mac. Esta página es un escritorio de Mac donde puedes probarla: arrastra un audio hasta el ícono de arriba de la pantalla.</p>
  <p><a href="{download}">Descargar TranscreveAI</a> · <a href="{repo}">Código en GitHub</a></p>""",
    },
}
# Os idiomas do app (não do site).
APP_LANGUAGES = ["pt-BR", "en", "es"]
ICON_FILES = ["favicon.ico", "favicon-96.png", "apple-touch-icon.png", "icon-192.png", "icon-512.png"]


def take(text, old, new):
    """Troca um trecho exato da página e para tudo se a página não tiver esse trecho uma vez só."""
    n = text.count(old)
    if n != 1:
        sys.exit(f"gerar.py: esperava uma vez no index.html, achei {n}: {old[:80]!r}")
    return text.replace(old, new)


def latest_version(fallback):
    try:
        req = urllib.request.Request(RELEASE_API, headers={"Accept": "application/vnd.github+json",
                                                           "User-Agent": "transcreveai-site-build"})
        with urllib.request.urlopen(req, timeout=10) as r:
            tag = json.load(r).get("tag_name", "")
        return tag.lstrip("v") or fallback
    except Exception as e:  # sem rede ou cota estourada: fica a do index.html
        print(f"  (versão do GitHub indisponível: {e}; usando {fallback})")
        return fallback


def structured_data(site, page, version):
    url = f"{site}/{page['path']}"
    data = {
        "@context": "https://schema.org",
        "@graph": [
            {"@type": "WebSite", "@id": f"{site}/#website", "url": f"{site}/", "name": "TranscreveAI",
             "inLanguage": [p["html_lang"] for p in PAGES.values()], "publisher": {"@id": f"{site}/#author"}},
            {"@type": "Person", "@id": f"{site}/#author", "name": "João Corrêa",
             "sameAs": ["https://github.com/joaogmcorrea"]},
            {"@type": "WebPage", "@id": f"{url}#page", "url": url, "name": page["title"],
             "description": page["description"], "inLanguage": page["html_lang"],
             "isPartOf": {"@id": f"{site}/#website"}, "about": {"@id": f"{site}/#app"},
             "primaryImageOfPage": f"{site}/{page['og_image']}"},
            {"@type": "SoftwareApplication", "@id": f"{site}/#app", "name": "TranscreveAI",
             "description": page["description"], "url": f"{site}/",
             "applicationCategory": "UtilitiesApplication", "operatingSystem": "macOS 26 or later",
             "softwareVersion": version, "downloadUrl": DOWNLOAD, "isAccessibleForFree": True, "license": MIT,
             "offers": {"@type": "Offer", "price": "0", "priceCurrency": "USD"},
             "author": {"@id": f"{site}/#author"}, "image": f"{site}/icon-512.png",
             "screenshot": f"{site}/{page['og_image']}", "inLanguage": APP_LANGUAGES,
             "releaseNotes": f"{REPO}/releases"},
            {"@type": "SoftwareSourceCode", "@id": f"{site}/#code", "name": "TranscreveAI", "codeRepository": REPO,
             "programmingLanguage": "Swift", "license": MIT, "targetProduct": {"@id": f"{site}/#app"},
             "author": {"@id": f"{site}/#author"}},
        ],
    }
    # Assim um "</" no texto não fecha o <script> antes da hora.
    return json.dumps(data, ensure_ascii=False, indent=2).replace("</", "<\\/")


def head(site, lang, version):
    page = PAGES[lang]
    e = lambda v: html.escape(v, quote=True)
    up = "../" if page["path"] else ""   # caminho até a raiz, para os arquivos ao lado da página inicial
    url = f"{site}/{page['path']}"
    image = f"{site}/{page['og_image']}"
    alternates = "\n".join(f'<link rel="alternate" hreflang="{p["html_lang"]}" href="{site}/{p["path"]}">'
                           for p in PAGES.values())
    other_locales = "\n".join(f'<meta property="og:locale:alternate" content="{p["og_locale"]}">'
                              for k, p in PAGES.items() if k != lang)
    return f"""<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<title>{e(page["title"])}</title>
<meta name="description" content="{e(page["description"])}">
<meta name="author" content="João Corrêa">
<meta name="robots" content="index, follow, max-image-preview:large">
<meta name="theme-color" content="#000000">
<link rel="canonical" href="{url}">
{alternates}
<link rel="alternate" hreflang="x-default" href="{site}/">
<link rel="icon" href="{up}favicon.ico" sizes="48x48">
<link rel="icon" href="{up}favicon-96.png" type="image/png" sizes="96x96">
<link rel="apple-touch-icon" href="{up}apple-touch-icon.png">
<link rel="manifest" href="{up}site.webmanifest">
<meta property="og:type" content="website">
<meta property="og:site_name" content="TranscreveAI">
<meta property="og:url" content="{url}">
<meta property="og:title" content="{e(page["og_title"])}">
<meta property="og:description" content="{e(page["og_description"])}">
<meta property="og:image" content="{image}">
<meta property="og:image:type" content="image/png">
<meta property="og:image:width" content="1200">
<meta property="og:image:height" content="630">
<meta property="og:image:alt" content="{e(page["og_image_alt"])}">
<meta property="og:locale" content="{page["og_locale"]}">
{other_locales}
<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:title" content="{e(page["og_title"])}">
<meta name="twitter:description" content="{e(page["og_description"])}">
<meta name="twitter:image" content="{image}">
<meta name="twitter:image:alt" content="{e(page["og_image_alt"])}">
<script type="application/ld+json">
{structured_data(site, page, version)}
</script>
"""


def build_page(source, site, lang, version):
    page = PAGES[lang]
    text = source
    # Cabeçalho: tudo entre <head> e o <style> vira o cabeçalho desta página.
    m = re.search(r"<head>\n(.*?)(?=<style>)", text, re.S)
    if not m:
        sys.exit("gerar.py: não achei o cabeçalho (<head> … <style>) no index.html")
    text = text[:m.start(1)] + head(site, lang, version) + text[m.end(1):]
    # O idioma da página e o caminho até a raiz, lidos pelo script da página (firstLang, setLang).
    attrs = f'lang="{page["html_lang"]}"' + (f' data-lang="{lang}"' if page["path"] else "") + \
            f' data-root="{"../" if page["path"] else "./"}"'
    text = take(text, '<html lang="en">', f"<html {attrs}>")
    # O texto escondido para leitores de tela e buscadores, no idioma da página.
    main = re.search(r'(<main class="sr-only">\n  )(.*?)(\n</main>)', text, re.S)
    if not main:
        sys.exit('gerar.py: não achei o <main class="sr-only"> no index.html')
    body = page["main"].format(download=html.escape(DOWNLOAD), repo=html.escape(REPO))
    text = text[:main.start(2)] + body + text[main.end(2):]
    # A versão de reserva (a página consulta o GitHub de novo no navegador).
    text = re.sub(r'let version = "[^"]*";', f'let version = "{version}";', text, count=1)
    # O ícone do Cutline no Dock fica na raiz.
    if page["path"]:
        text = take(text, 'src="cutline.png"', 'src="../cutline.png"')
    return text


def robots(site):
    return f"""# TranscreveAI: everything here is public, for search engines and AI assistants alike.
User-agent: *
Allow: /

Sitemap: {site}/sitemap.xml
"""


def sitemap(site, day):
    links = "\n".join(f'    <xhtml:link rel="alternate" hreflang="{p["html_lang"]}" href="{site}/{p["path"]}"/>'
                      for p in PAGES.values())
    links += f'\n    <xhtml:link rel="alternate" hreflang="x-default" href="{site}/"/>'
    urls = "\n".join(f"""  <url>
    <loc>{site}/{p["path"]}</loc>
    <lastmod>{day}</lastmod>
{links}
  </url>""" for p in PAGES.values())
    return f"""<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:xhtml="http://www.w3.org/1999/xhtml">
{urls}
</urlset>
"""


def llms(site, version):
    return f"""# TranscreveAI

> TranscreveAI is a free, open source menu bar app for macOS 26 or later that turns audio files into text in seconds, on the Mac itself. No audio or text leaves the Mac.

The website ({site}/) is an interactive Mac desktop: visitors drag a sample audio file to the TranscreveAI icon in the menu bar and watch the panel transcribe it. The samples have made-up text; nothing dropped on the page is read or uploaded.

## Key facts

- Drop an audio file on the menu bar icon or on the panel, and the text comes back already copied to the clipboard. Clicking the text copies it again.
- Default engine ("Automatic"): Parakeet v3 (NVIDIA, through FluidAudio on Core ML), about 145 times faster than real time on an M4 Pro. Apple Speech, built into macOS, handles the first file while Parakeet downloads once (470 MB).
- Any audio format: what macOS opens directly (MP3, M4A/AAC, WAV, AIFF, FLAC, MP4/MOV and more) plus WebM, WMA, MKV and AMR through a bundled FFmpeg.
- Recent transcriptions stay only on the Mac; by default the history is cleared when the Mac restarts.
- Interface in English, Portuguese and Spanish, following the Mac's language.
- Latest version: {version}. Free, MIT license, made by João Corrêa. Updates arrive through Sparkle.

## Links

- [Download the app (DMG)]({DOWNLOAD})
- [Source code on GitHub]({REPO})
- [Releases and notes]({REPO}/releases)
- Pages: [English]({site}/), [Português]({site}/pt/), [Español]({site}/es/)
"""


def manifest():
    return json.dumps({
        "name": "TranscreveAI",
        "short_name": "TranscreveAI",
        "description": PAGES["en"]["og_description"],
        "start_url": "./",
        "display": "browser",
        "background_color": "#000000",
        "theme_color": "#000000",
        "icons": [
            {"src": "icon-192.png", "sizes": "192x192", "type": "image/png"},
            {"src": "icon-512.png", "sizes": "512x512", "type": "image/png"},
        ],
    }, ensure_ascii=False, indent=2) + "\n"


HTACCESS = """# TranscreveAI: site estático (Hostinger, LiteSpeed). O HTTPS fica com o Cloudflare ("Always Use HTTPS"):
# um redirecionamento aqui, com o Cloudflare em SSL "Flexible", entraria em laço.
Options -Indexes
DirectoryIndex index.html
AddDefaultCharset utf-8
AddCharset utf-8 .html .txt .xml .webmanifest
AddType application/manifest+json .webmanifest

<IfModule mod_headers.c>
  Header always set X-Content-Type-Options "nosniff"
  Header always set Referrer-Policy "strict-origin-when-cross-origin"
  Header always set X-Frame-Options "SAMEORIGIN"
  Header always set Permissions-Policy "camera=(), microphone=(), geolocation=()"
  # Páginas e textos: sempre conferir se mudou. Imagens: uma semana (os nomes não mudam entre versões).
  <FilesMatch "\\.(html|txt|xml|webmanifest)$">
    Header set Cache-Control "public, max-age=0, must-revalidate"
  </FilesMatch>
  <FilesMatch "\\.(png|ico)$">
    Header set Cache-Control "public, max-age=604800"
  </FilesMatch>
</IfModule>
"""


def main():
    ap = argparse.ArgumentParser(description="Monta o site do TranscreveAI em dist/ e no zip.")
    ap.add_argument("--site", default=SITE, help=f"endereço do site, sem a barra no fim (padrão: {SITE})")
    ap.add_argument("--imagens", action="store_true", help="desenha de novo imagens/ antes (node imagens.mjs)")
    args = ap.parse_args()
    site = args.site.rstrip("/")
    if not re.match(r"^https://[^/]+(/.*)?$", site):
        sys.exit("gerar.py: --site precisa ser um endereço https://")

    if args.imagens:
        subprocess.run(["node", str(HERE / "imagens.mjs")], check=True)
    missing = [f for f in ICON_FILES + [p["og_image"] for p in PAGES.values()] if not (IMAGES / f).exists()]
    if missing:
        sys.exit(f"gerar.py: faltam imagens em imagens/ ({', '.join(missing)}). Rode com --imagens.")

    source = SOURCE.read_text(encoding="utf-8")
    m = re.search(r'let version = "([^"]*)";', source)
    version = latest_version(m.group(1) if m else "0.0.0")

    if OUT.exists():
        shutil.rmtree(OUT)
    OUT.mkdir()
    for lang, page in PAGES.items():
        folder = OUT / page["path"]
        folder.mkdir(parents=True, exist_ok=True)
        (folder / "index.html").write_text(build_page(source, site, lang, version), encoding="utf-8")
    shutil.copy2(HERE / "cutline.png", OUT / "cutline.png")
    for f in ICON_FILES + [p["og_image"] for p in PAGES.values()]:
        shutil.copy2(IMAGES / f, OUT / f)
    day = datetime.date.today().isoformat()
    (OUT / "robots.txt").write_text(robots(site), encoding="utf-8")
    (OUT / "sitemap.xml").write_text(sitemap(site, day), encoding="utf-8")
    (OUT / "llms.txt").write_text(llms(site, version), encoding="utf-8")
    (OUT / "site.webmanifest").write_text(manifest(), encoding="utf-8")
    (OUT / ".htaccess").write_text(HTACCESS, encoding="utf-8")

    # O zip leva o conteúdo de dist/ na raiz: extraído na pasta do subdomínio, o index.html fica no lugar certo.
    if ZIP.exists():
        ZIP.unlink()
    files = sorted(p for p in OUT.rglob("*") if p.is_file() and p.name != ".DS_Store")
    with zipfile.ZipFile(ZIP, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as z:
        for p in files:
            z.write(p, p.relative_to(OUT).as_posix())

    total = sum(p.stat().st_size for p in files)
    print(f"gerar.py → {OUT.relative_to(HERE.parent)}/ ({len(files)} arquivos, {total / 1024:.0f} KB)")
    print(f"  site {site}/ · versão {version}")
    print(f"  zip  {ZIP.relative_to(HERE.parent)} ({ZIP.stat().st_size / 1024:.0f} KB)")


if __name__ == "__main__":
    main()
