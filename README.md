# TranscreveAI

Fast, minimal, on-device audio transcription in the macOS menu bar.

Drop an audio file on the icon and the text shows up in seconds. Your audio never leaves your Mac.

**[Download the latest version (DMG)](https://github.com/joaogmcorrea/transcreveAI/releases/latest/download/TranscreveAI.dmg)** · [All releases](https://github.com/joaogmcorrea/transcreveAI/releases) · Requires macOS 26 or later

> The app's interface is in Brazilian Portuguese. It transcribes Portuguese, English and Spanish, and Parakeet detects the language on its own.

---

## Why

Transcription apps tend to be slow and crowded with options. TranscreveAI does one thing: it takes an audio file and gives you the text back as fast as possible. It lives in the menu bar, with no window and no Dock icon.

## How to use

There are four ways to hand it an audio file:

- **Click the menu bar icon** and drop the file on the panel, or click the drop area to pick a file.
- **Drop it right on the menu bar icon.**
- **Start dragging** an audio file in Finder, on the Desktop or from a Dock stack. The panel opens by itself and closes again if you drop the file somewhere else.
- **Open With › TranscreveAI** in Finder.

You can close the panel while it works. The icon shows the progress, plays a sound when it's done, and keeps a red dot until you look at the result. The text is already on the clipboard ("Copiar ao terminar", on by default).

Right-click the icon for Check for Updates, Settings, Open at Login and Quit. Press Esc or click anywhere outside to close the panel.

## Features

- **On-device transcription:** nothing goes to the cloud.
- **Text in paragraphs**, each with its timestamp. The text is selectable, and there's a "Copy all" button.
- **History** with search: reopen, copy or delete past transcriptions (a trash button shows on hover). By default, history is erased when you shut down or restart the Mac. You can change that in Settings › History.
- **Model and language** pickers at the bottom of the panel and in Settings. Languages: Auto, Portuguese, English and Spanish.
- **Automatic updates** through [Sparkle](https://sparkle-project.org), verified with EdDSA signatures.

## Engines

| Model | Best for | Download |
|---|---|---|
| **Automático** (default) | Always picks the fastest installed engine. Today that's Parakeet v3. | — |
| **Parakeet v3** (NVIDIA, through [FluidAudio](https://github.com/FluidInference/FluidAudio)) | The fastest. Detects the language by itself. | 470 MB, once |
| **Apple Speech** | Built into macOS. Shows a live preview. | None |
| **Whisper Large v3 Turbo** | Higher-quality alternative | Coming soon |

On the first transcription, Apple Speech handles the file while Parakeet downloads and gets compiled for the Neural Engine (about 14 s, only once). From then on, Automático uses Parakeet.

### Speed

Benchmark with 3 Portuguese voice notes on a Mac with an M4 Pro. The numbers are seconds of audio transcribed per second of work: 145× means one minute of audio in under half a second.

| Engine | Speed |
|---|---|
| Parakeet v3 | 145× |
| Apple Speech | 73× |
| whisper.cpp (Turbo) | 25× |
| Whisper Large v3 Turbo | 22× |
| Whisper Large v3 | 3× |

Inside the app, with the model already loaded, Parakeet transcribed 3 minutes of audio in 0.77 s (224×). Long recordings (30 minutes or more) haven't been measured yet; that comes before v1.0. whisper.cpp and Whisper Large v3 were left out of the app.

## Formats

- **Opened by macOS itself:** MP3, M4A/AAC, MP4/MOV, WAV, AIFF, FLAC, OGG and Opus (WhatsApp voice notes).
- **Through the bundled FFmpeg** (9.0.2, LGPL): WebM, WMA, MKV and AMR.

## Privacy

Audio and text stay on your Mac. The app only goes online to:

- download the Parakeet model once, from Hugging Face;
- download Apple Speech's language pack, if macOS doesn't have it yet;
- check for updates on GitHub.

History is stored in `~/Library/Application Support/TranscreveAI/Historico` and the model in `~/Library/Application Support/TranscreveAI/Modelos`.

## Install

1. Download [`TranscreveAI.dmg`](https://github.com/joaogmcorrea/transcreveAI/releases/latest/download/TranscreveAI.dmg) and drag TranscreveAI to Applications.
2. The first time you open it, macOS says it can't verify the app, because it isn't signed with a paid Apple developer certificate yet. Go to **System Settings › Privacy & Security** and click **Open Anyway**.
3. The icon shows up in the menu bar. New versions arrive on their own.

## Build from source

Tested with Xcode 27.2 on macOS 26 or later.

```bash
git clone https://github.com/joaogmcorrea/transcreveAI.git
cd transcreveAI
open files/TranscreveAI.xcodeproj
```

- The FFmpeg binary is already in the repository (`files/Vendor/ffmpeg/`). To rebuild it, run `_dev/ffmpeg/compilar.sh`.
- To try the engines from the terminal, without the app:

  ```bash
  swift run --package-path files/Pacotes/TranscreveMotores transcrever path/to/audio.m4a parakeet
  ```

  The engine can be `parakeet` or `apple`, optionally followed by a language code.
- Releases are made with `_dev/distribuir.sh`. It needs the project's EdDSA key, which isn't in the repository.

## Project layout

| Folder | Contents |
|---|---|
| `files/` | The app: Xcode project, SwiftUI/AppKit code, FFmpeg and licenses |
| `files/Pacotes/TranscreveMotores/` | The transcription engines (a Swift package you can run from the terminal) |
| `_dev/` | Release and FFmpeg build scripts, plus the notes for each version |
| `_docs/` | Context, decisions, changelog and roadmap (in Portuguese) |
| `_testes/benchmark/` | The engine benchmark |

## What's next

- **v0.5:** click a passage to copy it, and export to `.txt` / `.md`.
- **v0.6:** Whisper Large v3 Turbo.
- **v0.7:** a notification when a transcription finishes.
- **v0.8:** an action ring on the ⌥ Space shortcut.
- **v1.0:** polish and tests with long recordings.

The full roadmap is in [`_docs/ROADMAP.md`](_docs/ROADMAP.md), and the changes in each version are in [`_docs/CHANGELOG.md`](_docs/CHANGELOG.md) (both in Portuguese).

## License

TranscreveAI's code is released under the [MIT License](LICENSE).

Third-party components keep their own licenses: Sparkle (MIT), FluidAudio (Apache 2.0), FFmpeg (LGPL 2.1) and the Parakeet TDT 0.6B v3 model (CC BY 4.0). Details in [`files/LICENCAS.md`](files/LICENCAS.md).

---

Made by [João Corrêa](https://github.com/joaogmcorrea).
