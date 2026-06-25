import Foundation
import Combine
import UIKit

@Observable
final class AppViewModel {

    var config = AudioMothConfiguration()
    var deviceState: DeviceState = .disconnected
    var isConfiguring = false
    var configureError: String?
    var configureSuccess = false
    var shareURL: URL?

    private let deviceService: any DeviceServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    init(deviceService: (any DeviceServiceProtocol)? = nil) {
        self.deviceService = deviceService ?? MockDeviceService()
        self.deviceService.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in self?.deviceState = state }
            .store(in: &cancellables)
    }

    var connectedDevice: DeviceInfo? {
        if case .connected(let info) = deviceState { return info }
        return nil
    }

    var firmwareVersion: (Int, Int, Int) {
        connectedDevice?.firmwareVersion ?? AudioMothConstants.latestFirmware
    }

    var estimatedBatteryHours: Double {
        PacketBuilder.estimatedHours(config: config)
    }

    // MARK: - Device lifecycle

    func startMonitoring() {
        deviceService.startMonitoring()
    }

    func stopMonitoring() {
        deviceService.stopMonitoring()
    }

    // MARK: - Configure device

    @MainActor
    func configure() async {
        guard !isConfiguring else { return }
        isConfiguring = true
        configureError = nil
        configureSuccess = false
        do {
            try await deviceService.sendConfiguration(config)
            configureSuccess = true
        } catch {
            configureError = error.localizedDescription
        }
        isConfiguring = false
    }

    // MARK: - Copy device ID

    func copyDeviceID() {
        if let id = deviceService.copyDeviceID() {
            UIPasteboard.general.string = id
        }
    }

    // MARK: - File export/import

    func prepareShare() {
        let text = ConfigFileService.toConfigText(config, deviceInfo: connectedDevice)
        guard let data = text.data(using: .utf8) else { return }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("AudioMoth_Config.txt")
        guard (try? data.write(to: url)) != nil else { return }
        shareURL = url
    }

    func importConfig(from data: Data) {
        guard let loaded = try? ConfigFileService.decode(from: data) else { return }
        config = loaded
    }

    // MARK: - Schedule helpers

    func addTimePeriod() {
        guard config.timePeriods.count < AudioMothConstants.maxPeriods else { return }
        config.timePeriods.append(TimePeriod(startMins: 0, endMins: 1440))
    }

    func removeTimePeriod(at offsets: IndexSet) {
        config.timePeriods.remove(atOffsets: offsets)
    }

    // MARK: - Validation

    var isValid: Bool {
        guard config.sampleRateIndex >= 0 && config.sampleRateIndex < AudioMothConstants.configurations.count else { return false }
        guard config.gain >= 0 && config.gain <= 4 else { return false }
        guard config.recordDuration > 0 && config.recordDuration <= AudioMothConstants.maxRecordDuration else { return false }
        guard config.sleepDuration >= 0 && config.sleepDuration <= AudioMothConstants.maxSleepDuration else { return false }
        if config.passFiltersEnabled && !config.frequencyTriggerEnabled {
            if config.filterType == .band && config.lowerFilterHz >= config.higherFilterHz { return false }
        }
        return true
    }
}
