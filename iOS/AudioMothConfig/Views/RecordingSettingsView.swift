import SwiftUI

struct RecordingSettingsView: View {

    @Environment(AppViewModel.self) private var vm

    private let sampleRateLabels = ["8 kHz", "16 kHz", "32 kHz", "48 kHz", "96 kHz", "192 kHz", "250 kHz", "384 kHz"]
    private let gainLabels = ["Low (0)", "Low-medium (1)", "Medium (2)", "Medium-high (3)", "High (4)"]

    var body: some View {
        @Bindable var vm = vm
        Form {
            Section("Sample Rate") {
                Picker("Sample rate", selection: $vm.config.sampleRateIndex) {
                    ForEach(0..<sampleRateLabels.count, id: \.self) { i in
                        Text(sampleRateLabels[i]).tag(i)
                    }
                }
                .pickerStyle(.menu)
            }

            Section("Gain") {
                Picker("Gain", selection: $vm.config.gain) {
                    ForEach(0..<gainLabels.count, id: \.self) { i in
                        Text(gainLabels[i]).tag(i)
                    }
                }
                .pickerStyle(.menu)
            }

            Section("Durations") {
                DurationRow(label: "Record duration", value: $vm.config.recordDuration, max: AudioMothConstants.maxRecordDuration)
                DurationRow(label: "Sleep duration", value: $vm.config.sleepDuration, max: AudioMothConstants.maxSleepDuration)
            }

            Section("Options") {
                Toggle("Enable LED", isOn: $vm.config.ledEnabled)
                Toggle("Battery level check", isOn: $vm.config.batteryLevelCheckEnabled)
            }

            Section("Estimated battery life") {
                HStack {
                    Text("Recording time")
                    Spacer()
                    Text(batteryEstimate)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var batteryEstimate: String {
        let hours = vm.estimatedBatteryHours
        if hours > 48 {
            return String(format: "%.0f days", hours / 24)
        }
        return String(format: "%.1f hours", hours)
    }
}

struct DurationRow: View {
    let label: String
    @Binding var value: Int
    let max: Int

    @State private var showPicker = false

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Button(formattedDuration(value)) {
                showPicker = true
            }
            .foregroundStyle(.secondary)
        }
        .sheet(isPresented: $showPicker) {
            DurationPickerSheet(label: label, value: $value, max: max, isPresented: $showPicker)
        }
    }

    private func formattedDuration(_ seconds: Int) -> String {
        if seconds == 0 { return "0s" }
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        var parts: [String] = []
        if h > 0 { parts.append("\(h)h") }
        if m > 0 { parts.append("\(m)m") }
        if s > 0 { parts.append("\(s)s") }
        return parts.joined(separator: " ")
    }
}

struct DurationPickerSheet: View {

    let label: String
    @Binding var value: Int
    let max: Int
    @Binding var isPresented: Bool

    @State private var hours: Int = 0
    @State private var minutes: Int = 0
    @State private var seconds: Int = 0

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Picker("Hours", selection: $hours) {
                            ForEach(0..<(max / 3600 + 1), id: \.self) { Text("\($0)h").tag($0) }
                        }
                        .pickerStyle(.wheel)
                        Picker("Minutes", selection: $minutes) {
                            ForEach(0..<60, id: \.self) { Text("\($0)m").tag($0) }
                        }
                        .pickerStyle(.wheel)
                        Picker("Seconds", selection: $seconds) {
                            ForEach(0..<60, id: \.self) { Text("\($0)s").tag($0) }
                        }
                        .pickerStyle(.wheel)
                    }
                    .frame(height: 180)
                }
            }
            .navigationTitle(label)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        value = hours * 3600 + minutes * 60 + seconds
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
            }
        }
        .onAppear {
            hours = value / 3600
            minutes = (value % 3600) / 60
            seconds = value % 60
        }
    }
}
