import Combine
import SwiftUI
import TranscreveMotores

/// O painel da barra de menus (mockup, página "Menu bar"): arrastar, transcrevendo, transcrição pronta.
struct PainelView: View {
    let estado: EstadoApp
    let historico: Historico
    let escolherArquivo: () -> Void
    let procurarAtualizacoes: () -> Void
    let abrirAjustes: () -> Void
    let sair: () -> Void

    @AppStorage(Preferencia.modelo) private var modelo: ModeloTranscricao = .automatico
    @AppStorage(Preferencia.idioma) private var idioma: IdiomaAudio = .auto
    @AppStorage(Preferencia.copiarAoTerminar) private var copiarAoTerminar = true
    @AppStorage(Preferencia.abrirAoArrastar) private var abrirAoArrastar = true
    @AppStorage(Preferencia.somAoTerminar) private var somAoTerminar = true
    @State private var abrirAoIniciar = InicioAutomatico.ativo
    @State private var podeProcurar = false
    @State private var arrastando = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            cabecalho
            switch estado.fase {
            case .vazio:
                if estado.mostrandoHistorico {
                    ListaDoHistorico(
                        historico: historico, abrir: estado.abrir, copiar: { estado.copiar($0) },
                        voltar: { estado.mostrandoHistorico = false })
                } else {
                    areaDeArraste
                    rodape
                    if let aviso = estado.aviso { nota(aviso, simbolo: "exclamationmark.triangle") }
                    if let nota = estado.notaDoModelo { self.nota(nota, simbolo: "arrow.down.circle") }
                    if !historico.itens.isEmpty {
                        Recentes(
                            itens: Array(historico.itens.prefix(3)), total: historico.itens.count,
                            abrir: estado.abrir, copiar: { estado.copiar($0) },
                            apagar: { historico.apagar($0.id) },
                            verTudo: { estado.mostrandoHistorico = true })
                    }
                }
            case .trabalhando(let trabalho):
                Andamento(trabalho: trabalho, cancelar: estado.cancelar)
            case .pronto(let transcricao):
                Resultado(transcricao: transcricao, nota: estado.notaDoModelo, novo: estado.limpar)
            case .erro(let mensagem):
                Falha(mensagem: mensagem, tentarDeNovo: estado.tentarDeNovo, novo: estado.limpar)
            }
        }
        .padding(14)
        .overlay {
            // Com um arquivo na tela não há área tracejada: o painel inteiro vira o alvo.
            if arrastando && estado.arquivo != nil { soltarPorCima }
        }
        .dropDestination(for: URL.self) { urls, _ in
            estado.receber(urls)
        } isTargeted: { arrastando = $0 }
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.primary.opacity(0.1))
                .allowsHitTesting(false)
        }
        .onReceive(Atualizacoes.atualizador.publisher(for: \.canCheckForUpdates)) { podeProcurar = $0 }
    }

    private func nota(_ texto: String, simbolo: String) -> some View {
        Label(texto, systemImage: simbolo)
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: Cabeçalho

    private var cabecalho: some View {
        HStack(spacing: 10) {
            if let arquivo = estado.arquivo {
                VStack(alignment: .leading, spacing: 2) {
                    Text(arquivo.nome)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Text(detalhes(de: arquivo))
                        .font(.system(size: 11.5))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            } else {
                Text("TranscreveAI").font(.system(size: 13, weight: .semibold))
            }
            Spacer(minLength: 0)
            Menu {
                Toggle("Copiar ao terminar", isOn: $copiarAoTerminar)
                Toggle("Som ao terminar", isOn: $somAoTerminar)
                Toggle("Abrir ao arrastar um áudio", isOn: $abrirAoArrastar)
                Toggle("Abrir ao iniciar o Mac", isOn: Binding(
                    get: { abrirAoIniciar },
                    set: { InicioAutomatico.definir($0); abrirAoIniciar = InicioAutomatico.ativo }))
                Divider()
                Button("Procurar atualizações…", action: procurarAtualizacoes)
                    .disabled(!podeProcurar)
                Button("Ajustes…", action: abrirAjustes)
                    .keyboardShortcut(",")
                Divider()
                Button("Sair do TranscreveAI", action: sair)
                    .keyboardShortcut("q")
            } label: {
                Image(systemName: "ellipsis")
                    .frame(width: 28, height: 28)
            }
            .menuStyle(.button)
            .buttonStyle(.borderless)
            .menuIndicator(.hidden)
            .fixedSize()
            .help("Mais opções")
        }
        .frame(minHeight: 30)
    }

    private func detalhes(de arquivo: ArquivoAudio) -> String {
        var partes: [String] = []
        if let duracao = arquivo.duracao { partes.append(FormatosAudio.formatar(duracao: duracao)) }
        switch estado.fase {
        case .trabalhando(let trabalho):
            partes.append(trabalho.motor.nome)
        case .pronto(let transcricao):
            if let data = transcricao.doHistorico {
                partes.append(Historico.quando(data))
            } else {
                partes.append("transcrito em \(Self.segundos(transcricao.segundos))")
            }
            partes.append(transcricao.motor.nome)
        default:
            if let tamanho = arquivo.tamanho {
                partes.append(ByteCountFormatter.string(fromByteCount: tamanho, countStyle: .file))
            }
        }
        return partes.joined(separator: " · ")
    }

    static func segundos(_ valor: TimeInterval) -> String {
        if valor >= 60 { return FormatosAudio.formatar(duracao: valor) }
        let numero = valor.formatted(.number.precision(.fractionLength(1)).locale(Locale(identifier: "pt_BR")))
        return "\(numero) s"
    }

    // MARK: Área de arrastar

    private var soltarPorCima: some View {
        VStack(spacing: 8) {
            Image(systemName: "tray.and.arrow.down").font(.system(size: 24))
            Text("Solte para transcrever").font(.system(size: 15, weight: .semibold))
        }
        .foregroundStyle(Color.accentColor)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.accentColor, style: StrokeStyle(lineWidth: 2, dash: [6, 5])))
        .padding(6)
        .allowsHitTesting(false)
    }

    private var areaDeArraste: some View {
        Button(action: escolherArquivo) {
            VStack(spacing: 12) {
                Image(systemName: "tray.and.arrow.down")
                    .font(.system(size: 26))
                    .frame(width: 60, height: 60)
                    .foregroundStyle(arrastando ? Color.white : Color.secondary)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(arrastando ? Color.accentColor : Color.primary.opacity(0.08)))
                VStack(spacing: 4) {
                    Text(arrastando ? "Solte para transcrever" : "Arraste um áudio aqui")
                        .font(.system(size: 17, weight: .semibold))
                    Text("ou clique para escolher um arquivo")
                        .font(.system(size: 12.5))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 188)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(arrastando ? Color.accentColor.opacity(0.10) : Color.primary.opacity(0.03)))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(
                        arrastando ? Color.accentColor : Color.primary.opacity(0.22),
                        style: StrokeStyle(lineWidth: 2, dash: [6, 5])))
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.15), value: arrastando)
    }

    // MARK: Rodapé: modelo e idioma

    private var rodape: some View {
        HStack(spacing: 8) {
            Menu {
                ForEach(ModeloTranscricao.allCases) { opcao in
                    Toggle(isOn: Binding(get: { modelo == opcao }, set: { if $0 { modelo = opcao } })) {
                        Text(opcao.nome)
                        Text(opcao.descricao)
                    }
                    .disabled(!opcao.disponivel)
                }
            } label: {
                Label(modelo.rotuloCurto, systemImage: modelo.simbolo)
            }
            .fixedSize()
            .help("Modelo de transcrição: \(modelo.nome)")

            Menu {
                Picker("Idioma do áudio", selection: $idioma) {
                    ForEach(IdiomaAudio.allCases) { Text($0.nome).tag($0) }
                }
                .pickerStyle(.inline)
            } label: {
                Label(idioma.nome, systemImage: "globe")
            }
            .fixedSize()
            .help("Idioma do áudio")

            Spacer(minLength: 0)
        }
        .controlSize(.small)
    }
}

// MARK: - Transcrevendo

private struct Andamento: View {
    let trabalho: EstadoApp.Trabalho
    let cancelar: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 7) {
                HStack(alignment: .firstTextBaseline) {
                    Text(titulo).font(.system(size: 12.5, weight: .medium))
                    Spacer()
                    if let fracao {
                        Text("\(Int(fracao * 100))%")
                            .font(.system(size: 12.5))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
                if let fracao {
                    // Barra própria (como no mockup): a nativa anima atrasada em relação ao número.
                    GeometryReader { area in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.primary.opacity(0.1))
                            Capsule().fill(Color.accentColor)
                                .frame(width: max(6, area.size.width * min(1, fracao)))
                        }
                    }
                    .frame(height: 6)
                } else {
                    ProgressView().progressViewStyle(.linear)
                }
            }

            if !trabalho.previa.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("PRÉVIA AO VIVO")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(0.6)
                        .foregroundStyle(.secondary)
                    ForEach(trabalho.previa.suffix(4), id: \.self) { frase in
                        Text(frase.texto)
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                // Ancorada no fim: a frase mais nova sempre aparece inteira; as antigas saem por cima.
                .frame(height: 150, alignment: .bottom)
                .clipped()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.primary.opacity(0.05)))
            }

            HStack(spacing: 10) {
                Text("Pode fechar o painel: o progresso fica no ícone da barra.")
                    .font(.system(size: 11.5))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                Button("Cancelar", action: cancelar)
                    .controlSize(.small)
            }
        }
    }

    private var titulo: String {
        switch trabalho.etapa {
        case .convertendo: "Convertendo o áudio…"
        case .preparandoModelo:
            trabalho.baixando != nil ? "Baixando o \(trabalho.motor.nome) (uma vez só)…" : "Preparando o \(trabalho.motor.nome)…"
        case .transcrevendo: "Transcrevendo…"
        }
    }

    private var fracao: Double? {
        if let baixando = trabalho.baixando { return baixando }
        if case .transcrevendo(let fracao) = trabalho.etapa { return fracao }
        return nil
    }
}

// MARK: - Transcrição pronta

private struct Resultado: View {
    let transcricao: EstadoApp.Transcricao
    let nota: String?
    let novo: () -> Void
    @State private var copiadoAgora = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if transcricao.paragrafos.isEmpty {
                Label("Não encontrei fala nesse áudio.", systemImage: "waveform.slash")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.primary.opacity(0.05)))
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(Array(transcricao.paragrafos.enumerated()), id: \.offset) { _, paragrafo in
                            HStack(alignment: .firstTextBaseline, spacing: 10) {
                                Text(FormatosAudio.formatar(duracao: paragrafo.inicio))
                                    .font(.system(size: 11.5))
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                                    .frame(width: 38, alignment: .leading)
                                Text(paragrafo.texto)
                                    .font(.system(size: 13.5))
                                    .lineSpacing(2)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .textSelection(.enabled)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 312)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.primary.opacity(0.05)))
            }

            if let nota {
                Label(nota, systemImage: "arrow.down.circle")
                    .font(.system(size: 11.5))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack {
                Button(action: novo) {
                    Label("Novo", systemImage: "arrow.uturn.backward")
                }
                .buttonStyle(.borderless)
                Spacer()
                if !transcricao.paragrafos.isEmpty {
                    Button {
                        EstadoApp.copiarTexto(transcricao.paragrafos)
                        copiadoAgora = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { copiadoAgora = false }
                    } label: {
                        if copiadoAgora || transcricao.copiado {
                            Label("Copiado", systemImage: "checkmark")
                        } else {
                            Label("Copiar tudo", systemImage: "doc.on.doc")
                        }
                    }
                    .controlSize(.small)
                    .help(transcricao.copiado ? "O texto já está na área de transferência; clique para copiar de novo" : "Copiar o texto inteiro")
                }
            }
        }
    }
}

// MARK: - Erro

private struct Falha: View {
    let mensagem: String
    let tentarDeNovo: () -> Void
    let novo: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(mensagem, systemImage: "exclamationmark.triangle.fill")
                .font(.system(size: 13))
                .symbolRenderingMode(.multicolor)
                .fixedSize(horizontal: false, vertical: true)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.primary.opacity(0.05)))
            HStack {
                Button(action: novo) {
                    Label("Novo", systemImage: "arrow.uturn.backward")
                }
                .buttonStyle(.borderless)
                Spacer()
                Button("Tentar de novo", action: tentarDeNovo)
                    .controlSize(.small)
            }
        }
    }
}

// MARK: - Histórico

private struct Recentes: View {
    let itens: [Historico.Resumo]
    let total: Int
    let abrir: (Historico.Resumo) -> Void
    let copiar: (Historico.Resumo) -> Bool
    let apagar: (Historico.Resumo) -> Void
    let verTudo: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text("RECENTES")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.6)
                    .foregroundStyle(.secondary)
                Spacer()
                Button(total > itens.count ? "Ver tudo (\(total))" : "Ver tudo", action: verTudo)
                    .buttonStyle(.borderless)
                    .font(.system(size: 11.5))
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 4)
            ForEach(itens) { LinhaDoHistorico(resumo: $0, abrir: abrir, copiar: copiar, apagar: apagar) }
        }
        .padding(.top, 2)
    }
}

private struct ListaDoHistorico: View {
    let historico: Historico
    let abrir: (Historico.Resumo) -> Void
    let copiar: (Historico.Resumo) -> Bool
    let voltar: () -> Void
    @State private var busca = ""

    var body: some View {
        let lista = historico.filtrar(busca)
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Button(action: voltar) {
                    Label("Voltar", systemImage: "chevron.left")
                }
                .buttonStyle(.borderless)
                Spacer()
                Text(historico.itens.count == 1 ? "1 transcrição" : "\(historico.itens.count) transcrições")
                    .font(.system(size: 11.5))
                    .foregroundStyle(.secondary)
            }
            TextField("Buscar no histórico", text: $busca)
                .textFieldStyle(.roundedBorder)
            if lista.isEmpty {
                Text(busca.isEmpty ? "Nenhuma transcrição ainda." : "Nada encontrado.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 24)
                    .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(lista) { resumo in
                            LinhaDoHistorico(
                                resumo: resumo, abrir: abrir, copiar: copiar,
                                apagar: { historico.apagar($0.id) })
                        }
                    }
                }
                .frame(maxHeight: 360)
            }
            Text(historico.soNaSessao
                 ? "Guardado só neste Mac, até desligar ou reiniciar. Para mudar: … › Ajustes."
                 : "Guardado só neste Mac. Para desligar ou limpar: … › Ajustes.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
    }
}

/// Uma transcrição guardada: clique abre; o botão copia o texto; ao passar o mouse aparece a lixeira;
/// o menu de contexto tem o resto.
private struct LinhaDoHistorico: View {
    let resumo: Historico.Resumo
    let abrir: (Historico.Resumo) -> Void
    let copiar: (Historico.Resumo) -> Bool
    var apagar: ((Historico.Resumo) -> Void)? = nil
    @State private var sobre = false
    @State private var copiado = false

    var body: some View {
        HStack(spacing: 4) {
            Button { abrir(resumo) } label: {
                HStack(spacing: 10) {
                    Image(systemName: "waveform")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .frame(width: 28, height: 28)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(0.08)))
                    VStack(alignment: .leading, spacing: 1) {
                        Text(resumo.nome)
                            .font(.system(size: 13))
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Text(meta)
                            .font(.system(size: 11.5))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                            .lineLimit(1)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.leading, 8)
                .padding(.vertical, 6)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if let apagar {
                // Só aparece com o mouse em cima da linha; o espaço fica reservado para nada pular de lugar.
                Button { apagar(resumo) } label: {
                    Image(systemName: "trash")
                        .frame(width: 28, height: 30)
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)
                .help("Apagar do histórico")
                .opacity(sobre ? 1 : 0)
                .allowsHitTesting(sobre)
            }

            Button {
                if copiar(resumo) {
                    copiado = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { copiado = false }
                }
            } label: {
                Image(systemName: copiado ? "checkmark" : "doc.on.doc")
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
            .help("Copiar a transcrição")
        }
        .padding(.trailing, 4)
        .background(RoundedRectangle(cornerRadius: 10).fill(sobre ? Color.primary.opacity(0.07) : Color.clear))
        .onHover { sobre = $0 }
        .contextMenu {
            Button("Abrir") { abrir(resumo) }
            Button("Copiar o texto") { _ = copiar(resumo) }
            if FileManager.default.fileExists(atPath: resumo.caminho) {
                Button("Mostrar o áudio no Finder") {
                    NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: resumo.caminho)])
                }
            }
            if let apagar {
                Divider()
                Button("Apagar do histórico", role: .destructive) { apagar(resumo) }
            }
        }
    }

    private var meta: String {
        var partes = [Historico.quando(resumo.data)]
        if let duracao = resumo.duracao { partes.append(FormatosAudio.formatar(duracao: duracao)) }
        return partes.joined(separator: " · ")
    }
}
