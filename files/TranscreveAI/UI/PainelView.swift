import Combine
import SwiftUI

/// O painel da barra de menus (mockup, página "Menu bar"): arrastar, modelo, idioma e o menu "…".
struct PainelView: View {
    let estado: EstadoApp
    let escolherArquivo: () -> Void
    let procurarAtualizacoes: () -> Void
    let abrirAjustes: () -> Void
    let sair: () -> Void

    @AppStorage(Preferencia.modelo) private var modelo: ModeloTranscricao = .automatico
    @AppStorage(Preferencia.idioma) private var idioma: IdiomaAudio = .auto
    @AppStorage(Preferencia.copiarAoTerminar) private var copiarAoTerminar = true
    @AppStorage(Preferencia.abrirAoArrastar) private var abrirAoArrastar = true
    @State private var abrirAoIniciar = InicioAutomatico.ativo
    @State private var podeProcurar = false
    @State private var arrastando = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            cabecalho
            if let arquivo = estado.arquivo {
                ArquivoRecebido(arquivo: arquivo, modelo: modelo, novo: estado.limpar)
            } else {
                areaDeArraste
                rodape
                if let aviso = estado.aviso {
                    Label(aviso, systemImage: "exclamationmark.triangle")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
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
        if let tamanho = arquivo.tamanho {
            partes.append(ByteCountFormatter.string(fromByteCount: tamanho, countStyle: .file))
        }
        partes.append(modelo.motor)
        return partes.joined(separator: " · ")
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

/// O arquivo chegou. A transcrição entra na v0.4; por enquanto o painel confirma o recebimento.
private struct ArquivoRecebido: View {
    let arquivo: ArquivoAudio
    let modelo: ModeloTranscricao
    let novo: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.green)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Áudio recebido").font(.system(size: 13, weight: .medium))
                    Text("A transcrição com \(modelo.motor) chega na próxima etapa do app (v0.4).")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.primary.opacity(0.05)))

            HStack {
                Button(action: novo) {
                    Label("Novo", systemImage: "arrow.uturn.backward")
                }
                .buttonStyle(.borderless)
                Spacer()
                Button("Mostrar no Finder") {
                    NSWorkspace.shared.activateFileViewerSelecting([arquivo.url])
                }
                .controlSize(.small)
            }
        }
    }
}
