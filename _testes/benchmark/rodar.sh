#!/bin/bash
# Benchmark de motores de transcrição em pt-BR (TranscreveAI v0.2.0).
#
# Uso:
#   ./_testes/benchmark/rodar.sh preparar   # compila, baixa os modelos e aquece cada motor
#   ./_testes/benchmark/rodar.sh            # roda todos os motores em cada áudio de _testes/audios/
#
# Áudios: coloque em _testes/audios/ (qualquer formato). Opcional: um .txt com o mesmo nome
# do áudio contendo a transcrição correta, para medir o erro real (WER).
# Motores (variável MOTORES): apple parakeet whisper-turbo whisper-large whispercpp-turbo
#
# Modelos, build e WAVs convertidos ficam em ~/Library/Caches/TranscreveBench (fora do Dropbox).
# Resultados em _testes/resultados/ (fora do git: contêm o texto dos seus áudios).

set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TESTES="$(cd "$DIR/.." && pwd)"
AUDIOS="$TESTES/audios"
OUT="$TESTES/resultados"
CACHE="$HOME/Library/Caches/TranscreveBench"
BIN="$CACHE/build/release/bench"
GGML="$CACHE/models/ggml-large-v3-turbo.bin"
MOTORES="${MOTORES:-apple parakeet whisper-turbo whisper-large whispercpp-turbo}"
EXTS="mp3 m4a m4b aac wav aif aiff caf flac ogg oga opus webm wma mp4 mov mkv amr 3gp"

mkdir -p "$CACHE/models" "$CACHE/wav" "$OUT"

compilar() {
    echo "==> Compilando o benchmark"
    swift build -c release --package-path "$DIR" --scratch-path "$CACHE/build" 2>&1 | grep -E "error|Build complete" || true
    [ -x "$BIN" ] || { echo "Erro: binário não encontrado em $BIN"; exit 1; }
}

baixar_ggml() {
    if [ ! -f "$GGML" ]; then
        echo "==> Baixando whisper.cpp large-v3-turbo (1,6 GB)"
        curl -L --fail --progress-bar -o "$GGML.part" \
            "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-turbo.bin"
        mv "$GGML.part" "$GGML"
    fi
}

# Converte qualquer áudio para WAV 16 kHz mono (mesma entrada para todos os motores; fora da medição).
para_wav() {
    ffmpeg -nostdin -loglevel error -y -i "$1" -ac 1 -ar 16000 -c:a pcm_s16le "$2"
}

# Roda um motor em um WAV e grava <motor>.txt, <motor>.json e <motor>.time em $3.
rodar_motor() {
    local motor="$1" wav="$2" saida="$3"
    mkdir -p "$saida"
    if [ "$motor" = "whispercpp-turbo" ]; then
        # Greedy (beam 1), igual ao WhisperKit, para comparar os dois runtimes de forma justa.
        local t0 t1
        t0=$(python3 -I -c 'import time; print(time.time())')
        /usr/bin/time -l whisper-cli -m "$GGML" -f "$wav" -l pt -t 8 -bs 1 -bo 1 -nt \
            -otxt -of "$saida/$motor" > /dev/null 2> "$saida/$motor.time"
        t1=$(python3 -I -c 'import time; print(time.time())')
        python3 -I - "$saida/$motor.time" "$wav" "$t0" "$t1" > "$saida/$motor.json" <<'PY'
import json, re, sys, wave
log = open(sys.argv[1], encoding="utf-8", errors="ignore").read()
with wave.open(sys.argv[2]) as w:
    dur = w.getnframes() / w.getframerate()
def ms(name):
    m = re.search(name + r" time =\s*([\d.]+) ms", log)
    return float(m.group(1)) / 1000 if m else None
load = ms("load") or 0.0
total = float(sys.argv[4]) - float(sys.argv[3])
trans = max(total - load, 0.001)
print(json.dumps({"engine": "whispercpp-turbo", "detail": "whisper.cpp ggml-large-v3-turbo (Metal, greedy)",
                  "audioSeconds": dur, "loadSeconds": load, "transcribeSeconds": trans,
                  "realtimeFactor": dur / trans}, indent=2, sort_keys=True))
PY
        printf "whispercpp-turbo  transcrição %.1fs\n" "$(python3 -I -c "import json;print(json.load(open('$saida/$motor.json'))['transcribeSeconds'])")"
    else
        /usr/bin/time -l "$BIN" "$motor" "$wav" "$saida" 2> "$saida/$motor.time" || {
            echo "  falhou: $motor (veja $saida/$motor.time)"; return 0; }
    fi
}

preparar() {
    compilar
    baixar_ggml
    echo "==> Aquecendo os motores (baixa e compila os modelos na primeira vez; pode levar vários minutos)"
    local aiff="$CACHE/aquecimento.aiff" wav="$CACHE/aquecimento.wav"
    say -v Luciana -o "$aiff" "Olá. Este é um teste curto de aquecimento do benchmark de transcrição, \
para baixar e preparar cada modelo antes da medição. Um, dois, três, gravando."
    para_wav "$aiff" "$wav"
    for motor in $MOTORES; do
        echo "--> $motor"
        rodar_motor "$motor" "$wav" "$CACHE/aquecimento"
    done
    echo "==> Pronto. Coloque os áudios em _testes/audios/ e rode: ./_testes/benchmark/rodar.sh"
}

benchmark() {
    compilar
    baixar_ggml
    shopt -s nullglob nocaseglob
    local arquivos=()
    for ext in $EXTS; do arquivos+=("$AUDIOS"/*."$ext"); done
    shopt -u nocaseglob
    if [ ${#arquivos[@]} -eq 0 ]; then
        echo "Nenhum áudio em $AUDIOS. Coloque seus arquivos lá e rode de novo."
        exit 1
    fi
    for audio in "${arquivos[@]}"; do
        local nome base wav saida
        base="$(basename "$audio")"
        nome="${base%.*}"
        wav="$CACHE/wav/$nome.wav"
        saida="$OUT/$nome"
        echo "==> $base"
        para_wav "$audio" "$wav"
        mkdir -p "$saida"
        [ -f "$AUDIOS/$nome.txt" ] && cp "$AUDIOS/$nome.txt" "$saida/referencia.txt"
        for motor in $MOTORES; do
            rodar_motor "$motor" "$wav" "$saida"
        done
    done
    echo "==> Gerando relatório"
    python3 -I "$DIR/relatorio.py" "$OUT" "$BIN"
}

case "${1:-}" in
    preparar) preparar ;;
    "") benchmark ;;
    *) echo "Uso: $0 [preparar]"; exit 1 ;;
esac
