import Foundation

enum AudioMothConstants {

    struct SampleRateConfig {
        let trueSampleRate: Int     // kHz
        let clockDivider: Int
        let acquisitionCycles: Int
        let oversampleRate: Int
        let sampleRate: Int         // Hz
        let sampleRateDivider: Int
        let recordCurrentMA: Double
        let energySaverCurrentMA: Double
    }

    static let configurations: [SampleRateConfig] = [
        SampleRateConfig(trueSampleRate: 8,   clockDivider: 4, acquisitionCycles: 16, oversampleRate: 1, sampleRate: 384000, sampleRateDivider: 48, recordCurrentMA: 8.5,  energySaverCurrentMA: 5.5),
        SampleRateConfig(trueSampleRate: 16,  clockDivider: 4, acquisitionCycles: 16, oversampleRate: 1, sampleRate: 384000, sampleRateDivider: 24, recordCurrentMA: 9.0,  energySaverCurrentMA: 6.0),
        SampleRateConfig(trueSampleRate: 32,  clockDivider: 4, acquisitionCycles: 16, oversampleRate: 1, sampleRate: 384000, sampleRateDivider: 12, recordCurrentMA: 10.0, energySaverCurrentMA: 7.0),
        SampleRateConfig(trueSampleRate: 48,  clockDivider: 4, acquisitionCycles: 16, oversampleRate: 1, sampleRate: 384000, sampleRateDivider: 8,  recordCurrentMA: 10.5, energySaverCurrentMA: 7.5),
        SampleRateConfig(trueSampleRate: 96,  clockDivider: 4, acquisitionCycles: 16, oversampleRate: 1, sampleRate: 384000, sampleRateDivider: 4,  recordCurrentMA: 13.5, energySaverCurrentMA: 13.5),
        SampleRateConfig(trueSampleRate: 192, clockDivider: 4, acquisitionCycles: 16, oversampleRate: 1, sampleRate: 384000, sampleRateDivider: 2,  recordCurrentMA: 20.0, energySaverCurrentMA: 20.0),
        SampleRateConfig(trueSampleRate: 250, clockDivider: 4, acquisitionCycles: 16, oversampleRate: 1, sampleRate: 250000, sampleRateDivider: 1,  recordCurrentMA: 17.0, energySaverCurrentMA: 17.0),
        SampleRateConfig(trueSampleRate: 384, clockDivider: 4, acquisitionCycles: 16, oversampleRate: 1, sampleRate: 384000, sampleRateDivider: 1,  recordCurrentMA: 24.0, energySaverCurrentMA: 24.0),
    ]

    static let oldConfigurations: [SampleRateConfig] = [
        SampleRateConfig(trueSampleRate: 8,  clockDivider: 4, acquisitionCycles: 16, oversampleRate: 1, sampleRate: 128000, sampleRateDivider: 16, recordCurrentMA: 0, energySaverCurrentMA: 0),
        SampleRateConfig(trueSampleRate: 16, clockDivider: 4, acquisitionCycles: 16, oversampleRate: 1, sampleRate: 128000, sampleRateDivider: 8,  recordCurrentMA: 0, energySaverCurrentMA: 0),
        SampleRateConfig(trueSampleRate: 32, clockDivider: 4, acquisitionCycles: 16, oversampleRate: 1, sampleRate: 128000, sampleRateDivider: 4,  recordCurrentMA: 0, energySaverCurrentMA: 0),
    ]

    struct PacketLengthVersion {
        let firmwareVersion: (Int, Int, Int)
        let packetLength: Int
    }

    static let packetLengthVersions: [PacketLengthVersion] = [
        PacketLengthVersion(firmwareVersion: (0, 0, 0), packetLength: 39),
        PacketLengthVersion(firmwareVersion: (1, 2, 0), packetLength: 40),
        PacketLengthVersion(firmwareVersion: (1, 2, 1), packetLength: 42),
        PacketLengthVersion(firmwareVersion: (1, 2, 2), packetLength: 43),
        PacketLengthVersion(firmwareVersion: (1, 4, 0), packetLength: 58),
        PacketLengthVersion(firmwareVersion: (1, 5, 0), packetLength: 59),
        PacketLengthVersion(firmwareVersion: (1, 6, 0), packetLength: 62),
    ]

    static let maxPacketLength = 62

    static let latestFirmware = (major: 1, minor: 12, patch: 0)

    static let maxPeriods = 4
    static let minutesInDay = 1440
    static let minutesInHour = 60
    static let secondsInMinute = 60
    static let secondsInDay = 86400
    static let uint32Max: UInt32 = 0xFFFF_FFFF
    static let uint16Max = 0xFFFF

    static let maxSleepDuration = 43200
    static let maxRecordDuration = 43200
    static let minCustomTimezoneOffset = -720
    static let maxCustomTimezoneOffset = 840

    static let validGPSFixTimes = [1, 2, 5, 10, 15]
    static let frequencyTriggerWindowLengths = [16, 32, 64, 128, 256, 512, 1024, 2048]

    static let minimumThresholdDurations = [0, 1, 2, 5, 10, 15, 30, 60]

    static func compareVersion(_ v: (Int, Int, Int), _ major: Int, _ minor: Int, _ patch: Int) -> Int {
        let lhs = [v.0, v.1, v.2]
        let rhs = [major, minor, patch]
        for i in 0..<3 {
            if lhs[i] > rhs[i] { return 1 }
            if lhs[i] < rhs[i] { return -1 }
        }
        return 0
    }

    static func isOlderThan(_ v: (Int, Int, Int), _ major: Int, _ minor: Int, _ patch: Int) -> Bool {
        compareVersion(v, major, minor, patch) == -1
    }

    static func isNewerOrEqual(_ v: (Int, Int, Int), _ major: Int, _ minor: Int, _ patch: Int) -> Bool {
        compareVersion(v, major, minor, patch) >= 0
    }

    static func packetLength(for firmware: (Int, Int, Int)) -> Int {
        var length = packetLengthVersions[0].packetLength
        for entry in packetLengthVersions {
            let ev = entry.firmwareVersion
            if isOlderThan(firmware, ev.0, ev.1, ev.2) { break }
            length = entry.packetLength
        }
        return length
    }
}
