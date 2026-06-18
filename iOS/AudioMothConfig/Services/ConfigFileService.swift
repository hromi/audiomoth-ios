import Foundation
import UniformTypeIdentifiers

extension UTType {
    static let audiomothConfig = UTType(exportedAs: "info.openacousticdevices.audiomoth-config")
}

struct ConfigFileService {

    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }()

    private static let decoder = JSONDecoder()

    static func encode(_ config: AudioMothConfiguration) throws -> Data {
        try encoder.encode(config)
    }

    static func decode(from data: Data) throws -> AudioMothConfiguration {
        try decoder.decode(AudioMothConfiguration.self, from: data)
    }

    // MARK: - Human-readable export matching desktop app format

    struct ExportFormat: Codable {
        var timePeriods: [[String: Int]]
        var sampleRate: Int
        var gain: Int
        var recordDuration: Int
        var sleepDuration: Int
        var ledEnabled: Bool
        var batteryLevelCheckEnabled: Bool
        var passFiltersEnabled: Bool
        var filterType: String
        var lowerFilter: Int
        var higherFilter: Int
        var amplitudeThresholdingEnabled: Bool
        var frequencyTriggerEnabled: Bool
        var energySaverModeEnabled: Bool
        var disable48DCFilter: Bool
        var lowGainRangeEnabled: Bool
        var magneticSwitchEnabled: Bool
        var sunScheduleEnabled: Bool
    }

    static func toExportFormat(_ config: AudioMothConfiguration) -> ExportFormat {
        ExportFormat(
            timePeriods: config.timePeriods.map { ["startMins": $0.startMins, "endMins": $0.endMins] },
            sampleRate: AudioMothConstants.configurations[config.sampleRateIndex].trueSampleRate * 1000,
            gain: config.gain,
            recordDuration: config.recordDuration,
            sleepDuration: config.sleepDuration,
            ledEnabled: config.ledEnabled,
            batteryLevelCheckEnabled: config.batteryLevelCheckEnabled,
            passFiltersEnabled: config.passFiltersEnabled,
            filterType: config.filterType.rawValue,
            lowerFilter: config.lowerFilterHz,
            higherFilter: config.higherFilterHz,
            amplitudeThresholdingEnabled: config.amplitudeThresholdingEnabled,
            frequencyTriggerEnabled: config.frequencyTriggerEnabled,
            energySaverModeEnabled: config.energySaverModeEnabled,
            disable48DCFilter: config.disable48DCFilter,
            lowGainRangeEnabled: config.lowGainRangeEnabled,
            magneticSwitchEnabled: config.magneticSwitchEnabled,
            sunScheduleEnabled: config.sunScheduleEnabled
        )
    }
}
