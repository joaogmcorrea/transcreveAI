import Combine
import Sparkle
import SwiftUI
import TranscreveMotores

/// Ajustes (… › Ajustes…): as opções do app num lugar só. O "…" do painel continua com os atalhos rápidos.
/// A janela tem tamanho fixo: deixar o tamanho seguir o conteúdo (`preferredContentSize`) com um Form
/// agrupado criava um ciclo de layout que derrubava o app (bug da v0.4).
struct AjustesView: View {
    let historico: Historico

    @AppStorage(Preferencia.modelo) private var modelo: ModeloTranscricao = .automatico
    @AppStorage(Preferencia.idioma) private var idioma: IdiomaAudio = .auto
    @AppStorage(Preferencia.copiarAoTerminar) private var copiarAoTerminar = true
    @AppStorage(Preferencia.somAoTerminar) private var somAoTerminar = true
    @AppStorage(Preferencia.abrirAoArrastar) private var abrirAoArrastar = true
    @AppStorage(Preferencia.guardarHistorico) private var guardarHistorico = true
    @AppStorage(Preferencia.historicoSoNaSessao) private var soNaSessao = true
    @State private var abrirAoIniciar = InicioAutomatico.ativo
    @State private var automatico = Atualizacoes.atualizador.automaticallyChecksForUpdates
    @State private var podeProcurar = false
    @State private var confirmarLimpeza = false
    @State private var parakeet: String = "…"

    static let tamanho = NSSize(width: 480, height: 660)

    var body: some View {
        Form {
            Section("Geral") {
                Toggle("Abrir ao iniciar o Mac", isOn: Binding(
                    get: { abrirAoIniciar },
                    set: { InicioAutomatico.definir($0); abrirAoIniciar = InicioAutomatico.ativo }))
                Toggle("Abrir o painel ao arrastar um áudio", isOn: $abrirAoArrastar)
                Toggle("Copiar o texto ao terminar", isOn: $copiarAoTerminar)
                Toggle("Tocar um som ao terminar", isOn: $somAoTerminar)
            }

            Section("Transcrição") {
                Picker("Modelo", selection: $modelo) {
                    ForEach(ModeloTranscricao.allCases.filter(\.disponivel)) { Text($0.nome).tag($0) }
                }
                Picker("Idioma do áudio", selection: $idioma) {
                    ForEach(IdiomaAudio.allCases) { Text($0.nome).tag($0) }
                }
                LabeledContent("Parakeet v3") { Text(parakeet).foregroundStyle(.secondary) }
                LabeledContent("Apple Speech") { Text("Já vem no macOS").foregroundStyle(.secondary) }
            }

            Section("Histórico") {
                Toggle("Guardar as transcrições neste Mac", isOn: $guardarHistorico)
                Toggle("Apagar ao desligar ou reiniciar o Mac", isOn: $soNaSessao)
                    .disabled(!guardarHistorico)
                HStack {
                    Text(contagem).foregroundStyle(.secondary)
                    Spacer()
                    Button("Mostrar no Finder") {
                        NSWorkspace.shared.activateFileViewerSelecting([historico.pasta])
                    }
                    Button("Limpar histórico…", role: .destructive) { confirmarLimpeza = true }
                        .disabled(historico.itens.isEmpty)
                }
            }

            Section("Atualizações") {
                Toggle("Procurar atualizações automaticamente", isOn: Binding(
                    get: { automatico },
                    set: { automatico = $0; Atualizacoes.atualizador.automaticallyChecksForUpdates = $0 }))
                    .disabled(!Atualizacoes.ativo)
                HStack {
                    Text("Versão \(versao)").foregroundStyle(.secondary)
                    Spacer()
                    Button("Procurar agora") { Atualizacoes.atualizador.checkForUpdates() }
                        .disabled(!podeProcurar)
                }
                if !Atualizacoes.ativo {
                    Text("Desligado nos builds de teste (debug).")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: Self.tamanho.width, height: Self.tamanho.height)
        .confirmationDialog("Apagar todo o histórico?", isPresented: $confirmarLimpeza) {
            Button(historico.itens.count == 1 ? "Apagar 1 transcrição" : "Apagar \(historico.itens.count) transcrições",
                   role: .destructive) { historico.limpar() }
        } message: {
            Text("As transcrições somem deste Mac. Os áudios originais não são tocados.")
        }
        .onReceive(Atualizacoes.atualizador.publisher(for: \.canCheckForUpdates)) { podeProcurar = $0 }
        .task {
            let motor = MotorParakeet.compartilhado
            let pronto = await motor.pronto
            let baixado = await motor.baixado
            parakeet = pronto ? "Carregado e pronto" : baixado ? "Baixado (~470 MB)" : "Baixa sozinho na primeira transcrição"
        }
    }

    private var contagem: String {
        switch historico.itens.count {
        case 0: "Nenhuma transcrição guardada"
        case 1: "1 transcrição guardada"
        default: "\(historico.itens.count) transcrições guardadas"
        }
    }

    private var versao: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }
}
