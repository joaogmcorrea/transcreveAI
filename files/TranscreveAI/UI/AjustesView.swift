import Combine
import Sparkle
import SwiftUI

/// Ajustes (… › Ajustes…). Por enquanto só as atualizações: o ajuste do próprio Sparkle e "Procurar agora",
/// os dois desligados nos builds de debug, em que o atualizador não roda.
struct AjustesView: View {
    @State private var automatico = Atualizacoes.atualizador.automaticallyChecksForUpdates
    @State private var podeProcurar = false

    var body: some View {
        Form {
            Section("Atualizações") {
                Toggle("Procurar atualizações automaticamente", isOn: Binding(
                    get: { automatico },
                    set: { automatico = $0; Atualizacoes.atualizador.automaticallyChecksForUpdates = $0 }))
                    .disabled(!Atualizacoes.ativo)
                HStack {
                    Text("Versão \(versao)")
                        .foregroundStyle(.secondary)
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
        .frame(width: 420)
        .fixedSize(horizontal: false, vertical: true)
        .onReceive(Atualizacoes.atualizador.publisher(for: \.canCheckForUpdates)) { podeProcurar = $0 }
    }

    private var versao: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }
}
