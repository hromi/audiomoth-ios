import SwiftUI

struct AdvancedView: View {

    @Environment(AppViewModel.self) private var vm

    var body: some View {
        @Bindable var vm = vm
        Form {

            Section("Duty cycling") {
                Toggle("Enable duty cycle", isOn: $vm.config.dutyEnabled)
                if vm.config.dutyEnabled {
                    DurationRow(label: "Record duration",
                                value: $vm.config.recordDuration,
                                max: AudioMothConstants.maxRecordDuration)
                    DurationRow(label: "Sleep duration",
                                value: $vm.config.sleepDuration,
                                max: AudioMothConstants.maxSleepDuration)
                    HStack {
                        Text("Duty cycle")
                        Spacer()
                        Text(dutyCycleString)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Files") {
                Toggle("Filename includes device ID", isOn: $vm.config.filenameWithDeviceIDEnabled)
                Toggle("Daily folders", isOn: $vm.config.dailyFolders)
            }

            Section("Power") {
                Toggle("Energy saver mode", isOn: $vm.config.energySaverModeEnabled)
                Toggle("Low gain range", isOn: $vm.config.lowGainRangeEnabled)
                Toggle("Display voltage range (NiMH/LiPo)", isOn: $vm.config.displayVoltageRange)
                Text("Voltage range affects the battery level indicator display on the device LED.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Filters") {
                Toggle("Disable 48 Hz DC blocking filter", isOn: $vm.config.disable48DCFilter)
                Text("The 48 Hz DC blocking filter is enabled by default to remove DC offset noise.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Hardware") {
                Toggle("Enable magnetic switch", isOn: $vm.config.magneticSwitchEnabled)
                Text("When enabled, the magnetic switch can be used to start or stop a delayed recording schedule.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Timezone") {
                Picker("Time zone", selection: $vm.config.timezoneMode) {
                    Text("UTC").tag(0)
                    Text("Local time").tag(1)
                    Text("Custom").tag(2)
                }

                if vm.config.timezoneMode == 2 {
                    HStack {
                        Text("UTC offset")
                        Spacer()
                        Text(timezoneOffsetString(vm.config.customTimezoneOffsetMinutes))
                            .foregroundStyle(.secondary)
                        Stepper("",
                                value: $vm.config.customTimezoneOffsetMinutes,
                                in: AudioMothConstants.minCustomTimezoneOffset...AudioMothConstants.maxCustomTimezoneOffset,
                                step: 30)
                        .labelsHidden()
                    }
                }

                if vm.config.timezoneMode == 1 {
                    HStack {
                        Text("Current local offset")
                        Spacer()
                        Text(timezoneOffsetString(TimeZone.current.secondsFromGMT() / 60))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var dutyCycleString: String {
        let total = vm.config.recordDuration + vm.config.sleepDuration
        guard total > 0 else { return "—" }
        let pct = 100.0 * Double(vm.config.recordDuration) / Double(total)
        return String(format: "%.0f%%", pct)
    }

    private func timezoneOffsetString(_ minutes: Int) -> String {
        let sign = minutes >= 0 ? "+" : "-"
        let absMin = abs(minutes)
        let h = absMin / 60
        let m = absMin % 60
        return m == 0 ? String(format: "UTC%@%d", sign, h)
                      : String(format: "UTC%@%d:%02d", sign, h, m)
    }
}
