# Licenças de terceiros

O TranscreveAI inclui ou usa:

| Componente | Licença | Arquivo |
|---|---|---|
| [Sparkle](https://github.com/sparkle-project/Sparkle) 2: atualizações | MIT (e outras, no arquivo) | `LICENSE-sparkle.txt` |
| [FluidAudio](https://github.com/FluidInference/FluidAudio): motor do Parakeet | Apache 2.0 | `LICENSE-fluidaudio.txt` |
| fastcluster (incluído no FluidAudio) | BSD 2-Clause | `LICENSE-fastcluster.txt` |
| [FFmpeg](https://ffmpeg.org) 9.0.2: conversão de WebM, WMA, MKV e AMR | LGPL 2.1 | `Vendor/ffmpeg/LICENSE-ffmpeg.txt` |
| Modelo Parakeet TDT 0.6B v3 (NVIDIA), baixado pelo app na primeira vez | CC BY 4.0 | — |

O FFmpeg é um programa separado dentro do app (`Contents/Helpers/ffmpeg`), compilado sem componentes GPL. O código-fonte é o da versão oficial indicada em `Vendor/ffmpeg/VERSAO`, e a receita da compilação está no repositório (`_dev/ffmpeg/compilar.sh`).
