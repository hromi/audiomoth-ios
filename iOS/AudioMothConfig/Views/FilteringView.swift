import SwiftUI

struct FilteringView: View {

    @Environment(AppViewModel.self) private var vm

    private let frequencyTriggerWindowLabels = ["16", "32", "64", "128", "256", "512", "1024", "2048"]

    var body: some View {
        @Bindable var vm = vm
        Form {

            // MARK: Pass filters

            Section {
                Toggle("Enable frequency filters", isOn: $vm.config.passFiltersEnabled)
            }

            if vm.config.passFiltersEnabled && !vm.config.frequencyTriggerEnabled {
                Section("Filter type") {
                    Picker("Type", selection: $vm.config.filterType) {
                        ForEach(FilterType.allCases, id: \.self) { ft in
                            Text(ft.displayName).tag(ft)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                if vm.config.filterType != .none {
                    Section("Frequency range (Hz)") {
                        if vm.config.filterType == .high || vm.config.filterType == .band {
                            FrequencyRow(label: "Lower cutoff", value: $vm.config.lowerFilterHz,
                                         range: 100...192000, step: 100)
                        }
                        if vm.config.filterType == .low || vm.config.filterType == .band {
                            FrequencyRow(label: "Higher cutoff", value: $vm.config.higherFilterHz,
                                         range: 100...192000, step: 100)
                        }
                    }
                }
            }

            // MARK: Amplitude threshold

            Section {
                Toggle("Amplitude threshold", isOn: $vm.config.amplitudeThresholdingEnabled)
            }

            if vm.config.amplitudeThresholdingEnabled {
                Section("Threshold scale") {
                    Picker("Scale", selection: $vm.config.amplitudeThresholdScale) {
                        ForEach(ThresholdScale.allCases, id: \.self) { s in
                            Text(s.displayName).tag(s)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Threshold value") {
                    switch vm.config.amplitudeThresholdScale {
                    case .percentage:
                        percentageThresholdControls
                    case .sixteenBit:
                        Stepper("Value: \(vm.config.amplitudeThreshold16Bit)",
                                value: $vm.config.amplitudeThreshold16Bit, in: 1...32768, step: 100)
                    case .decibel:
                        Stepper("Level: \(vm.config.amplitudeThresholdDecibels) dB",
                                value: $vm.config.amplitudeThresholdDecibels, in: -100...0, step: 1)
                    }
                }

                Section("Minimum trigger duration") {
                    Picker("Duration", selection: $vm.config.minimumAmplitudeThresholdDurationIndex) {
                        ForEach(0..<AudioMothConstants.minimumThresholdDurations.count, id: \.self) { i in
                            Text(durationLabel(AudioMothConstants.minimumThresholdDurations[i])).tag(i)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }

            // MARK: Frequency trigger

            Section {
                Toggle("Frequency trigger (Goertzel)", isOn: $vm.config.frequencyTriggerEnabled)
                    .onChange(of: vm.config.frequencyTriggerEnabled) { _, enabled in
                        if enabled { vm.config.passFiltersEnabled = false }
                    }
            }

            if vm.config.frequencyTriggerEnabled {
                Section("Frequency trigger settings") {
                    FrequencyRow(label: "Centre frequency", value: $vm.config.frequencyTriggerCentreFrequencyHz,
                                 range: 100...192000, step: 100)

                    Picker("Window length", selection: $vm.config.frequencyTriggerWindowLengthIndex) {
                        ForEach(0..<frequencyTriggerWindowLabels.count, id: \.self) { i in
                            Text(frequencyTriggerWindowLabels[i] + " samples").tag(i)
                        }
                    }

                    HStack {
                        Text("Threshold mantissa")
                        Spacer()
                        Stepper("\(vm.config.frequencyTriggerThresholdMantissa)",
                                value: $vm.config.frequencyTriggerThresholdMantissa, in: 0...15, step: 1)
                    }
                    HStack {
                        Text("Threshold exponent")
                        Spacer()
                        Stepper("\(vm.config.frequencyTriggerThresholdExponent)",
                                value: $vm.config.frequencyTriggerThresholdExponent, in: 0...7, step: 1)
                    }
                }

                Section("Minimum trigger duration") {
                    Picker("Duration", selection: $vm.config.minimumFrequencyTriggerDurationIndex) {
                        ForEach(0..<AudioMothConstants.minimumThresholdDurations.count, id: \.self) { i in
                            Text(durationLabel(AudioMothConstants.minimumThresholdDurations[i])).tag(i)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
        }
    }

    @ViewBuilder
    private var percentageThresholdControls: some View {
        @Bindable var vm = vm
        let mantissaLabels = (1...9).map { "\($0)" }
        let exponentLabels = ["×1%", "×0.1%", "×0.01%", "×0.001%", "×0.0001%"]

        HStack {
            Text("Mantissa")
            Spacer()
            Picker("Mantissa", selection: $vm.config.amplitudeThresholdPercentageMantissa) {
                ForEach(1...9, id: \.self) { v in Text("\(v)").tag(v) }
            }
            .pickerStyle(.menu)
        }
        HStack {
            Text("Exponent")
            Spacer()
            Picker("Exponent", selection: $vm.config.amplitudeThresholdPercentageExponent) {
                ForEach(0..<exponentLabels.count, id: \.self) { i in
                    Text(exponentLabels[i]).tag(i)
                }
            }
            .pickerStyle(.menu)
        }
        HStack {
            Text("Effective threshold")
            Spacer()
            Text(percentageEffectiveThreshold)
                .foregroundStyle(.secondary)
        }
    }

    private var percentageEffectiveThreshold: String {
        let exponent = [0, -1, -2, -3, -4][vm.config.amplitudeThresholdPercentageExponent]
        let value = Double(vm.config.amplitudeThresholdPercentageMantissa) * pow(10.0, Double(exponent))
        if value >= 1 { return String(format: "%.0f%%", value) }
        if value >= 0.1 { return String(format: "%.1f%%", value) }
        if value >= 0.01 { return String(format: "%.2f%%", value) }
        return String(format: "%.4f%%", value)
    }

    private func durationLabel(_ seconds: Int) -> String {
        if seconds == 0 { return "None" }
        return "\(seconds)s"
    }
}

struct FrequencyRow: View {
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let step: Int

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(frequencyString(value))
                .foregroundStyle(.secondary)
                .frame(minWidth: 80, alignment: .trailing)
            Stepper("", value: $value, in: range, step: step)
                .labelsHidden()
        }
    }

    private func frequencyString(_ hz: Int) -> String {
        hz >= 1000 ? String(format: "%.1f kHz", Double(hz) / 1000) : "\(hz) Hz"
    }
}
