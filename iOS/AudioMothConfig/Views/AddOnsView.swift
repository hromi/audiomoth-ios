import SwiftUI

struct AddOnsView: View {

    @Environment(AppViewModel.self) private var vm

    private let gpsFixTimeLabels = ["1 min", "2 min", "5 min", "10 min", "15 min"]

    var body: some View {
        @Bindable var vm = vm
        Form {

            // MARK: GPS time setting

            Section {
                Toggle("Set time from GPS", isOn: $vm.config.timeSettingFromGPSEnabled)
            } header: {
                Text("GPS")
            } footer: {
                Text("Requires a compatible GPS module connected to AudioMoth.")
            }

            if vm.config.timeSettingFromGPSEnabled {
                Section("GPS acquisition") {
                    Picker("GPS fix time", selection: Binding(
                        get: {
                            AudioMothConstants.validGPSFixTimes.firstIndex(of: vm.config.gpsFixTime) ?? 0
                        },
                        set: {
                            vm.config.gpsFixTime = AudioMothConstants.validGPSFixTimes[$0]
                        }
                    )) {
                        ForEach(0..<gpsFixTimeLabels.count, id: \.self) { i in
                            Text(gpsFixTimeLabels[i]).tag(i)
                        }
                    }
                    .pickerStyle(.menu)

                    Picker("Acquire fix", selection: $vm.config.acquireGPSFixMode) {
                        ForEach(GPSAcquireMode.allCases, id: \.self) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }

            // MARK: Acoustic configuration

            Section {
                Toggle("Require acoustic configuration", isOn: $vm.config.requireAcousticConfig)
            } header: {
                Text("Acoustic configuration")
            } footer: {
                Text("When enabled, the AudioMoth will not start recording until it receives a valid acoustic configuration signal.")
            }

            if vm.config.requireAcousticConfig {
                Section("Acoustic options") {
                    Toggle("Include location in chime", isOn: $vm.config.requireLocationInChime)
                    Toggle("Include timezone in chime", isOn: $vm.config.useTimezoneInChime)
                    if vm.config.useTimezoneInChime {
                        Toggle("Adjust schedule using chime timezone", isOn: $vm.config.adjustScheduleFromAcousticChime)
                    }
                    Toggle("Ignore external mic for chime", isOn: $vm.config.ignoreExternalMicForAcousticChime)
                }
            }

            // MARK: Pre-recording

            Section {
                Stepper("Preparation time: \(vm.config.prerecordingPrepTime)s",
                        value: $vm.config.prerecordingPrepTime, in: 0...15, step: 1)
            } header: {
                Text("Pre-recording")
            } footer: {
                Text("Time the AudioMoth waits before starting a recording to allow the microphone to stabilise.")
            }
        }
    }
}
