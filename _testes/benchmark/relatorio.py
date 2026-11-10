"""Gera _testes/resultados/relatorio.md a partir das saídas do rodar.sh.

Uso: python3 -I relatorio.py <pasta-resultados> <binario-bench>

Qualidade: se existir referencia.txt (transcrição correta feita por você), calcula o WER real.
Sem referência, compara cada motor com o Whisper Large v3 ("divergência"): mostra o quanto os
textos diferem, não quem está certo.
"""

import json
import platform
import re
import subprocess
import sys
from datetime import datetime
from pathlib import Path

MOTORES = {
    "apple": "Apple Speech",
    "parakeet": "Parakeet v3",
    "whisper-turbo": "Whisper Large v3 Turbo (WhisperKit)",
    "whisper-large": "Whisper Large v3 (WhisperKit)",
    "whispercpp-turbo": "whisper.cpp Turbo (base MacWhisper)",
}
TOLERANCIA_WER = 0.03  # o "Automático" aceita até 3 pontos de erro a mais que o melhor


def palavras(texto):
    return re.findall(r"\w+", texto.lower())


def alertas(texto, mediana_palavras):
    """Sinais de falha comuns: texto bem mais curto que os outros motores ou frase repetida (alucinação)."""
    avisos = []
    p = palavras(texto)
    if mediana_palavras and len(p) < 0.75 * mediana_palavras:
        avisos.append(f"incompleto ({len(p)} de ~{mediana_palavras:.0f} palavras)")
    vistos = set()
    for i in range(len(p) - 5):
        trecho = tuple(p[i:i + 6])
        if trecho in vistos:
            avisos.append("repetição")
            break
        vistos.add(trecho)
    return avisos


def wer(binario, ref, hyp):
    out = subprocess.run([binario, "wer", str(ref), str(hyp)], capture_output=True, text=True, check=True)
    return json.loads(out.stdout)["wer"]


def memoria_mb(arquivo_time):
    if not arquivo_time.exists():
        return None
    m = re.search(r"(\d+)\s+maximum resident set size", arquivo_time.read_text(errors="ignore"))
    return int(m.group(1)) / 1e6 if m else None


def fmt_tempo(s):
    if s is None:
        return "—"
    return f"{s:.1f} s" if s < 90 else f"{int(s // 60)} min {int(s % 60):02d} s"


def fmt_pct(x):
    return "—" if x is None else f"{x * 100:.1f}%"


def maquina():
    try:
        chip = subprocess.run(["sysctl", "-n", "machdep.cpu.brand_string"], capture_output=True, text=True).stdout.strip()
        ram = int(subprocess.run(["sysctl", "-n", "hw.memsize"], capture_output=True, text=True).stdout) / 2**30
        return f"{chip}, {ram:.0f} GB, macOS {platform.mac_ver()[0]}"
    except Exception:
        return platform.platform()


def main():
    pasta, binario = Path(sys.argv[1]), sys.argv[2]
    audios = sorted(p for p in pasta.iterdir() if p.is_dir())
    linhas, total = [], {}

    for audio in audios:
        ref = audio / "referencia.txt"
        tem_ref = ref.exists()
        if not tem_ref and (audio / "whisper-large.txt").exists():
            ref = audio / "whisper-large.txt"
        dados = []
        for motor in MOTORES:
            j = audio / f"{motor}.json"
            t = audio / f"{motor}.txt"
            if not j.exists() or not t.exists():
                continue
            m = json.loads(j.read_text())
            erro = None
            if ref.exists() and not (not tem_ref and motor == "whisper-large"):
                erro = wer(binario, ref, t)
            m.update(motor=motor, erro=erro, mem=memoria_mb(audio / f"{motor}.time"), amostra=t.read_text()[:280])
            dados.append(m)
            acc = total.setdefault(motor, {"audio": 0.0, "trans": 0.0, "carga": [], "mem": [], "erros": []})
            acc["audio"] += m["audioSeconds"]
            acc["trans"] += m["transcribeSeconds"]
            acc["carga"].append(m["loadSeconds"])
            if m["mem"]:
                acc["mem"].append(m["mem"])
            if erro is not None:
                acc["erros"].append((erro, m["audioSeconds"]))
        if not dados:
            continue
        contagens = sorted(len(palavras((audio / f"{m['motor']}.txt").read_text())) for m in dados)
        mediana = contagens[len(contagens) // 2]
        for m in dados:
            m["alertas"] = alertas((audio / f"{m['motor']}.txt").read_text(), mediana)
            total[m["motor"]].setdefault("alertas", []).extend(f"{audio.name}: {a}" for a in m["alertas"])
        dur = dados[0]["audioSeconds"]
        rotulo = "WER (vs. sua transcrição)" if tem_ref else "Divergência vs. Whisper Large v3"
        linhas += [f"### {audio.name} ({fmt_tempo(dur)})", "",
                   f"| Motor | Transcrição | × tempo real | Carga do modelo | Memória máx. | {rotulo} | Alertas |",
                   "|---|---|---|---|---|---|---|"]
        for m in sorted(dados, key=lambda d: d["transcribeSeconds"]):
            erro = "referência" if (not tem_ref and m["motor"] == "whisper-large") else fmt_pct(m["erro"])
            mem = f"{m['mem']:.0f} MB" if m["mem"] else "—"
            linhas.append(f"| {MOTORES[m['motor']]} | {fmt_tempo(m['transcribeSeconds'])} | {m['realtimeFactor']:.0f}× | "
                          f"{fmt_tempo(m['loadSeconds'])} | {mem} | {erro} | {', '.join(m['alertas']) or '—'} |")
        linhas += ["", "<details><summary>Início do texto de cada motor</summary>", ""]
        for m in dados:
            linhas += [f"**{MOTORES[m['motor']]}:** {m['amostra'].strip()}…", ""]
        linhas += ["</details>", ""]

    tem_ref_real = any((a / "referencia.txt").exists() for a in audios)
    rotulo_erro = "Erro médio ponderado (WER)" if tem_ref_real else "Divergência vs. Whisper Large v3"
    resumo = [f"| Motor | Velocidade (× tempo real) | Tempo total | Carga média | Memória máx. | {rotulo_erro} | Alertas |",
              "|---|---|---|---|---|---|---|"]
    ranking = []
    for motor, a in total.items():
        rtf = a["audio"] / max(a["trans"], 0.001)
        erro = (sum(e * d for e, d in a["erros"]) / sum(d for _, d in a["erros"])) if a["erros"] else None
        ranking.append((motor, rtf, erro, a.get("alertas", [])))
        mem = f"{max(a['mem']):.0f} MB" if a["mem"] else "—"
        resumo.append(f"| {MOTORES[motor]} | {rtf:.0f}× | {fmt_tempo(a['trans'])} | "
                      f"{fmt_tempo(sum(a['carga']) / len(a['carga']))} | {mem} | {fmt_pct(erro)} | "
                      f"{len(a.get('alertas', []))} |")
    ranking.sort(key=lambda r: -r[1])

    sem_alerta = [r for r in ranking if not r[3]] or ranking
    if tem_ref_real and any(r[2] is not None for r in sem_alerta):
        melhor = min(r[2] for r in sem_alerta if r[2] is not None)
        aceitaveis = [r for r in sem_alerta if r[2] is None or r[2] <= melhor + TOLERANCIA_WER]
        escolhido = aceitaveis[0]
        recomendacao = (f"**{MOTORES[escolhido[0]]}**: o mais rápido ({escolhido[1]:.0f}× tempo real) entre os motores "
                        f"sem alertas e com erro até {TOLERANCIA_WER * 100:.0f} pontos acima do melhor ({fmt_pct(melhor)}).")
    else:
        escolhido = sem_alerta[0]
        recomendacao = (f"**{MOTORES[escolhido[0]]}**: o mais rápido ({escolhido[1]:.0f}× tempo real) sem alertas. "
                        "Sem `referencia.txt` a qualidade não foi medida de forma objetiva: confira os textos abaixo.")

    relatorio = [f"# Benchmark de transcrição — {datetime.now():%d/%m/%Y %H:%M}", "",
                 f"Máquina: {maquina()}. Entrada: WAV 16 kHz mono (conversão fora da medição).", "",
                 "## Resumo", "", *resumo, "", f"Sugestão para o padrão \"Automático\": {recomendacao}", "",
                 "Notas: \"Transcrição\" exclui a carga do modelo (no app ele fica carregado). Sem `referencia.txt`, "
                 "a coluna de erro mede divergência em relação ao Whisper Large v3, não acerto absoluto.", "",
                 "## Por áudio", "", *linhas]
    destino = pasta / "relatorio.md"
    destino.write_text("\n".join(relatorio), encoding="utf-8")
    print("\n".join(relatorio[:len(resumo) + 8]))
    print(f"\nRelatório completo: {destino}")


if __name__ == "__main__":
    main()
