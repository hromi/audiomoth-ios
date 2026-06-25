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

    // MARK: - Human-readable text export matching desktop app CONFIG.TXT format

    static func toConfigText(_ config: AudioMothConfiguration, deviceInfo: DeviceInfo?) -> String {
        var lines: [String] = []

        func row(_ label: String, _ value: String) {
            lines.append(label.padding(toLength: 32, withPad: " ", startingAt: 0) + ": " + value)
        }

        let fw = deviceInfo.map { "\($0.firmwareDescription) (\($0.firmwareVersion.0).\($0.firmwareVersion.1).\($0.firmwareVersion.2))" }
            ?? "AudioMoth-Firmware-Basic (\(AudioMothConstants.latestFirmware.major).\(AudioMothConstants.latestFirmware.minor).\(AudioMothConstants.latestFirmware.patch))"

        let utcFormatter: DateFormatter = {
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd HH:mm:ss"
            f.timeZone = TimeZone(identifier: "UTC")
            return f
        }()
        let deviceTime = utcFormatter.string(from: deviceInfo?.deviceTime ?? Date()) + " (UTC)"

        row("Device ID", deviceInfo?.deviceID ?? "----------------")
        row("Firmware", fw)
        lines.append("")

        row("Device time", deviceTime)
        lines.append("")

        let gainNames = ["Low", "Low-Medium", "Medium", "Medium-High", "High"]
        row("Sample rate (Hz)", "\(config.sampleRateKHz * 1000)")
        row("Gain", config.gain < gainNames.count ? gainNames[config.gain] : "Medium")
        lines.append("")

        row("Sleep duration (s)", config.dutyEnabled ? "\(config.sleepDuration)" : "-")
        row("Recording duration (s)", config.dutyEnabled ? "\(config.recordDuration)" : "-")
        lines.append("")

        row("Active recording periods", "\(config.timePeriods.count)")
        lines.append("")

        for (i, period) in config.timePeriods.enumerated() {
            row("Recording period \(i + 1)", "\(period.startTime) - \(period.endTime) (UTC)")
            lines.append("")
        }

        row("First recording date", config.firstRecordingDateEnabled ? config.firstRecordingDate : "----------")
        row("Last recording date", config.lastRecordingDateEnabled ? config.lastRecordingDate : "----------")
        lines.append("")

        let filterStr: String
        if config.passFiltersEnabled && !config.frequencyTriggerEnabled && config.filterType != .none {
            switch config.filterType {
            case .low:  filterStr = "Low-pass (\(config.higherFilterHz) Hz)"
            case .high: filterStr = "High-pass (\(config.lowerFilterHz) Hz)"
            case .band: filterStr = "Band-pass (\(config.lowerFilterHz) Hz - \(config.higherFilterHz) Hz)"
            case .none: filterStr = "-"
            }
        } else {
            filterStr = "-"
        }
        row("Filter", filterStr)
        lines.append("")

        let triggerType: String
        let thresholdSetting: String
        let minTriggerDuration: String

        if config.amplitudeThresholdingEnabled {
            triggerType = "Amplitude threshold"
            let durations = AudioMothConstants.minimumThresholdDurations
            let dur = config.minimumAmplitudeThresholdDurationIndex < durations.count ? durations[config.minimumAmplitudeThresholdDurationIndex] : 0
            minTriggerDuration = dur > 0 ? "\(dur)" : "-"
            switch config.amplitudeThresholdScale {
            case .percentage:
                let m = config.amplitudeThresholdPercentageMantissa
                let e = config.amplitudeThresholdPercentageExponent
                thresholdSetting = e == 0 ? "\(m)% (Percentage)" : "0.\(String(repeating: "0", count: e - 1))\(m)% (Percentage)"
            case .sixteenBit:
                thresholdSetting = "\(config.amplitudeThreshold16Bit) (16-bit)"
            case .decibel:
                thresholdSetting = "\(config.amplitudeThresholdDecibels) dB (Decibel)"
            }
        } else if config.frequencyTriggerEnabled {
            triggerType = "Frequency trigger"
            thresholdSetting = "-"
            let durations = AudioMothConstants.minimumThresholdDurations
            let dur = config.minimumFrequencyTriggerDurationIndex < durations.count ? durations[config.minimumFrequencyTriggerDurationIndex] : 0
            minTriggerDuration = dur > 0 ? "\(dur)" : "-"
        } else {
            triggerType = "-"
            thresholdSetting = "-"
            minTriggerDuration = "-"
        }

        row("Trigger type", triggerType)
        row("Threshold setting", thresholdSetting)
        row("Minimum trigger duration (s)", minTriggerDuration)
        lines.append("")

        row("Enable LED", config.ledEnabled ? "Yes" : "No")
        row("Enable low-voltage cut-off", config.batteryLevelCheckEnabled ? "Yes" : "No")
        row("Enable battery level indication", config.batteryLevelCheckEnabled ? "Yes" : "No")
        lines.append("")

        row("Always require acoustic chime", config.requireAcousticConfig ? "Yes" : "No")
        row("Also require location in chime", config.requireAcousticConfig ? (config.requireLocationInChime ? "Yes" : "No") : "-")
        row("Use timezone from chime", config.useTimezoneInChime ? "Yes" : "No")
        row("Also adjust recording schedule", config.useTimezoneInChime ? (config.adjustScheduleFromAcousticChime ? "Yes" : "No") : "-")
        lines.append("")

        row("Recording preparation time (s)", "\(config.prerecordingPrepTime)")
        row("Use device ID in WAV file name", config.filenameWithDeviceIDEnabled ? "Yes" : "No")
        row("Use daily folder for WAV files", config.dailyFolders ? "Yes" : "No")
        lines.append("")

        row("Disable 48Hz DC blocking filter", config.disable48DCFilter ? "Yes" : "No")
        row("Enable energy saver mode", config.energySaverModeEnabled ? "Yes" : "No")
        row("Enable low gain range", config.lowGainRangeEnabled ? "Yes" : "No")
        lines.append("")

        row("Ignore external microphone", config.ignoreExternalMicForAcousticChime ? "Yes" : "No")
        lines.append("")

        row("Enable magnetic switch", config.magneticSwitchEnabled ? "Yes" : "No")
        lines.append("")

        row("Enable GPS time setting", config.timeSettingFromGPSEnabled ? "Yes" : "No")
        row("GPS fix before and after", config.timeSettingFromGPSEnabled ? config.acquireGPSFixMode.displayName : "-")
        row("GPS fix time (mins)", config.timeSettingFromGPSEnabled ? "\(config.gpsFixTime)" : "-")
        lines.append("")

        return lines.joined(separator: "\n")
    }
}
