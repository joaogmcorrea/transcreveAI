#!/bin/bash
# Compila o FFmpeg mínimo que vai dentro do TranscreveAI (Contents/Helpers/ffmpeg): só decodifica áudio e grava
# WAV, para os formatos que o macOS não abre sozinho (WebM, WMA, MKV, AMR…). Licença LGPL 2.1 (sem --enable-gpl
# e sem bibliotecas externas). Binário universal (Apple Silicon + Intel), macOS 26+.
#
# Uso: ./_dev/ffmpeg/compilar.sh   → files/Vendor/ffmpeg/ffmpeg (+ LICENSE-ffmpeg.txt e VERSAO)
# O código-fonte e a compilação ficam em ~/Library/Caches/TranscreveAI-ffmpeg (fora do Dropbox).
set -euo pipefail
cd "$(dirname "$0")"

VERSAO=9.0.2
CACHE="$HOME/Library/Caches/TranscreveAI-ffmpeg"
DESTINO="$(cd ../../files && pwd)/Vendor/ffmpeg"
FONTE="$CACHE/ffmpeg-$VERSAO"
mkdir -p "$CACHE" "$DESTINO"

if [ ! -d "$FONTE" ]; then
    echo "Baixando o FFmpeg $VERSAO…"
    curl -L --fail --progress-bar -o "$CACHE/ffmpeg-$VERSAO.tar.xz" "https://ffmpeg.org/releases/ffmpeg-$VERSAO.tar.xz"
    tar -xf "$CACHE/ffmpeg-$VERSAO.tar.xz" -C "$CACHE"
fi

COMUNS=(
    --disable-everything --disable-autodetect --disable-doc --disable-debug --disable-network
    --disable-ffplay --disable-ffprobe --enable-ffmpeg --disable-avdevice
    --enable-static --disable-shared --enable-swresample
    --enable-protocol=file,pipe
    --enable-demuxer=matroska,asf,amr,ogg,mov,mp3,aac,flac,wav,aiff,caf,avi
    --enable-decoder=opus,vorbis,wmav1,wmav2,wmapro,wmavoice,wmalossless,aac,aac_latm,mp3,mp3float,mp2,flac,alac,amrnb,amrwb,ac3,eac3,'pcm*','adpcm*'
    --enable-parser=aac,aac_latm,mpegaudio,opus,vorbis,flac,ac3
    --enable-muxer=wav --enable-encoder=pcm_s16le
    --enable-filter=aresample,aformat,anull,atrim
    --extra-cflags=-mmacosx-version-min=26.0 --extra-ldflags=-mmacosx-version-min=26.0
)

compilar() {
    local arch="$1"; shift
    local pasta="$CACHE/build-$VERSAO-$arch"
    if [ ! -x "$pasta/ffmpeg" ]; then
        echo "Compilando para $arch…"
        rm -rf "$pasta" && mkdir -p "$pasta" && cd "$pasta"
        "$FONTE/configure" --arch="$arch" --cc="clang -arch $arch" --target-os=darwin "${COMUNS[@]}" "$@" > configure.log
        make -j"$(sysctl -n hw.ncpu)" ffmpeg > make.log 2>&1
        cd - > /dev/null
    fi
}

compilar arm64
compilar x86_64 --enable-cross-compile --disable-x86asm

lipo -create "$CACHE/build-$VERSAO-arm64/ffmpeg" "$CACHE/build-$VERSAO-x86_64/ffmpeg" -output "$DESTINO/ffmpeg"
strip -x "$DESTINO/ffmpeg"
chmod 755 "$DESTINO/ffmpeg"
cp "$FONTE/COPYING.LGPLv2.1" "$DESTINO/LICENSE-ffmpeg.txt"
echo "$VERSAO" > "$DESTINO/VERSAO"
echo "Pronto: $DESTINO/ffmpeg ($(du -h "$DESTINO/ffmpeg" | cut -f1), $(lipo -archs "$DESTINO/ffmpeg"))"
