import SwiftUI

struct DeviceInfoView: View {

    @Environment(AppViewModel.self) private var vm

    var body: some View {
        GroupBox {
            switch vm.deviceState {
            case .disconnected:
                Label("No AudioMoth connected", systemImage: "cable.connector.slash")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)

            case .connecting:
                Label("Connecting…", systemImage: "arrow.triangle.2.circlepath")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)

            case .connected(let info):
                connectedView(info)

            case .error(let msg):
                Label(msg, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
        }
    }

    private func connectedView(_ info: DeviceInfo) -> some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Circle().fill(.green).frame(width: 8, height: 8)
                    Text("AudioMoth").font(.headline)
                }
                Text(info.deviceID)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .onTapGesture { vm.copyDeviceID() }
                Text("Firmware \(info.firmwareVersion.0).\(info.firmwareVersion.1).\(info.firmwareVersion.2)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(info.firmwareDescription)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                if let t = info.deviceTime {
                    Text(t, format: .dateTime.hour().minute().second())
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.primary)
                }
                batteryView(voltage: info.batteryVoltage)
            }
        }
        .padding(.vertical, 2)
    }

    private func batteryView(voltage: Double) -> some View {
        HStack(spacing: 4) {
            Image(systemName: batteryIcon(voltage))
                .foregroundStyle(batteryColor(voltage))
            Text(String(format: "%.2f V", voltage))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func batteryIcon(_ v: Double) -> String {
        switch v {
        case 4.0...: return "battery.100"
        case 3.6..<4.0: return "battery.75"
        case 3.3..<3.6: return "battery.25"
        default: return "battery.0"
        }
    }

    private func batteryColor(_ v: Double) -> Color {
        switch v {
        case 3.5...: return .green
        case 3.3..<3.5: return .orange
        default: return .red
        }
    }
}
