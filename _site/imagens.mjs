#!/usr/bin/env node
// Desenha as imagens do site em _site/imagens/ com o Google Chrome sem janela (headless), pelo protocolo do DevTools.
//
//   node _site/imagens.mjs        (ou: python3 _site/gerar.py --imagens)
//
// Ícones: a marca da página (onda branca no quadrado violeta, a mesma do favicon do index.html), em favicon.ico
// (16, 32 e 48), favicon-96.png, apple-touch-icon.png (180, sem cantos: o iOS arredonda), icon-192.png e icon-512.png.
// Compartilhamento (og-image.png, og-image-pt.png, og-image-es.png; 1200×630): a própria página, em cada idioma, com o
// painel aberto e a transcrição de exemplo pronta. A cena sai de cliques de verdade (dois cliques no áudio da mesa),
// sem nenhum gancho de teste na página.
//
// Precisa só do Node 24+ (WebSocket embutido) e do Chrome. CHROME=<caminho> troca o navegador.
import { spawn } from "node:child_process";
import { createServer } from "node:http";
import { mkdtemp, mkdir, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { dirname, extname, join, normalize } from "node:path";
import { fileURLToPath } from "node:url";

const HERE = dirname(fileURLToPath(import.meta.url));
const OUT = join(HERE, "imagens");
const CHROME = process.env.CHROME || "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome";

// A marca: o favicon do index.html. Sem cantos (rx = 0) para o ícone do iOS, que aplica a própria máscara.
const mark = (rx) => `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64"><defs><linearGradient id="g" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#8057fb"/><stop offset="1" stop-color="#4a0ff9"/></linearGradient></defs><rect width="64" height="64" rx="${rx}" fill="url(#g)"/><path d="M14 28v8M20.5 22v20M27 15v34M33.5 23v18M40 18v28M46.5 25v14M53 29v6" stroke="#fff" stroke-width="4.5" stroke-linecap="round" fill="none"/></svg>`;
const ICONS = [
  { file: "favicon-96.png", size: 96, rx: 15 },
  { file: "apple-touch-icon.png", size: 180, rx: 0 },
  { file: "icon-192.png", size: 192, rx: 15 },
  { file: "icon-512.png", size: 512, rx: 15 },
];
const ICO_SIZES = [16, 32, 48];
// 960×504 a 1,25× dá 1200×630: a página fica no layout de computador (acima de 760 px) e o painel sai maior.
const OG = { width: 960, height: 504, scale: 1.25 };
const LANGS = { en: "og-image.png", pt: "og-image-pt.png", es: "og-image-es.png" };

const sleep = (ms) => new Promise((ok) => setTimeout(ok, ms));

// Servidor local só para a pasta _site/ (a página e a imagem do Cutline).
const TYPES = { ".html": "text/html; charset=utf-8", ".png": "image/png", ".js": "text/javascript", ".css": "text/css" };
function serve() {
  const server = createServer(async (req, res) => {
    const path = normalize(decodeURIComponent(new URL(req.url, "http://x").pathname)).replace(/^(\.\.[/\\])+/, "");
    const file = join(HERE, path.endsWith("/") ? path + "index.html" : path);
    try {
      const body = await readFile(file);
      res.writeHead(200, { "Content-Type": TYPES[extname(file)] || "application/octet-stream" });
      res.end(body);
    } catch {
      res.writeHead(404); res.end();
    }
  });
  return new Promise((ok) => server.listen(0, "127.0.0.1", () => ok(server)));
}

// Cliente mínimo do protocolo do DevTools.
async function connect(url) {
  const ws = new WebSocket(url);
  await new Promise((ok, no) => { ws.onopen = ok; ws.onerror = () => no(new Error("imagens.mjs: não conectou ao Chrome")); });
  let seq = 0;
  const waiting = new Map(), events = [];
  ws.onmessage = (m) => {
    const d = JSON.parse(m.data);
    if (d.id && waiting.has(d.id)) {
      const { ok, no } = waiting.get(d.id); waiting.delete(d.id);
      d.error ? no(new Error(`${d.error.message} (${d.error.code})`)) : ok(d.result);
    } else if (d.method) {
      events.forEach((f) => f(d));
    }
  };
  const send = (method, params = {}, sessionId) => new Promise((ok, no) => {
    const id = ++seq; waiting.set(id, { ok, no });
    ws.send(JSON.stringify({ id, method, params, sessionId }));
  });
  const once = (method, sessionId, ms = 15000) => new Promise((ok, no) => {
    const t = setTimeout(() => no(new Error(`imagens.mjs: ${method} não chegou`)), ms);
    const f = (d) => { if (d.method === method && d.sessionId === sessionId) { clearTimeout(t); events.splice(events.indexOf(f), 1); ok(d.params); } };
    events.push(f);
  });
  return { send, once, close: () => ws.close() };
}

async function launch() {
  const profile = await mkdtemp(join(tmpdir(), "transcreveai-chrome-"));
  const proc = spawn(CHROME, [
    "--headless=new", "--remote-debugging-port=0", `--user-data-dir=${profile}`, "--no-first-run",
    "--no-default-browser-check", "--hide-scrollbars", "--mute-audio", "--force-color-profile=srgb", "about:blank",
  ], { stdio: ["ignore", "ignore", "pipe"] });
  const url = await new Promise((ok, no) => {
    let err = "";
    const t = setTimeout(() => no(new Error("imagens.mjs: o Chrome não abriu\n" + err)), 20000);
    proc.stderr.on("data", (b) => {
      err += b;
      const m = err.match(/DevTools listening on (ws:\/\/\S+)/);
      if (m) { clearTimeout(t); ok(m[1]); }
    });
    proc.on("error", (e) => { clearTimeout(t); no(e); });
  });
  return { url, quit: async () => { proc.kill(); await sleep(300); await rm(profile, { recursive: true, force: true }); } };
}

async function newPage(cdp, width, height, scale, transparent) {
  const { targetId } = await cdp.send("Target.createTarget", { url: "about:blank" });
  const { sessionId } = await cdp.send("Target.attachToTarget", { targetId, flatten: true });
  const page = (m, p) => cdp.send(m, p, sessionId);
  await page("Page.enable");
  await page("Runtime.enable");
  await page("Emulation.setDeviceMetricsOverride", { width, height, deviceScaleFactor: scale, mobile: false });
  if (transparent) await page("Emulation.setDefaultBackgroundColorOverride", { color: { r: 0, g: 0, b: 0, a: 0 } });
  const go = async (url) => { const loaded = cdp.once("Page.loadEventFired", sessionId); await page("Page.navigate", { url }); await loaded; };
  const shot = async () => Buffer.from((await page("Page.captureScreenshot", { format: "png", captureBeyondViewport: false })).data, "base64");
  const js = async (expression) => (await page("Runtime.evaluate", { expression, returnByValue: true, awaitPromise: true })).result.value;
  const close = () => cdp.send("Target.closeTarget", { targetId });
  return { page, go, shot, js, close };
}

// .ico com as imagens PNG dentro (aceito desde o Windows Vista e por todos os navegadores).
function ico(pngs) {
  const head = Buffer.alloc(6 + 16 * pngs.length);
  head.writeUInt16LE(0, 0); head.writeUInt16LE(1, 2); head.writeUInt16LE(pngs.length, 4);
  let offset = head.length;
  pngs.forEach(({ size, png }, i) => {
    const e = 6 + 16 * i;
    head.writeUInt8(size >= 256 ? 0 : size, e); head.writeUInt8(size >= 256 ? 0 : size, e + 1);
    head.writeUInt8(0, e + 2); head.writeUInt8(0, e + 3);
    head.writeUInt16LE(1, e + 4); head.writeUInt16LE(32, e + 6);
    head.writeUInt32LE(png.length, e + 8); head.writeUInt32LE(offset, e + 12);
    offset += png.length;
  });
  return Buffer.concat([head, ...pngs.map((p) => p.png)]);
}

async function icons(cdp) {
  const draw = async (size, rx) => {
    const p = await newPage(cdp, size, size, 1, true);
    const html = `<!doctype html><style>html,body{margin:0;background:transparent}svg{display:block;width:100vw;height:100vh}</style>${mark(rx)}`;
    await p.go("data:text/html;charset=utf-8," + encodeURIComponent(html));
    const png = await p.shot();
    await p.close();
    return png;
  };
  for (const { file, size, rx } of ICONS) {
    await writeFile(join(OUT, file), await draw(size, rx));
    console.log("  " + file);
  }
  const pngs = [];
  for (const size of ICO_SIZES) pngs.push({ size, png: await draw(size, 15) });
  await writeFile(join(OUT, "favicon.ico"), ico(pngs));
  console.log("  favicon.ico");
}

async function shareImages(cdp, base) {
  for (const [lang, file] of Object.entries(LANGS)) {
    const p = await newPage(cdp, OG.width, OG.height, OG.scale, false);
    // A página copia o texto ao terminar ("Copiado"): libera a área de transferência para o aviso aparecer.
    await cdp.send("Browser.grantPermissions", { origin: base, permissions: ["clipboardReadWrite", "clipboardSanitizedWrite"] }).catch(() => {});
    await p.go(`${base}/index.html?lang=${lang}`);
    await sleep(1500);
    // Dois cliques de verdade no áudio da reunião, na mesa: "Abrir com › TranscreveAI".
    const r = await p.js(`(() => { const b = document.querySelector('.desk .item[data-k="meeting"], .item[data-k="meeting"]'); if (!b) return null; const r = b.getBoundingClientRect(); return { x: r.left + r.width / 2, y: r.top + r.height / 2 }; })()`);
    if (!r) throw new Error("imagens.mjs: não achei o áudio da mesa (.item[data-k=meeting])");
    for (const clickCount of [1, 2]) {
      await p.page("Input.dispatchMouseEvent", { type: "mousePressed", x: r.x, y: r.y, button: "left", clickCount });
      await p.page("Input.dispatchMouseEvent", { type: "mouseReleased", x: r.x, y: r.y, button: "left", clickCount });
    }
    await p.page("Input.dispatchMouseEvent", { type: "mouseMoved", x: OG.width * 0.3, y: OG.height * 0.45 });
    // Espera a transcrição de exemplo terminar (o tempo que o app levou de verdade) e os parágrafos aparecerem.
    const t0 = Date.now();
    while (!(await p.js(`!!document.querySelector("#p-body .tbox")`))) {
      if (Date.now() - t0 > 15000) throw new Error("imagens.mjs: a transcrição de exemplo não terminou");
      await sleep(100);
    }
    await sleep(800);
    await writeFile(join(OUT, file), await p.shot());
    await p.close();
    console.log("  " + file);
  }
}

const server = await serve();
const chrome = await launch();
try {
  await mkdir(OUT, { recursive: true });
  const cdp = await connect(chrome.url);
  console.log("imagens.mjs → " + OUT);
  await icons(cdp);
  await shareImages(cdp, `http://127.0.0.1:${server.address().port}`);
  cdp.close();
} finally {
  await chrome.quit();
  server.close();
}
