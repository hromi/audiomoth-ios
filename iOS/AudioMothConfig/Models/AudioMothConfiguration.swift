import Foundation

enum FilterType: String, Codable, CaseIterable {
    case none = "none"
    case low = "low"
    case high = "high"
    case band = "band"

    var displayName: String {
        switch self {
        case .none: return "None"
        case .low:  return "Low-pass"
        case .high: return "High-pass"
        case .band: return "Band-pass"
        }
    }
}

enum ThresholdScale: Int, Codable, CaseIterable {
    case percentage = 0
    case sixteenBit = 1
    case decibel    = 2

    var displayName: String {
        switch self {
        case .percentage: return "Percentage"
        case .sixteenBit: return "16-bit"
        case .decibel:    return "Decibel"
        }
    }
}

enum SunMode: Int, Codable, CaseIterable {
    case beforeAfterSunrise  = 0
    case beforeAfterSunset   = 1
    case beforeAfterBoth     = 2
    case sunsetToSunrise     = 3
    case sunriseToSunset     = 4

    var displayName: String {
        switch self {
        case .beforeAfterSunrise: return "Around sunrise"
        case .beforeAfterSunset:  return "Around sunset"
        case .beforeAfterBoth:    return "Around both"
        case .sunsetToSunrise:    return "Sunset to sunrise"
        case .sunriseToSunset:    return "Sunrise to sunset"
        }
    }
}

enum SunDefinition: Int, Codable, CaseIterable {
    case sunriseAndSunset     = 0
    case civilDawnAndDusk     = 1
    case nauticalDawnAndDusk  = 2
    case astronomicalDawnAndDusk = 3

    var displayName: String {
        switch self {
        case .sunriseAndSunset:         return "Sunrise / Sunset"
        case .civilDawnAndDusk:         return "Civil dawn / dusk"
        case .nauticalDawnAndDusk:      return "Nautical dawn / dusk"
        case .astronomicalDawnAndDusk:  return "Astronomical dawn / dusk"
        }
    }
}

enum GPSAcquireMode: String, Codable, CaseIterable {
    case period     = "period"
    case individual = "individual"

    var displayName: String {
        switch self {
        case .period:     return "Each recording period"
        case .individual: return "Each individual recording"
        }
    }
}

struct Coordinate: Codable, Equatable {
    var degrees: Int = 0
    var hundredths: Int = 0
    var isPositive: Bool = true

    var decimalDegrees: Double {
        let abs = Double(degrees) + Double(hundredths) / 100.0
        return isPositive ? abs : -abs
    }

    init(decimal: Double) {
        isPositive = decimal >= 0
        let abs = Swift.abs(decimal)
        degrees = Int(abs)
        hundredths = Int((abs - Double(degrees)) * 100)
    }

    init(degrees: Int = 0, hundredths: Int = 0, isPositive: Bool = true) {
        self.degrees = degrees
        self.hundredths = hundredths
        self.isPositive = isPositive
    }
}

struct TimePeriod: Codable, Identifiable, Equatable {
    var id = UUID()
    var startMins: Int  // minutes since midnight
    var endMins: Int    // minutes since midnight (0 = midnight/end of day)

    enum CodingKeys: String, CodingKey {
        case startMins, endMins
    }

    var startTime: String {
        String(format: "%02d:%02d", startMins / 60, startMins % 60)
    }

    var endTime: String {
        let e = endMins == 0 ? 1440 : endMins
        return String(format: "%02d:%02d", e / 60, e % 60)
    }
}

struct SunPeriods: Codable {
    var sunriseBefore: Int = 60
    var sunriseAfter: Int  = 60
    var sunsetBefore: Int  = 60
    var sunsetAfter: Int   = 60
}

struct AudioMothConfiguration: Codable {

    // Recording
    var sampleRateIndex: Int = 3        // 48 kHz default
    var gain: Int = 2
    var recordDuration: Int = 55
    var sleepDuration: Int = 5
    var ledEnabled: Bool = true
    var batteryLevelCheckEnabled: Bool = true

    // Schedule
    var timePeriods: [TimePeriod] = [TimePeriod(startMins: 360, endMins: 1320)]
    var sunScheduleEnabled: Bool = false
    var latitude: Coordinate = Coordinate()
    var longitude: Coordinate = Coordinate()
    var sunMode: SunMode = .beforeAfterSunrise
    var sunDefinition: SunDefinition = .sunriseAndSunset
    var sunPeriods: SunPeriods = SunPeriods()
    var sunRounding: Int = 0            // minutes rounding
    var firstRecordingDateEnabled: Bool = false
    var firstRecordingDate: String = "2024-01-01"
    var lastRecordingDateEnabled: Bool = false
    var lastRecordingDate: String = "2024-12-31"

    // Timezone
    var timezoneMode: Int = 0           // 0=UTC, 1=local, 2=custom
    var customTimezoneOffsetMinutes: Int = 0

    // Filtering
    var passFiltersEnabled: Bool = false
    var filterType: FilterType = .none
    var lowerFilterHz: Int = 1000
    var higherFilterHz: Int = 20000
    var amplitudeThresholdingEnabled: Bool = false
    var amplitudeThresholdScale: ThresholdScale = .percentage
    var amplitudeThresholdPercentageMantissa: Int = 1   // 1-9
    var amplitudeThresholdPercentageExponent: Int = 0   // stored as 0=0, 1=-1, 2=-2, 3=-3, 4=-4
    var amplitudeThreshold16Bit: Int = 100
    var amplitudeThresholdDecibels: Int = -20           // -100 to 0
    var frequencyTriggerEnabled: Bool = false
    var frequencyTriggerWindowLengthIndex: Int = 2      // index into [16,32,64,128,256,512,1024,2048]
    var frequencyTriggerCentreFrequencyHz: Int = 2000
    var frequencyTriggerThresholdMantissa: Int = 1
    var frequencyTriggerThresholdExponent: Int = 0
    var minimumAmplitudeThresholdDurationIndex: Int = 0
    var minimumFrequencyTriggerDurationIndex: Int = 0

    // Advanced
    var dutyEnabled: Bool = false
    var filenameWithDeviceIDEnabled: Bool = false
    var energySaverModeEnabled: Bool = false
    var disable48DCFilter: Bool = false
    var lowGainRangeEnabled: Bool = false
    var magneticSwitchEnabled: Bool = false
    var displayVoltageRange: Bool = false
    var dailyFolders: Bool = false

    // Add-ons / GPS
    var timeSettingFromGPSEnabled: Bool = false
    var gpsFixTime: Int = 1             // minutes
    var acquireGPSFixMode: GPSAcquireMode = .period
    var requireAcousticConfig: Bool = false
    var requireLocationInChime: Bool = false
    var useTimezoneInChime: Bool = false
    var adjustScheduleFromAcousticChime: Bool = false
    var ignoreExternalMicForAcousticChime: Bool = false
    var prerecordingPrepTime: Int = 0   // seconds 0-15

    // Computed helpers
    var sampleRateKHz: Int {
        AudioMothConstants.configurations[sampleRateIndex].trueSampleRate
    }

    var timezoneOffsetMinutes: Int {
        switch timezoneMode {
        case 1:  return TimeZone.current.secondsFromGMT() / 60
        case 2:  return customTimezoneOffsetMinutes
        default: return 0
        }
    }

    mutating func sortTimePeriods() {
        timePeriods.sort { $0.startMins < $1.startMins }
    }
}
