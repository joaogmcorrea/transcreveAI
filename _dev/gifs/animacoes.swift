// Animações do README em estilo de vídeo-tutorial flat. Cada quadro é desenhado do zero com AppKit
// (fonte do sistema e SF Symbols); não é gravação de tela, então nada pessoal aparece.
// O painel imita a interface real (textos e medidas de PainelView.swift) numa cena simplificada.
//
// Uso: _dev/gifs/gerar.sh  (compila este arquivo, desenha os quadros e monta os GIFs com o FFmpeg)
import AppKit

// MARK: - Cena

let largura: CGFloat = 800
let altura: CGFloat = 500
let escala: CGFloat = 2
let quadrosPorSegundo = 25.0

extension NSColor {
    convenience init(_ hex: UInt32, _ alfa: CGFloat = 1) {
        self.init(
            srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: alfa)
    }
    func a(_ alfa: CGFloat) -> NSColor { withAlphaComponent(alphaComponent * alfa) }
}

enum Cor {
    static let fundo = NSColor(0xDCE5F4)
    static let fundo2 = NSColor(0xD0DCF0)
    static let fundo3 = NSColor(0xE7EDF8)
    static let azul = NSColor(0x007AFF)
    static let tinta = NSColor(0x1D1D1F)
    static let cinza = NSColor(0x6E6E73)
    static let branco = NSColor.white
    static let vermelho = NSColor(0xFF3B30)
    static let preto = NSColor.black
}

func misturar(_ a: NSColor, _ b: NSColor, _ x: CGFloat) -> NSColor {
    let p = a.usingColorSpace(.sRGB)!, q = b.usingColorSpace(.sRGB)!
    return NSColor(
        srgbRed: mix(p.redComponent, q.redComponent, x), green: mix(p.greenComponent, q.greenComponent, x),
        blue: mix(p.blueComponent, q.blueComponent, x), alpha: mix(p.alphaComponent, q.alphaComponent, x))
}

// MARK: - Tempo e movimento

func limitar(_ x: CGFloat) -> CGFloat { min(1, max(0, x)) }
func fase(_ t: Double, _ a: Double, _ b: Double) -> CGFloat { limitar(CGFloat((t - a) / (b - a))) }
func suave(_ x: CGFloat) -> CGFloat { x < 0.5 ? 4 * x * x * x : 1 - pow(-2 * x + 2, 3) / 2 }
func saida(_ x: CGFloat) -> CGFloat { 1 - pow(1 - x, 3) }
func mola(_ x: CGFloat) -> CGFloat {
    let c1: CGFloat = 1.70158, c3 = c1 + 1
    return 1 + c3 * pow(x - 1, 3) + c1 * pow(x - 1, 2)
}
func mix(_ a: CGFloat, _ b: CGFloat, _ x: CGFloat) -> CGFloat { a + (b - a) * x }
func mix(_ a: CGPoint, _ b: CGPoint, _ x: CGFloat) -> CGPoint { CGPoint(x: mix(a.x, b.x, x), y: mix(a.y, b.y, x)) }

/// Um trecho do caminho do cursor, de `a` até `b`, curvado por `c` (opcional).
struct Trecho {
    let t0: Double, t1: Double
    let a: CGPoint, b: CGPoint
    var c: CGPoint? = nil
}

func ponto(_ trechos: [Trecho], inicio: CGPoint, _ t: Double) -> CGPoint {
    var atual = inicio
    for trecho in trechos {
        if t < trecho.t0 { return atual }
        if t <= trecho.t1 {
            let x = suave(fase(t, trecho.t0, trecho.t1))
            guard let c = trecho.c else { return mix(trecho.a, trecho.b, x) }
            let u = 1 - x
            return CGPoint(
                x: u * u * trecho.a.x + 2 * u * x * c.x + x * x * trecho.b.x,
                y: u * u * trecho.a.y + 2 * u * x * c.y + x * x * trecho.b.y)
        }
        atual = trecho.b
    }
    return atual
}

// MARK: - Desenho básico (contexto invertido: y cresce para baixo)

nonisolated(unsafe) var cg: CGContext!

func caixa(_ r: CGRect, raio: CGFloat, _ cor: NSColor) {
    cor.setFill()
    NSBezierPath(roundedRect: r, xRadius: raio, yRadius: raio).fill()
}

func borda(_ r: CGRect, raio: CGFloat, _ cor: NSColor, espessura: CGFloat = 1, tracejado: [CGFloat]? = nil) {
    let dentro = r.insetBy(dx: espessura / 2, dy: espessura / 2)
    let caminho = NSBezierPath(
        roundedRect: dentro, xRadius: max(0, raio - espessura / 2), yRadius: max(0, raio - espessura / 2))
    caminho.lineWidth = espessura
    if let tracejado { caminho.setLineDash(tracejado, count: tracejado.count, phase: 0) }
    cor.setStroke()
    caminho.stroke()
}

func circulo(_ c: CGPoint, _ r: CGFloat, _ cor: NSColor) {
    cor.setFill()
    NSBezierPath(ovalIn: CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r)).fill()
}

func comSombra(raio: CGFloat, y: CGFloat, alfa: CGFloat, _ bloco: () -> Void) {
    cg.saveGState()
    cg.setShadow(
        offset: CGSize(width: 0, height: -y * escala), blur: raio * escala,
        color: NSColor.black.withAlphaComponent(alfa).cgColor)
    bloco()
    cg.restoreGState()
}

/// Desenha o bloco com transparência de grupo (sem somar as camadas internas).
func camada(_ alfa: CGFloat, _ bloco: () -> Void) {
    guard alfa > 0.002 else { return }
    if alfa >= 0.998 { bloco(); return }
    cg.saveGState()
    cg.setAlpha(alfa)
    cg.beginTransparencyLayer(auxiliaryInfo: nil)
    bloco()
    cg.endTransparencyLayer()
    cg.restoreGState()
}

func transformado(_ t: CGAffineTransform, _ bloco: () -> Void) {
    cg.saveGState()
    cg.concatenate(t)
    bloco()
    cg.restoreGState()
}

/// Escala em torno de um ponto.
func escalado(_ fator: CGFloat, em c: CGPoint, _ bloco: () -> Void) {
    transformado(
        CGAffineTransform(translationX: c.x, y: c.y).scaledBy(x: fator, y: fator).translatedBy(x: -c.x, y: -c.y),
        bloco)
}

func recortado(_ r: CGRect, raio: CGFloat, _ bloco: () -> Void) {
    cg.saveGState()
    NSBezierPath(roundedRect: r, xRadius: raio, yRadius: raio).addClip()
    bloco()
    cg.restoreGState()
}

func fonte(_ tamanho: CGFloat, _ peso: NSFont.Weight = .regular, numeros: Bool = false) -> NSFont {
    numeros
        ? NSFont.monospacedDigitSystemFont(ofSize: tamanho, weight: peso)
        : NSFont.systemFont(ofSize: tamanho, weight: peso)
}

func atributos(_ f: NSFont, _ cor: NSColor, entrelinha: CGFloat = 0, espaco: CGFloat = 0)
    -> [NSAttributedString.Key: Any]
{
    let paragrafo = NSMutableParagraphStyle()
    paragrafo.lineSpacing = entrelinha
    paragrafo.lineBreakMode = .byWordWrapping
    var lista: [NSAttributedString.Key: Any] = [.font: f, .foregroundColor: cor, .paragraphStyle: paragrafo]
    if espaco != 0 { lista[.kern] = espaco }
    return lista
}

enum Alinhar { case esquerda, centro, direita }

func medir(_ s: String, _ f: NSFont, espaco: CGFloat = 0) -> CGSize {
    NSAttributedString(string: s, attributes: atributos(f, .black, espaco: espaco)).size()
}

/// Uma linha de texto. `y` é o meio da linha.
@discardableResult
func texto(_ s: String, x: CGFloat, y: CGFloat, _ f: NSFont, _ cor: NSColor, alinhar: Alinhar = .esquerda,
           espaco: CGFloat = 0) -> CGSize {
    let frase = NSAttributedString(string: s, attributes: atributos(f, cor, espaco: espaco))
    let tamanho = frase.size()
    var origem = x
    if alinhar == .centro { origem -= tamanho.width / 2 } else if alinhar == .direita { origem -= tamanho.width }
    frase.draw(at: CGPoint(x: origem, y: y - tamanho.height / 2))
    return tamanho
}

func alturaDoBloco(_ s: String, largura l: CGFloat, _ f: NSFont, entrelinha: CGFloat = 0) -> CGFloat {
    let frase = NSAttributedString(string: s, attributes: atributos(f, .black, entrelinha: entrelinha))
    return ceil(
        frase.boundingRect(
            with: CGSize(width: l, height: 2000), options: [.usesLineFragmentOrigin, .usesFontLeading]
        ).height)
}

/// Texto com quebra de linha a partir do canto superior esquerdo.
func bloco(_ s: String, x: CGFloat, y: CGFloat, largura l: CGFloat, _ f: NSFont, _ cor: NSColor,
           entrelinha: CGFloat = 0) {
    let frase = NSAttributedString(string: s, attributes: atributos(f, cor, entrelinha: entrelinha))
    let h = alturaDoBloco(s, largura: l, f, entrelinha: entrelinha)
    frase.draw(
        with: CGRect(x: x, y: y, width: l, height: h + 2), options: [.usesLineFragmentOrigin, .usesFontLeading])
}

nonisolated(unsafe) var simbolosFaltando = Set<String>()

func simbolo(_ nome: String, x: CGFloat, y: CGFloat, tamanho: CGFloat, _ cor: NSColor,
             peso: NSFont.Weight = .regular) {
    guard cor.alphaComponent > 0.002 else { return }
    guard let base = NSImage(systemSymbolName: nome, accessibilityDescription: nil) else {
        simbolosFaltando.insert(nome)
        return
    }
    let configuracao = NSImage.SymbolConfiguration(pointSize: tamanho, weight: peso)
        .applying(NSImage.SymbolConfiguration(paletteColors: [cor.withAlphaComponent(1)]))
    guard let imagem = base.withSymbolConfiguration(configuracao) else { return }
    let s = imagem.size
    imagem.draw(
        in: CGRect(x: x - s.width / 2, y: y - s.height / 2, width: s.width, height: s.height), from: .zero,
        operation: .sourceOver, fraction: cor.alphaComponent, respectFlipped: true, hints: nil)
}

// MARK: - Peças da cena

func mesa() {
    Cor.fundo.setFill()
    CGRect(x: 0, y: 0, width: largura, height: altura).fill()
    circulo(CGPoint(x: 70, y: 560), 300, Cor.fundo2)
    circulo(CGPoint(x: 820, y: 500), 190, Cor.fundo3)
    circulo(CGPoint(x: 690, y: 430), 46, Cor.fundo3)
}

struct EstadoDoIcone {
    var destaque: CGFloat = 0
    /// 0 = só o símbolo; 1 = anel (ou ✓) no lugar do símbolo.
    var glifo: CGFloat = 0
    /// 0 = anel; 1 = ✓.
    var pronto: CGFloat = 0
    /// Mostra a porcentagem ao lado (e alarga o item).
    var comTexto: CGFloat = 0
    var progresso: CGFloat = 0
    var bolinha: CGFloat = 0
}

/// O centro do símbolo do TranscreveAI na barra (sem porcentagem).
let centroDoIcone = CGPoint(x: 600, y: 14)

func anel(_ c: CGPoint, _ fracao: CGFloat, _ cor: NSColor) {
    let raio: CGFloat = 6.25
    cg.saveGState()
    cg.setLineWidth(2)
    cg.setStrokeColor(cor.a(0.3).cgColor)
    cg.addEllipse(in: CGRect(x: c.x - raio, y: c.y - raio, width: 2 * raio, height: 2 * raio))
    cg.strokePath()
    cg.setStrokeColor(cor.cgColor)
    cg.setLineCap(.round)
    let inicio = -CGFloat.pi / 2
    cg.addArc(center: c, radius: raio, startAngle: inicio, endAngle: inicio + 2 * .pi * max(0.02, fracao),
              clockwise: false)
    cg.strokePath()
    cg.restoreGState()
}

func barraDeMenus(_ e: EstadoDoIcone) {
    Cor.branco.a(0.78).setFill()
    CGRect(x: 0, y: 0, width: largura, height: 28).fill()
    Cor.preto.a(0.06).setFill()
    CGRect(x: 0, y: 28, width: largura, height: 0.5).fill()

    var x: CGFloat = 20
    x += texto("Finder", x: x, y: 14, fonte(13, .bold), Cor.tinta).width + 18
    for item in ["File", "Edit", "View", "Go", "Window", "Help"] {
        x += texto(item, x: x, y: 14, fonte(13), Cor.tinta).width + 17
    }
    texto("Tue 10:41", x: 784, y: 14, fonte(13, .medium), Cor.tinta, alinhar: .direita)
    simbolo("battery.75percent", x: 690, y: 14, tamanho: 13, Cor.tinta)
    simbolo("wifi", x: 652, y: 14, tamanho: 13, Cor.tinta, peso: .medium)

    // Item do TranscreveAI: cresce para a esquerda quando mostra a porcentagem.
    let w = mix(28, 64, e.comTexto)
    let item = CGRect(x: 614 - w, y: 3, width: w, height: 22)
    if e.destaque > 0 { caixa(item, raio: 6, Cor.preto.a(0.1 * e.destaque)) }
    let c = CGPoint(x: item.minX + 14, y: 14)
    simbolo("waveform", x: c.x, y: c.y, tamanho: 14, Cor.tinta.a(1 - e.glifo), peso: .medium)
    if e.glifo > 0 {
        if e.pronto < 1 { anel(c, e.progresso, Cor.tinta.a(e.glifo * (1 - e.pronto))) }
        simbolo("checkmark", x: c.x, y: c.y, tamanho: 13, Cor.tinta.a(e.glifo * e.pronto), peso: .bold)
    }
    if e.comTexto > 0 {
        camada(e.comTexto) {
            texto("\(Int(e.progresso * 100))%", x: item.minX + 26, y: 14, fonte(13, .medium, numeros: true), Cor.tinta)
        }
    }
    if e.bolinha > 0 {
        let r = 3.6 * mola(e.bolinha)
        circulo(CGPoint(x: c.x + 8, y: c.y - 6), r + 1, Cor.branco)
        circulo(CGPoint(x: c.x + 8, y: c.y - 6), r, Cor.vermelho)
    }
}

func cursor(_ p: CGPoint, pressionado: Bool = false) {
    let pontos: [(CGFloat, CGFloat)] = [(0, 0), (0, 16.5), (3.9, 12.8), (6.6, 19.2), (9.3, 18.1), (6.7, 11.9), (12, 11.9)]
    escalado(pressionado ? 0.9 : 1, em: p) {
        let caminho = NSBezierPath()
        caminho.move(to: CGPoint(x: p.x + pontos[0].0, y: p.y + pontos[0].1))
        for (x, y) in pontos.dropFirst() { caminho.line(to: CGPoint(x: p.x + x, y: p.y + y)) }
        caminho.close()
        caminho.lineJoinStyle = .round
        comSombra(raio: 3, y: 1.5, alfa: 0.35) {
            caminho.lineWidth = 2.8
            Cor.branco.setStroke()
            caminho.stroke()
        }
        Cor.preto.setFill()
        caminho.fill()
    }
}

func clique(_ p: CGPoint, _ x: CGFloat) {
    guard x > 0, x < 1 else { return }
    let r = mix(5, 24, saida(x))
    let alfa = (1 - x) * 0.6
    circulo(p, r, Cor.azul.a(alfa * 0.22))
    let anel = NSBezierPath(ovalIn: CGRect(x: p.x - r, y: p.y - r, width: 2 * r, height: 2 * r))
    anel.lineWidth = 2
    Cor.azul.a(alfa).setStroke()
    anel.stroke()
}

struct Arquivo {
    let nome: String
    let extensao: String
    let cor: NSColor
    let simbolo: String
}

func iconeDeArquivo(_ a: Arquivo, centro c: CGPoint, tamanho s: CGFloat = 1, rotulo: Bool = true,
                    selecionado: Bool = false, rotuloAEsquerda: Bool = false, rotuloEscuro: Bool = false) {
    let w = 40 * s, h = 50 * s, dobra = 11 * s, r = 5 * s
    let x = c.x - w / 2, y = c.y - h / 2
    let papel = NSBezierPath()
    papel.move(to: CGPoint(x: x + r, y: y))
    papel.line(to: CGPoint(x: x + w - dobra, y: y))
    papel.line(to: CGPoint(x: x + w, y: y + dobra))
    papel.line(to: CGPoint(x: x + w, y: y + h - r))
    papel.appendArc(from: CGPoint(x: x + w, y: y + h), to: CGPoint(x: x + w - r, y: y + h), radius: r)
    papel.line(to: CGPoint(x: x + r, y: y + h))
    papel.appendArc(from: CGPoint(x: x, y: y + h), to: CGPoint(x: x, y: y + h - r), radius: r)
    papel.line(to: CGPoint(x: x, y: y + r))
    papel.appendArc(from: CGPoint(x: x, y: y), to: CGPoint(x: x + r, y: y), radius: r)
    papel.close()
    comSombra(raio: 4, y: 2, alfa: 0.12) {
        Cor.branco.setFill()
        papel.fill()
    }
    papel.lineWidth = 1
    Cor.preto.a(0.12).setStroke()
    papel.stroke()
    let canto = NSBezierPath()
    canto.move(to: CGPoint(x: x + w - dobra, y: y))
    canto.line(to: CGPoint(x: x + w - dobra, y: y + dobra))
    canto.line(to: CGPoint(x: x + w, y: y + dobra))
    canto.close()
    NSColor(0xE5E5EA).setFill()
    canto.fill()

    simbolo(a.simbolo, x: c.x, y: c.y - 4 * s, tamanho: 15 * s, a.cor, peso: .semibold)
    let faixa = CGRect(x: x + 5 * s, y: y + h - 15 * s, width: w - 10 * s, height: 10 * s)
    caixa(faixa, raio: 2.5 * s, a.cor)
    texto(a.extensao.uppercased(), x: faixa.midX, y: faixa.midY, fonte(6.5 * s, .heavy), Cor.branco,
          alinhar: .centro, espaco: 0.3)

    guard rotulo else { return }
    let f = fonte(11, .medium)
    let t = medir(a.nome, f)
    let pilula: CGRect
    if rotuloAEsquerda {
        pilula = CGRect(x: x - 10 - t.width - 16, y: c.y - 10, width: t.width + 16, height: 20)
    } else {
        pilula = CGRect(x: c.x - t.width / 2 - 6, y: y + h + 5, width: t.width + 12, height: 18)
    }
    if selecionado {
        caixa(pilula, raio: pilula.height / 2, Cor.azul)
    } else if rotuloEscuro {
        caixa(pilula, raio: pilula.height / 2, Cor.preto.a(0.55))
    }
    texto(a.nome, x: pilula.midX, y: pilula.midY, f, selecionado || rotuloEscuro ? Cor.branco : Cor.tinta,
          alinhar: .centro)
}

/// Janela do Finder simplificada, na pasta Downloads.
func janelaDoFinder(_ r: CGRect) {
    comSombra(raio: 26, y: 12, alfa: 0.16) { caixa(r, raio: 12, Cor.branco) }
    recortado(r, raio: 12) {
        NSColor(0xF2F2F5).setFill()
        CGRect(x: r.minX, y: r.minY, width: 132, height: r.height).fill()
        Cor.preto.a(0.07).setFill()
        CGRect(x: r.minX + 132, y: r.minY + 44, width: r.width - 132, height: 0.5).fill()
    }
    borda(r, raio: 12, Cor.preto.a(0.1))
    for (i, cor) in [NSColor(0xFF5F57), NSColor(0xFEBC2E), NSColor(0x28C840)].enumerated() {
        circulo(CGPoint(x: r.minX + 18 + CGFloat(i) * 19, y: r.minY + 20), 6, cor)
    }
    texto("Favorites", x: r.minX + 16, y: r.minY + 52, fonte(11, .semibold), Cor.cinza.a(0.8))
    let itens: [(String, String)] = [
        ("clock", "Recents"), ("square.grid.2x2", "Applications"), ("desktopcomputer", "Desktop"),
        ("doc", "Documents"), ("arrow.down.circle", "Downloads"),
    ]
    for (i, item) in itens.enumerated() {
        let y = r.minY + 76 + CGFloat(i) * 26
        if item.1 == "Downloads" {
            caixa(CGRect(x: r.minX + 8, y: y - 11, width: 116, height: 22), raio: 6, Cor.preto.a(0.08))
        }
        simbolo(item.0, x: r.minX + 25, y: y, tamanho: 12, Cor.azul, peso: .medium)
        texto(item.1, x: r.minX + 38, y: y, fonte(12.5), Cor.tinta)
    }
    simbolo("chevron.left", x: r.minX + 152, y: r.minY + 22, tamanho: 12, Cor.cinza, peso: .semibold)
    simbolo("chevron.right", x: r.minX + 172, y: r.minY + 22, tamanho: 12, Cor.cinza.a(0.4), peso: .semibold)
    texto("Downloads", x: r.minX + 190, y: r.minY + 22, fonte(13, .bold), Cor.tinta)
    simbolo("magnifyingglass", x: r.maxX - 22, y: r.minY + 22, tamanho: 12, Cor.cinza, peso: .medium)
}

// MARK: - Dock e pilha de Downloads

let centroDaPilha = CGPoint(x: 560, y: 465)

func dock() {
    let r = CGRect(x: 210, y: 438, width: 380, height: 54)
    comSombra(raio: 18, y: 6, alfa: 0.12) { caixa(r, raio: 17, Cor.branco.a(0.6)) }
    borda(r, raio: 17, Cor.branco.a(0.8))
    let apps: [(String, UInt32)] = [
        ("folder.fill", 0x3B82F6), ("envelope.fill", 0x0EA5E9), ("message.fill", 0x22C55E),
        ("music.note", 0xF43F5E), ("calendar", 0xF97316), ("gearshape.fill", 0x8E8E93),
    ]
    for (i, app) in apps.enumerated() {
        let q = CGRect(x: 218 + CGFloat(i) * 52, y: 443, width: 44, height: 44)
        caixa(q, raio: 11, NSColor(app.1))
        simbolo(app.0, x: q.midX, y: q.midY, tamanho: 19, Cor.branco, peso: .semibold)
    }
    Cor.preto.a(0.15).setFill()
    CGRect(x: 529.5, y: 448, width: 1, height: 34).fill()
    // Pilha de Downloads: pasta azul com a seta.
    let q = CGRect(x: centroDaPilha.x - 22, y: 443, width: 44, height: 44)
    caixa(CGRect(x: q.minX + 2, y: q.minY + 6, width: 18, height: 8), raio: 3, NSColor(0x5AA2F5))
    caixa(CGRect(x: q.minX + 2, y: q.minY + 10, width: 40, height: 30), raio: 6, NSColor(0x7DB8FA))
    simbolo("arrow.down", x: q.midX, y: q.minY + 26, tamanho: 14, Cor.branco, peso: .bold)
}

/// Os arquivos da pilha abertos em leque, de baixo para cima.
let posicoesDoLeque: [CGPoint] = [
    CGPoint(x: 556, y: 398), CGPoint(x: 562, y: 336), CGPoint(x: 572, y: 274), CGPoint(x: 586, y: 212),
]

func leque(_ abertura: CGFloat, _ itens: [Arquivo], destaque: Int?) {
    guard abertura > 0 else { return }
    for (i, item) in itens.enumerated() {
        let atraso = CGFloat(i) * 0.1
        let x = limitar((abertura - atraso) / (1 - 0.3))
        guard x > 0 else { continue }
        let p = mix(centroDaPilha, posicoesDoLeque[i], mola(x))
        camada(limitar(x * 3)) {
            iconeDeArquivo(item, centro: p, tamanho: 0.85, selecionado: destaque == i, rotuloAEsquerda: true,
                           rotuloEscuro: true)
        }
    }
}

// MARK: - Legendas de passo

struct Passo {
    let inicio: Double
    let fim: Double
    let numero: Int
    let texto: String
}

func legendas(_ passos: [Passo], _ t: Double) {
    for passo in passos {
        let entra = saida(fase(t, passo.inicio, passo.inicio + 0.35))
        let sai = fase(t, passo.fim - 0.28, passo.fim)
        let alfa = entra * (1 - sai)
        guard alfa > 0 else { continue }
        let dy = (1 - entra) * 12 - sai * 8
        camada(alfa) {
            let f = fonte(14.5, .semibold)
            let t = medir(passo.texto, f)
            let r = CGRect(x: 24, y: 44 + dy, width: 6 + 26 + 10 + t.width + 16, height: 38)
            comSombra(raio: 14, y: 5, alfa: 0.12) { caixa(r, raio: 19, Cor.branco) }
            circulo(CGPoint(x: r.minX + 19, y: r.midY), 13, Cor.azul)
            texto("\(passo.numero)", x: r.minX + 19, y: r.midY, fonte(13, .bold), Cor.branco, alinhar: .centro)
            texto(passo.texto, x: r.minX + 42, y: r.midY, f, Cor.tinta)
        }
    }
}

// MARK: - Painel (imita PainelView.swift)

struct Demo {
    let arquivo: Arquivo
    let duracao: String
    let tempo: String
    let paragrafos: [(String, String)]
}

enum Conteudo {
    case vazio(arrastando: CGFloat)
    case trabalhando(Demo, fracao: CGFloat)
    case pronto(Demo, revelar: CGFloat)
}

let larguraDoPainel: CGFloat = 380
let topoDoPainel: CGFloat = 34
let margem: CGFloat = 14
let larguraInterna = larguraDoPainel - 2 * margem
let fonteDoParagrafo = fonte(13.5)
let larguraDoParagrafo = larguraInterna - 24 - 48

func alturaDosParagrafos(_ demo: Demo) -> CGFloat {
    let textos = demo.paragrafos.map { alturaDoBloco($0.1, largura: larguraDoParagrafo, fonteDoParagrafo, entrelinha: 2) }
    return 24 + textos.reduce(0, +) + CGFloat(textos.count - 1) * 12
}

func alturaInterna(_ c: Conteudo) -> CGFloat {
    switch c {
    case .vazio: 30 + 12 + 188 + 12 + 22
    case .trabalhando: 34 + 12 + 29 + 12 + 30
    case .pronto(let demo, _): 34 + 12 + alturaDosParagrafos(demo) + 12 + 24
    }
}

func alturaDoPainel(_ c: Conteudo) -> CGFloat { alturaInterna(c) + 2 * margem }

func cabecalho(_ r: CGRect, titulo: String, detalhe: String?) {
    if let detalhe {
        texto(titulo, x: r.minX, y: r.minY + 8, fonte(13, .semibold), Cor.tinta)
        texto(detalhe, x: r.minX, y: r.minY + 25, fonte(11.5, numeros: true), Cor.cinza)
    } else {
        texto(titulo, x: r.minX, y: r.minY + 15, fonte(13, .semibold), Cor.tinta)
    }
    simbolo("ellipsis", x: r.maxX - 14, y: r.minY + 15, tamanho: 13, Cor.cinza, peso: .semibold)
}

func botaoPequeno(_ titulo: String, simbolo nome: String?, direita: CGFloat? = nil, x: CGFloat = 0, y: CGFloat,
                  seta: Bool = false) -> CGRect {
    let f = fonte(11.5)
    let t = medir(titulo, f)
    var w = t.width + 16
    if nome != nil { w += 16 }
    if seta { w += 12 }
    let r = CGRect(x: direita.map { $0 - w } ?? x, y: y, width: w, height: 22)
    comSombra(raio: 1.5, y: 0.5, alfa: 0.12) { caixa(r, raio: 6, Cor.branco) }
    borda(r, raio: 6, Cor.preto.a(0.12))
    var cx = r.minX + 8
    if let nome {
        simbolo(nome, x: cx + 6, y: r.midY, tamanho: 10.5, Cor.tinta, peso: .medium)
        cx += 16
    }
    texto(titulo, x: cx, y: r.midY, f, Cor.tinta)
    if seta { simbolo("chevron.down", x: r.maxX - 10, y: r.midY + 0.5, tamanho: 7.5, Cor.cinza, peso: .bold) }
    return r
}

func conteudo(_ c: Conteudo, _ r: CGRect) {
    switch c {
    case .vazio(let x):
        cabecalho(r, titulo: "TranscreveAI", detalhe: nil)
        let area = CGRect(x: r.minX, y: r.minY + 42, width: r.width, height: 188)
        caixa(area, raio: 14, misturar(Cor.preto.a(0.03), Cor.azul.a(0.1), x))
        borda(area, raio: 14, misturar(Cor.preto.a(0.22), Cor.azul, x), espessura: 2, tracejado: [6, 5])
        let topo = area.midY - 56
        let quadrado = CGRect(x: area.midX - 30, y: topo, width: 60, height: 60)
        escalado(1 + 0.06 * x, em: CGPoint(x: quadrado.midX, y: quadrado.midY)) {
            caixa(quadrado, raio: 18, misturar(Cor.preto.a(0.08), Cor.azul, x))
            simbolo("tray.and.arrow.down", x: quadrado.midX, y: quadrado.midY, tamanho: 26,
                    misturar(Cor.cinza, Cor.branco, x))
        }
        texto("Drop an audio file here", x: area.midX, y: topo + 83, fonte(17, .semibold), Cor.tinta.a(1 - x),
              alinhar: .centro)
        texto("Release to transcribe", x: area.midX, y: topo + 83, fonte(17, .semibold), Cor.tinta.a(x),
              alinhar: .centro)
        texto("or click to choose a file", x: area.midX, y: topo + 104, fonte(12.5), Cor.cinza,
              alinhar: .centro)
        let linha = area.maxY + 12
        let modelo = botaoPequeno("Fastest", simbolo: "bolt", x: r.minX, y: linha, seta: true)
        _ = botaoPequeno("Auto", simbolo: "globe", x: modelo.maxX + 8, y: linha, seta: true)

    case .trabalhando(let demo, let fracao):
        cabecalho(r, titulo: demo.arquivo.nome, detalhe: "\(demo.duracao) · Parakeet v3")
        let topo = r.minY + 46
        texto("Transcribing…", x: r.minX, y: topo + 8, fonte(12.5, .medium), Cor.tinta)
        texto("\(Int(fracao * 100))%", x: r.maxX, y: topo + 8, fonte(12.5, numeros: true), Cor.cinza, alinhar: .direita)
        let trilho = CGRect(x: r.minX, y: topo + 23, width: r.width, height: 6)
        caixa(trilho, raio: 3, Cor.preto.a(0.1))
        caixa(CGRect(x: trilho.minX, y: trilho.minY, width: max(6, trilho.width * fracao), height: 6), raio: 3, Cor.azul)
        let dica = topo + 29 + 12
        bloco("You can close the panel: progress shows on the menu bar icon.", x: r.minX, y: dica, largura: r.width - 96,
              fonte(11.5), Cor.cinza)
        _ = botaoPequeno("Cancel", simbolo: nil, direita: r.maxX, y: dica + 3)

    case .pronto(let demo, let revelar):
        cabecalho(r, titulo: demo.arquivo.nome, detalhe: "\(demo.duracao) · transcribed in \(demo.tempo) · Parakeet v3")
        let caixaDoTexto = CGRect(x: r.minX, y: r.minY + 46, width: r.width, height: alturaDosParagrafos(demo))
        caixa(caixaDoTexto, raio: 12, Cor.preto.a(0.05))
        var y = caixaDoTexto.minY + 12
        for (i, paragrafo) in demo.paragrafos.enumerated() {
            let h = alturaDoBloco(paragrafo.1, largura: larguraDoParagrafo, fonteDoParagrafo, entrelinha: 2)
            let x = saida(limitar((revelar - CGFloat(i) * 0.22) / 0.5))
            let base = y
            camada(x) {
                let dy = (1 - x) * 8
                texto(paragrafo.0, x: caixaDoTexto.minX + 12, y: base + 9 + dy, fonte(11.5, numeros: true), Cor.cinza)
                bloco(paragrafo.1, x: caixaDoTexto.minX + 60, y: base + dy, largura: larguraDoParagrafo,
                      fonteDoParagrafo, Cor.tinta, entrelinha: 2)
            }
            y += h + 12
        }
        let linha = caixaDoTexto.maxY + 12
        simbolo("arrow.uturn.backward", x: r.minX + 7, y: linha + 11, tamanho: 11, Cor.tinta, peso: .medium)
        texto("New", x: r.minX + 19, y: linha + 11, fonte(13), Cor.tinta)
        let copiado = saida(fase(Double(revelar), 0.7, 1))
        camada(copiado) {
            let b = botaoPequeno("Copied", simbolo: "checkmark", direita: r.maxX, y: linha + 1)
            _ = b
        }
    }
}

/// Desenha o painel embaixo do ícone. `abertura` anima a entrada; `transicao` cruza de `de` para `para`.
func painel(abertura: CGFloat, _ de: Conteudo, para: Conteudo? = nil, transicao: CGFloat = 0) {
    guard abertura > 0 else { return }
    let x = suave(transicao)
    let h = para.map { mix(alturaDoPainel(de), alturaDoPainel($0), x) } ?? alturaDoPainel(de)
    let r = CGRect(x: centroDoIcone.x - larguraDoPainel / 2, y: topoDoPainel - (1 - saida(abertura)) * 8,
                   width: larguraDoPainel, height: h)
    camada(saida(abertura)) {
        escalado(mix(0.96, 1, saida(abertura)), em: CGPoint(x: r.midX, y: r.minY)) {
            comSombra(raio: 30, y: 14, alfa: 0.2) { caixa(r, raio: 16, Cor.branco) }
            borda(r, raio: 16, Cor.preto.a(0.1))
            recortado(r, raio: 16) {
                let dentro = CGRect(x: r.minX + margem, y: r.minY + margem, width: larguraInterna, height: h - 2 * margem)
                camada(1 - x) { conteudo(de, dentro) }
                if let para { camada(x) { conteudo(para, dentro) } }
            }
        }
    }
}

/// O ponto onde o arquivo é solto (meio da área tracejada).
let pontoDeSoltar = CGPoint(x: 600, y: 170)

// MARK: - Conteúdo das demonstrações (texto inventado)

let reuniao = Demo(
    arquivo: Arquivo(nome: "meeting.m4a", extensao: "m4a", cor: NSColor(0xFF9500), simbolo: "waveform"),
    duracao: "12:48", tempo: "3.4 s",
    paragrafos: [
        ("0:00", "Good morning, everyone. Let's start with this week's numbers, then the launch."),
        ("0:18", "Sales went up twelve percent, driven by the annual plan that went live on Monday."),
        ("0:41", "Next steps: review the budget by Friday and schedule the presentation with the team."),
    ])

let entrevista = Demo(
    arquivo: Arquivo(nome: "interview.opus", extensao: "opus", cor: NSColor(0xAF52DE), simbolo: "waveform"),
    duracao: "6:12", tempo: "1.7 s",
    paragrafos: [
        ("0:00", "Thanks for having us. To start, tell us a little about your career so far."),
        ("0:09", "I started out as a designer, but soon moved into product, and that changed everything."),
        ("0:27", "What I learned is that the hardest part is deciding what to leave out."),
    ])

let podcast = Demo(
    arquivo: Arquivo(nome: "podcast-ep12.mp3", extensao: "mp3", cor: NSColor(0xFF2D55), simbolo: "waveform"),
    duracao: "38:20", tempo: "10.2 s",
    paragrafos: [
        ("0:00", "Hi, and welcome to another episode. Today we're talking about everyday productivity."),
        ("0:14", "The first tip is simple: before you start, write down what has to be done by the end."),
        ("0:36", "The second is to protect a block of time with no meetings, every day, at the same hour."),
    ])

let pdf = Arquivo(nome: "report.pdf", extensao: "pdf", cor: NSColor(0xFF3B30), simbolo: "doc.richtext")
let foto = Arquivo(nome: "team.jpg", extensao: "jpg", cor: NSColor(0x34C759), simbolo: "photo")
let notas = Arquivo(nome: "notes.txt", extensao: "txt", cor: NSColor(0x8E8E93), simbolo: "doc.text")

let janela = CGRect(x: 36, y: 108, width: 352, height: 300)
let gradeDoFinder: [CGPoint] = [
    CGPoint(x: 222, y: 196), CGPoint(x: 326, y: 196), CGPoint(x: 222, y: 312), CGPoint(x: 326, y: 312),
]

func finder(_ arquivos: [Arquivo], selecionado: Int? = nil) {
    janelaDoFinder(janela)
    for (i, a) in arquivos.enumerated() {
        iconeDeArquivo(a, centro: gradeDoFinder[i], selecionado: selecionado == i)
    }
}

/// O arquivo arrastado: a imagem semitransparente que acompanha o cursor.
func fantasma(_ a: Arquivo, _ p: CGPoint, alfa: CGFloat, tamanho: CGFloat = 1) {
    camada(alfa * 0.8) { iconeDeArquivo(a, centro: CGPoint(x: p.x + 2, y: p.y + 8), tamanho: tamanho, rotulo: false) }
}

// MARK: - 1. Soltar no painel

func soltar(_ t: Double) {
    mesa()
    let abertura = fase(t, 1.38, 1.62)
    let selecionado = t >= 2.8 ? 0 : nil
    finder([reuniao.arquivo, pdf, foto, notas], selecionado: selecionado)
    barraDeMenus(EstadoDoIcone(destaque: abertura))

    let arrastando = fase(t, 3.62, 3.76)
    let progresso = suave(fase(t, 4.4, 6.3))
    let revelar = fase(t, 6.6, 7.7)
    if t < 4.1 {
        painel(abertura: abertura, .vazio(arrastando: arrastando))
    } else if t < 4.4 {
        painel(abertura: 1, .vazio(arrastando: 1 - fase(t, 4.1, 4.3)), para: .trabalhando(reuniao, fracao: 0),
               transicao: fase(t, 4.1, 4.4))
    } else if t < 6.35 {
        painel(abertura: 1, .trabalhando(reuniao, fracao: progresso))
    } else if t < 6.7 {
        painel(abertura: 1, .trabalhando(reuniao, fracao: 1), para: .pronto(reuniao, revelar: 0),
               transicao: fase(t, 6.35, 6.7))
    } else {
        painel(abertura: 1, .pronto(reuniao, revelar: revelar))
    }

    let p = ponto([
        Trecho(t0: 0.4, t1: 1.25, a: CGPoint(x: 300, y: 430), b: centroDoIcone, c: CGPoint(x: 520, y: 260)),
        Trecho(t0: 1.9, t1: 2.7, a: centroDoIcone, b: gradeDoFinder[0], c: CGPoint(x: 430, y: 120)),
        Trecho(t0: 2.95, t1: 4.0, a: gradeDoFinder[0], b: pontoDeSoltar, c: CGPoint(x: 400, y: 110)),
        Trecho(t0: 4.35, t1: 5.2, a: pontoDeSoltar, b: CGPoint(x: 300, y: 440), c: CGPoint(x: 430, y: 380)),
    ], inicio: CGPoint(x: 300, y: 430), t)
    if t > 2.95, t < 4.25 {
        let alfa = fase(t, 2.95, 3.05) * (1 - fase(t, 4.05, 4.2))
        fantasma(reuniao.arquivo, p, alfa: alfa, tamanho: mix(1, 0.6, fase(t, 4.05, 4.2)))
    }
    clique(centroDoIcone, fase(t, 1.3, 1.8))
    clique(pontoDeSoltar, fase(t, 4.05, 4.55))
    cursor(p, pressionado: (t > 1.27 && t < 1.42) || (t > 2.8 && t < 4.05))
    legendas([
        Passo(inicio: 0.3, fim: 2.75, numero: 1, texto: "Click the icon in the menu bar"),
        Passo(inicio: 2.75, fim: 6.45, numero: 2, texto: "Drag an audio file onto the panel"),
        Passo(inicio: 6.45, fim: 9.95, numero: 3, texto: "The text is ready, already copied"),
    ], t)
}

// MARK: - 2. Arrastar da pilha do Dock

func arrastarDoDock(_ t: Double) {
    mesa()
    let abertura = fase(t, 2.95, 3.2)
    barraDeMenus(EstadoDoIcone(destaque: 0))
    dock()
    let leque1 = fase(t, 1.3, 2.0) * (1 - fase(t, 3.0, 3.35))
    leque(leque1, [pdf, entrevista.arquivo, foto, notas], destaque: t >= 2.6 ? 1 : nil)

    let arrastando = fase(t, 4.22, 4.36)
    let progresso = suave(fase(t, 4.95, 6.4))
    let revelar = fase(t, 6.7, 7.8)
    if t < 4.65 {
        painel(abertura: abertura, .vazio(arrastando: arrastando))
    } else if t < 4.95 {
        painel(abertura: 1, .vazio(arrastando: 1 - fase(t, 4.65, 4.85)), para: .trabalhando(entrevista, fracao: 0),
               transicao: fase(t, 4.65, 4.95))
    } else if t < 6.45 {
        painel(abertura: 1, .trabalhando(entrevista, fracao: progresso))
    } else if t < 6.8 {
        painel(abertura: 1, .trabalhando(entrevista, fracao: 1), para: .pronto(entrevista, revelar: 0),
               transicao: fase(t, 6.45, 6.8))
    } else {
        painel(abertura: 1, .pronto(entrevista, revelar: revelar))
    }

    let item = posicoesDoLeque[1]
    let p = ponto([
        Trecho(t0: 0.4, t1: 1.2, a: CGPoint(x: 420, y: 300), b: centroDaPilha, c: CGPoint(x: 470, y: 420)),
        Trecho(t0: 2.0, t1: 2.5, a: centroDaPilha, b: item, c: CGPoint(x: 540, y: 400)),
        Trecho(t0: 2.75, t1: 4.55, a: item, b: pontoDeSoltar, c: CGPoint(x: 700, y: 300)),
        Trecho(t0: 4.85, t1: 5.7, a: pontoDeSoltar, b: CGPoint(x: 330, y: 330), c: CGPoint(x: 420, y: 260)),
    ], inicio: CGPoint(x: 420, y: 300), t)
    if t > 2.75, t < 4.8 {
        let alfa = fase(t, 2.75, 2.85) * (1 - fase(t, 4.6, 4.75))
        fantasma(entrevista.arquivo, p, alfa: alfa, tamanho: mix(0.85, 0.55, fase(t, 4.6, 4.75)))
    }
    clique(centroDaPilha, fase(t, 1.25, 1.75))
    clique(pontoDeSoltar, fase(t, 4.6, 5.1))
    cursor(p, pressionado: (t > 1.22 && t < 1.37) || (t > 2.6 && t < 4.6))
    legendas([
        Passo(inicio: 0.3, fim: 3.0, numero: 1, texto: "Drag an audio file, even from the Dock"),
        Passo(inicio: 3.0, fim: 4.7, numero: 2, texto: "The panel opens on its own"),
        Passo(inicio: 4.7, fim: 10.1, numero: 3, texto: "Drop it: the text shows up in seconds"),
    ], t)
}

// MARK: - 3. Painel fechado: progresso no ícone

let centroDaLupa = CGPoint(x: 600, y: 98)

func lupa(_ alfa: CGFloat, _ e: EstadoDoIcone, som: CGFloat) {
    guard alfa > 0 else { return }
    // Por dentro, 72 pt de altura: a barra (28 pt) aumentada 2,6×, sem sobrar a mesa embaixo.
    let r = CGRect(x: centroDaLupa.x - 150, y: centroDaLupa.y - 40, width: 300, height: 80)
    camada(alfa) {
        escalado(mix(0.9, 1, saida(alfa)), em: CGPoint(x: r.midX, y: r.minY)) {
            // Bico apontando para o ícone.
            let bico = NSBezierPath()
            bico.move(to: CGPoint(x: centroDoIcone.x - 10, y: r.minY + 1))
            bico.line(to: CGPoint(x: centroDoIcone.x, y: r.minY - 12))
            bico.line(to: CGPoint(x: centroDoIcone.x + 10, y: r.minY + 1))
            bico.close()
            comSombra(raio: 22, y: 10, alfa: 0.2) {
                caixa(r, raio: 22, Cor.branco)
                Cor.branco.setFill()
                bico.fill()
            }
            recortado(r.insetBy(dx: 4, dy: 4), raio: 18) {
                let fator: CGFloat = 2.6
                let alvo = CGPoint(x: r.midX - 12, y: r.midY)
                transformado(
                    CGAffineTransform(translationX: alvo.x, y: alvo.y).scaledBy(x: fator, y: fator)
                        .translatedBy(x: -centroDoIcone.x, y: -centroDoIcone.y)
                ) {
                    Cor.fundo.setFill()
                    CGRect(x: 0, y: 0, width: largura, height: 40).fill()
                    barraDeMenus(e)
                }
            }
            if som > 0 {
                let c = CGPoint(x: r.maxX - 6, y: r.minY + 6)
                let x = mola(limitar(som * 1.6))
                camada(1 - fase(Double(som), 0.85, 1)) {
                    let onda = limitar(som * 1.3)
                    circulo(c, 17 + 14 * saida(onda), Cor.azul.a(0.25 * (1 - onda)))
                    escalado(x, em: c) {
                        circulo(c, 17, Cor.azul)
                        simbolo("speaker.wave.2.fill", x: c.x, y: c.y, tamanho: 13, Cor.branco, peso: .semibold)
                    }
                }
            }
        }
    }
}

func painelFechado(_ t: Double) {
    mesa()
    finder([podcast.arquivo, pdf, foto, notas])

    let fechou = fase(t, 1.62, 1.74)
    let reabriu = fase(t, 8.4, 8.65)
    let progresso = mix(0.16, 1, fase(t, 0, 5.2))
    var icone = EstadoDoIcone()
    icone.destaque = max(1 - fechou, reabriu)
    let comAnel = fase(t, 1.75, 2.0) * (1 - fase(t, 6.3, 6.5))
    icone.glifo = comAnel
    icone.comTexto = fase(t, 1.75, 2.0) * (1 - fase(t, 5.2, 5.45))
    icone.pronto = fase(t, 5.2, 5.35)
    icone.progresso = progresso
    icone.bolinha = fase(t, 6.45, 6.75) * (1 - fase(t, 8.36, 8.42))
    barraDeMenus(icone)

    if t < 1.75 {
        painel(abertura: 1 - fechou, .trabalhando(podcast, fracao: progresso))
    } else if t >= 8.4 {
        painel(abertura: reabriu, .pronto(podcast, revelar: fase(t, 8.6, 9.7)))
    }
    lupa(fase(t, 2.0, 2.4) * (1 - fase(t, 7.4, 7.7)), icone, som: fase(t, 5.2, 6.3))

    let p = ponto([
        Trecho(t0: 0.5, t1: 1.45, a: CGPoint(x: 300, y: 300), b: CGPoint(x: 250, y: 450), c: CGPoint(x: 330, y: 400)),
        Trecho(t0: 7.5, t1: 8.3, a: CGPoint(x: 250, y: 450), b: centroDoIcone, c: CGPoint(x: 500, y: 330)),
        Trecho(t0: 8.8, t1: 9.6, a: centroDoIcone, b: CGPoint(x: 330, y: 440), c: CGPoint(x: 420, y: 330)),
    ], inicio: CGPoint(x: 300, y: 300), t)
    clique(CGPoint(x: 250, y: 450), fase(t, 1.55, 2.05))
    clique(centroDoIcone, fase(t, 8.35, 8.85))
    cursor(p, pressionado: (t > 1.52 && t < 1.66) || (t > 8.32 && t < 8.46))
    legendas([
        Passo(inicio: 0.3, fim: 2.4, numero: 1, texto: "Close the panel any time"),
        Passo(inicio: 2.4, fim: 6.35, numero: 2, texto: "Progress stays in the menu bar"),
        Passo(inicio: 6.35, fim: 11.1, numero: 3, texto: "A red dot means a new result"),
    ], t)
}

// MARK: - Programa

struct Animacao {
    let nome: String
    let duracao: Double
    let desenhar: (Double) -> Void
}

let animacoes = [
    Animacao(nome: "soltar", duracao: 10.4, desenhar: soltar),
    Animacao(nome: "dock", duracao: 10.6, desenhar: arrastarDoDock),
    Animacao(nome: "painel-fechado", duracao: 11.6, desenhar: painelFechado),
]

let argumentos = CommandLine.arguments.dropFirst()
let destino = URL(fileURLWithPath: argumentos.first ?? "quadros")
let escolhidas = Set(argumentos.dropFirst())
let apenasQuadro = ProcessInfo.processInfo.environment["QUADRO"].flatMap(Double.init)

guard let imagem = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: Int(largura * escala), pixelsHigh: Int(altura * escala), bitsPerSample: 8,
    samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)
else { fatalError("sem memória para o quadro") }
imagem.size = NSSize(width: largura, height: altura)

func desenharQuadro(_ animacao: Animacao, _ t: Double, em arquivo: URL) {
    guard let contexto = NSGraphicsContext(bitmapImageRep: imagem) else { return }
    cg = contexto.cgContext
    cg.saveGState()
    // O contexto do bitmap já desenha em pontos (2 px por ponto); só falta inverter o eixo y.
    cg.translateBy(x: 0, y: altura)
    cg.scaleBy(x: 1, y: -1)
    NSGraphicsContext.current = NSGraphicsContext(cgContext: cg, flipped: true)
    animacao.desenhar(t)
    // Fim: volta ao primeiro quadro, para o GIF repetir sem salto.
    let volta = fase(t, animacao.duracao - 0.5, animacao.duracao - 1 / quadrosPorSegundo)
    if volta > 0 { camada(suave(volta)) { animacao.desenhar(0) } }
    cg.restoreGState()
    NSGraphicsContext.current = nil
    try? imagem.representation(using: .png, properties: [:])?.write(to: arquivo)
}

for animacao in animacoes where escolhidas.isEmpty || escolhidas.contains(animacao.nome) {
    let pasta = destino.appendingPathComponent(animacao.nome)
    try? FileManager.default.removeItem(at: pasta)
    try FileManager.default.createDirectory(at: pasta, withIntermediateDirectories: true)
    if let apenasQuadro {
        desenharQuadro(animacao, apenasQuadro, em: pasta.appendingPathComponent("previa.png"))
        continue
    }
    let total = Int((animacao.duracao * quadrosPorSegundo).rounded())
    for i in 0..<total {
        desenharQuadro(animacao, Double(i) / quadrosPorSegundo,
                       em: pasta.appendingPathComponent(String(format: "q%04d.png", i)))
    }
    print("\(animacao.nome): \(total) quadros")
}
if !simbolosFaltando.isEmpty { print("Símbolos que não existem: \(simbolosFaltando.sorted())") }
