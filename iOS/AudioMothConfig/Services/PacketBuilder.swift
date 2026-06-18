import Foundation

struct PacketBuilder {

    static func build(config: AudioMothConfiguration, firmware: (Int, Int, Int) = AudioMothConstants.latestFirmware) -> (packet: Data, sendAt: Date) {

        let usbLag = 20
        let minimumDelay = 100

        var now = Date()
        var msUntilSecond = 1000 - Int(now.timeIntervalSince1970.truncatingRemainder(dividingBy: 1) * 1000)
        if msUntilSecond < minimumDelay { msUntilSecond += 1000 }
        let sendAt = now.addingTimeInterval(Double(msUntilSecond - usbLag) / 1000.0)

        var bytes = [UInt8](repeating: 0, count: AudioMothConstants.maxPacketLength)
        var idx = 0

        let timestamp = UInt32(sendAt.timeIntervalSince1970)
        writeLE(&bytes, at: &idx, bytes: 4, value: Int(timestamp))

        bytes[idx] = UInt8(config.gain); idx += 1

        let trueFW = firmware
        let useOldConfig = AudioMothConstants.isOlderThan(trueFW, 1, 4, 4) && config.sampleRateIndex < 3
        let srConfig = useOldConfig
            ? AudioMothConstants.oldConfigurations[config.sampleRateIndex]
            : AudioMothConstants.configurations[config.sampleRateIndex]

        bytes[idx] = UInt8(srConfig.clockDivider);     idx += 1
        bytes[idx] = UInt8(srConfig.acquisitionCycles); idx += 1
        bytes[idx] = UInt8(srConfig.oversampleRate);   idx += 1
        writeLE(&bytes, at: &idx, bytes: 4, value: srConfig.sampleRate)
        bytes[idx] = UInt8(srConfig.sampleRateDivider); idx += 1

        writeLE(&bytes, at: &idx, bytes: 2, value: config.sleepDuration)
        writeLE(&bytes, at: &idx, bytes: 2, value: config.recordDuration)

        bytes[idx] = config.ledEnabled ? 1 : 0; idx += 1

        // Schedule block — always 21 bytes
        if config.sunScheduleEnabled {
            let packed0 = UInt8((config.sunMode.rawValue & 0b111) | ((config.sunDefinition.rawValue & 0b11) << 3))
            bytes[idx] = packed0; idx += 1

            let lat = config.latitude.degrees * 100 + config.latitude.hundredths
            let latSigned = config.latitude.isPositive ? lat : -lat
            writeInt16LE(&bytes, at: &idx, value: latSigned)

            let lon = config.longitude.degrees * 100 + config.longitude.hundredths
            let lonSigned = config.longitude.isPositive ? lon : -lon
            writeInt16LE(&bytes, at: &idx, value: lonSigned)

            bytes[idx] = UInt8(config.sunRounding); idx += 1

            writeFourTenBit(&bytes, at: idx,
                            config.sunPeriods.sunriseBefore,
                            config.sunPeriods.sunriseAfter,
                            config.sunPeriods.sunsetBefore,
                            config.sunPeriods.sunsetAfter)
            idx += 5

            idx += 10 // padding to match schedule block size
        } else {
            var periods = config.timePeriods.sorted { $0.startMins < $1.startMins }
            let count = min(periods.count, AudioMothConstants.maxPeriods)

            bytes[idx] = UInt8(count); idx += 1

            for i in 0..<count {
                writeLE(&bytes, at: &idx, bytes: 2, value: periods[i].startMins)
                let end = periods[i].endMins == 0 ? AudioMothConstants.minutesInDay : periods[i].endMins
                writeLE(&bytes, at: &idx, bytes: 2, value: end)
            }
            // Pad remaining slots (always write MAX_PERIODS+1 total slots)
            for _ in count..<(AudioMothConstants.maxPeriods + 1) {
                writeLE(&bytes, at: &idx, bytes: 2, value: 0)
                writeLE(&bytes, at: &idx, bytes: 2, value: 0)
            }
        }

        // Timezone
        let tzOffset = config.timezoneOffsetMinutes
        let tzHours = tzOffset < 0 ? Int(ceil(Double(tzOffset) / Double(AudioMothConstants.minutesInHour)))
                                   : tzOffset / AudioMothConstants.minutesInHour
        let tzMins  = tzOffset % AudioMothConstants.minutesInHour
        bytes[idx] = UInt8(bitPattern: Int8(clamping: tzHours)); idx += 1

        bytes[idx] = 1; idx += 1 // low voltage cutoff always enabled

        var packed1: UInt8 = config.batteryLevelCheckEnabled ? 0 : 1
        if AudioMothConstants.isNewerOrEqual(trueFW, 1, 12, 0) {
            if config.requireAcousticConfig {
                packed1 |= config.requireLocationInChime ? (1 << 1) : 0
            }
            packed1 |= config.useTimezoneInChime ? (1 << 2) : 0
            if config.useTimezoneInChime {
                packed1 |= config.adjustScheduleFromAcousticChime ? (1 << 3) : 0
            }
            packed1 |= UInt8((config.prerecordingPrepTime & 0b1111) << 4)
        }
        bytes[idx] = packed1; idx += 1

        bytes[idx] = UInt8(bitPattern: Int8(clamping: tzMins)); idx += 1

        var packed2: UInt8 = config.dutyEnabled ? 0 : 1
        if AudioMothConstants.isNewerOrEqual(trueFW, 1, 11, 0) {
            packed2 |= config.filenameWithDeviceIDEnabled ? (1 << 1) : 0
            if config.timeSettingFromGPSEnabled {
                packed2 |= config.acquireGPSFixMode == .individual ? (1 << 2) : 0
                let gpsFixIndex = AudioMothConstants.validGPSFixTimes.firstIndex(of: config.gpsFixTime) ?? 0
                packed2 |= UInt8((gpsFixIndex & 0b1111) << 3)
            }
        }
        if AudioMothConstants.isNewerOrEqual(trueFW, 1, 12, 0) {
            packed2 |= config.ignoreExternalMicForAcousticChime ? (1 << 7) : 0
        }
        bytes[idx] = packed2; idx += 1

        // First/last recording dates
        let earliest = firstRecordingTimestamp(config: config)
        let latest   = lastRecordingTimestamp(config: config)
        writeLE(&bytes, at: &idx, bytes: 4, value: Int(min(UInt32.max, UInt32(max(0, earliest)))))
        writeLE(&bytes, at: &idx, bytes: 4, value: Int(min(UInt32.max, UInt32(max(0, latest)))))

        // Filters
        let (lowerFilter, higherFilter) = filterValues(config: config)
        writeLE(&bytes, at: &idx, bytes: 2, value: lowerFilter)
        writeLE(&bytes, at: &idx, bytes: 2, value: higherFilter)

        // Threshold union (amplitude or frequency trigger)
        let thresholdUnion = thresholdUnionValue(config: config, firmware: trueFW)
        writeLE(&bytes, at: &idx, bytes: 2, value: thresholdUnion)

        // packed3: requireAcousticConfig, displayVoltageRange, minimumThresholdDuration
        let minDurIdx = config.amplitudeThresholdingEnabled
            ? config.minimumAmplitudeThresholdDurationIndex
            : (config.frequencyTriggerEnabled ? config.minimumFrequencyTriggerDurationIndex : 0)
        let minDur = AudioMothConstants.minimumThresholdDurations[min(minDurIdx, AudioMothConstants.minimumThresholdDurations.count - 1)]
        var packed3: UInt8 = config.requireAcousticConfig ? 1 : 0
        packed3 |= config.displayVoltageRange ? (1 << 1) : 0
        packed3 |= UInt8((minDur & 0b111111) << 2)
        bytes[idx] = packed3; idx += 1

        // packed4/5 (amplitude) or packed6/7 (frequency trigger)
        if config.amplitudeThresholdingEnabled {
            let decibelAbs = config.amplitudeThresholdScale == .decibel ? abs(config.amplitudeThresholdDecibels) : 0
            let enableDecibel: UInt8 = config.amplitudeThresholdScale == .sixteenBit || config.amplitudeThresholdScale == .decibel ? 1 : 0
            var packed4: UInt8 = enableDecibel & 0b1
            packed4 |= UInt8((decibelAbs & 0b1111111) << 1)
            bytes[idx] = packed4; idx += 1

            let enablePct: UInt8 = config.amplitudeThresholdScale == .sixteenBit || config.amplitudeThresholdScale == .percentage ? 1 : 0
            let pctMantissa = config.amplitudeThresholdScale == .percentage ? config.amplitudeThresholdPercentageMantissa : 0
            let pctExponent = config.amplitudeThresholdScale == .percentage ? config.amplitudeThresholdPercentageExponent : 0
            var packed5: UInt8 = enablePct & 0b1
            packed5 |= UInt8((pctMantissa & 0b1111) << 1)
            packed5 |= UInt8((pctExponent & 0b111) << 5)
            bytes[idx] = packed5; idx += 1
        } else if config.frequencyTriggerEnabled && AudioMothConstants.isNewerOrEqual(trueFW, 1, 8, 0) {
            let windowLog2 = Int(log2(Double(AudioMothConstants.frequencyTriggerWindowLengths[config.frequencyTriggerWindowLengthIndex])))
            var packed6: UInt8 = UInt8(windowLog2 & 0b1111)
            packed6 |= UInt8((config.frequencyTriggerThresholdMantissa & 0b1111) << 4)
            bytes[idx] = packed6; idx += 1
            bytes[idx] = UInt8(config.frequencyTriggerThresholdExponent & 0b111); idx += 1
        } else {
            bytes[idx] = 0; idx += 1
            bytes[idx] = 0; idx += 1
        }

        // packed8: feature flags
        var packed8: UInt8 = config.energySaverModeEnabled      ? 1       : 0
        packed8 |= config.disable48DCFilter                      ? (1 << 1) : 0
        packed8 |= config.timeSettingFromGPSEnabled              ? (1 << 2) : 0
        packed8 |= config.magneticSwitchEnabled                  ? (1 << 3) : 0
        packed8 |= config.lowGainRangeEnabled                    ? (1 << 4) : 0
        packed8 |= config.frequencyTriggerEnabled                ? (1 << 5) : 0
        packed8 |= config.dailyFolders                           ? (1 << 6) : 0
        packed8 |= config.sunScheduleEnabled                     ? (1 << 7) : 0
        bytes[idx] = packed8; idx += 1

        return (Data(bytes), sendAt)
    }

    // MARK: - Private helpers

    private static func writeLE(_ buf: inout [UInt8], at idx: inout Int, bytes count: Int, value: Int) {
        for i in 0..<count {
            buf[idx + i] = UInt8((value >> (i * 8)) & 0xFF)
        }
        idx += count
    }

    private static func writeInt16LE(_ buf: inout [UInt8], at idx: inout Int, value: Int) {
        let v = Int16(clamping: value)
        let bits = v.bitPattern
        buf[idx]     = UInt8(bits & 0xFF)
        buf[idx + 1] = UInt8((bits >> 8) & 0xFF)
        idx += 2
    }

    private static func writeFourTenBit(_ buf: inout [UInt8], at start: Int, _ v1: Int, _ v2: Int, _ v3: Int, _ v4: Int) {
        buf[start]     = UInt8(v1 & 0b0011111111)
        buf[start + 1] = UInt8(((v1 & 0b1100000000) >> 8) | ((v2 & 0b0000111111) << 2))
        buf[start + 2] = UInt8(((v2 & 0b1111000000) >> 6) | ((v3 & 0b0000001111) << 4))
        buf[start + 3] = UInt8(((v3 & 0b1111110000) >> 4) | ((v4 & 0b0000000011) << 6))
        buf[start + 4] = UInt8((v4 & 0b1111111100) >> 2)
    }

    private static func firstRecordingTimestamp(config: AudioMothConfiguration) -> Int {
        guard config.firstRecordingDateEnabled,
              let date = parseDate(config.firstRecordingDate) else { return 0 }
        let utc = Int(date.timeIntervalSince1970)
        return utc - config.timezoneOffsetMinutes * AudioMothConstants.secondsInMinute
    }

    private static func lastRecordingTimestamp(config: AudioMothConfiguration) -> Int {
        guard config.lastRecordingDateEnabled,
              let date = parseDate(config.lastRecordingDate) else { return 0 }
        let utc = Int(date.timeIntervalSince1970)
        return utc + AudioMothConstants.secondsInDay - config.timezoneOffsetMinutes * AudioMothConstants.secondsInMinute
    }

    private static func parseDate(_ string: String) -> Date? {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.timeZone = TimeZone(identifier: "UTC")
        return fmt.date(from: string)
    }

    private static func filterValues(config: AudioMothConfiguration) -> (Int, Int) {
        guard config.passFiltersEnabled && !config.frequencyTriggerEnabled else { return (0, 0) }
        switch config.filterType {
        case .low:  return (AudioMothConstants.uint16Max, config.higherFilterHz / 100)
        case .band: return (config.lowerFilterHz / 100, config.higherFilterHz / 100)
        case .high: return (config.lowerFilterHz / 100, AudioMothConstants.uint16Max)
        case .none: return (0, 0)
        }
    }

    private static func thresholdUnionValue(config: AudioMothConfiguration, firmware: (Int, Int, Int)) -> Int {
        if config.amplitudeThresholdingEnabled {
            switch config.amplitudeThresholdScale {
            case .sixteenBit:
                return config.amplitudeThreshold16Bit
            case .percentage:
                let exponentValue = [0, -1, -2, -3, -4][min(config.amplitudeThresholdPercentageExponent, 4)]
                let pct = Double(config.amplitudeThresholdPercentageMantissa) * pow(10.0, Double(exponentValue))
                return Int((32768.0 * pct / 100.0).rounded())
            case .decibel:
                return Int((32768.0 * pow(10.0, Double(config.amplitudeThresholdDecibels) / 20.0)).rounded())
            }
        } else if config.frequencyTriggerEnabled && AudioMothConstants.isNewerOrEqual(firmware, 1, 8, 0) {
            return config.frequencyTriggerCentreFrequencyHz / 100
        }
        return 0
    }

    // MARK: - Battery life estimation

    static func estimatedHours(config: AudioMothConfiguration) -> Double {
        let srConfig = AudioMothConstants.configurations[config.sampleRateIndex]
        let currentMA = config.energySaverModeEnabled ? srConfig.energySaverCurrentMA : srConfig.recordCurrentMA
        let batteryCapacityMAh = 3100.0 // 4x AA NiMH approx
        guard currentMA > 0 else { return 0 }

        if config.dutyEnabled && config.sleepDuration > 0 {
            let cycleDuration = Double(config.recordDuration + config.sleepDuration)
            let dutyCycle = Double(config.recordDuration) / cycleDuration
            let effectiveCurrent = currentMA * dutyCycle
            return batteryCapacityMAh / effectiveCurrent
        }
        return batteryCapacityMAh / currentMA
    }
}
