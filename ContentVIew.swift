import SwiftUI
import WireGuardKit

struct ContentView: View {
    @State private var isConnected = false
    @State private var configuration: String = "" // WireGuard конфигурация в формате string
    @State private var errorMessage: String? = nil

    private var tunnelName = "MyTunnel"
    private let tunnelManager = WireGuardKit.TunnelManager()

    var body: some View {
        VStack(spacing: 20) {
            Text("WireGuard VPN")
                .font(.largeTitle)
                .padding()

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }

            TextEditor(text: $configuration)
                .frame(height: 200)
                .border(Color.gray, width: 1)
                .padding()
                .disabled(isConnected)

            Button(action: {
                if isConnected {
                    disconnect()
                } else {
                    connect()
                }
            }) {
                Text(isConnected ? "Disconnect" : "Connect")
                    .font(.title2)
                    .padding()
                    .foregroundColor(.white)
                    .background(isConnected ? Color.red : Color.blue)
                    .cornerRadius(8)
            }
        }
        .padding()
        .onAppear {
            setupTunnelManager()
        }
    }

    private func setupTunnelManager() {
        tunnelManager.delegate = self
    }

    private func connect() {
        guard let tunnelConfig = try? TunnelConfiguration(fromWgQuickConfig: configuration) else {
            errorMessage = "Invalid configuration."
            return
        }

        do {
            try tunnelManager.addOrUpdate(tunnelName: tunnelName, configuration: tunnelConfig)
            tunnelManager.start(tunnelName: tunnelName) { result in
                switch result {
                case .success:
                    isConnected = true
                    errorMessage = nil
                case .failure(let error):
                    errorMessage = "Failed to connect: \(error.localizedDescription)"
                }
            }
        } catch {
            errorMessage = "Failed to add or update tunnel: \(error.localizedDescription)"
        }
    }

    private func disconnect() {
        tunnelManager.stop(tunnelName: tunnelName) { result in
            switch result {
            case .success:
                isConnected = false
                errorMessage = nil
            case .failure(let error):
                errorMessage = "Failed to disconnect: \(error.localizedDescription)"
            }
        }
    }
}

extension ContentView: TunnelManagerDelegate {
    func tunnelManager(_ manager: WireGuardKit.TunnelManager, didUpdate tunnel: WireGuardKit.TunnelStatus) {
        print("Tunnel status updated: \(tunnel)")
    }
}
