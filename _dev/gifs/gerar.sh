#!/bin/bash
# Gera os GIFs do README (estilo vídeo-tutorial flat) a partir de _dev/gifs/animacoes.swift.
# Uso: _dev/gifs/gerar.sh [soltar|dock|painel-fechado ...]   (sem argumento: todos)
# Precisa do ffmpeg no PATH (Homebrew). Quadros temporários em ~/Library/Caches/TranscreveAI-gifs.
set -euo pipefail

PASTA="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CACHE="$HOME/Library/Caches/TranscreveAI-gifs"
LARGURA="${LARGURA:-1200}"   # px do GIF; o README mostra com width=800 (nítido em tela Retina)
mkdir -p "$CACHE"

swiftc -O -swift-version 5 "$PASTA/animacoes.swift" -o "$CACHE/animacoes" 2>&1 | grep -E "error" || true
"$CACHE/animacoes" "$CACHE/quadros" "$@"

for quadros in "$CACHE"/quadros/*/; do
    nome="$(basename "$quadros")"
    [ -f "$quadros/q0000.png" ] || continue
    ffmpeg -loglevel error -y -framerate 25 -i "$quadros/q%04d.png" \
        -vf "scale=$LARGURA:-1:flags=lanczos,split[a][b];[a]palettegen=max_colors=128:stats_mode=full[p];[b][p]paletteuse=dither=bayer:bayer_scale=5:diff_mode=rectangle" \
        -loop 0 "$PASTA/$nome.gif"
    echo "$nome.gif: $(du -h "$PASTA/$nome.gif" | cut -f1)"
done
