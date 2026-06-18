import SwiftUI

struct ScheduleView: View {

    @Environment(AppViewModel.self) private var vm
    @State private var showLocationPicker = false

    var body: some View {
        @Bindable var vm = vm
        Form {
            // Visual bar
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    ScheduleBarView(timePeriods: vm.config.timePeriods)
                    ScheduleTimeAxis()
                }
                .padding(.vertical, 4)
            }

            Section {
                Toggle("Sun schedule", isOn: $vm.config.sunScheduleEnabled)
            }

            if vm.config.sunScheduleEnabled {
                sunScheduleSections
            } else {
                timePeriodsSections
            }

            dateRangeSection
        }
    }

    // MARK: - Time periods

    @ViewBuilder
    private var timePeriodsSections: some View {
        Section {
            ForEach($vm.config.timePeriods) { $period in
                TimePeriodEditor(period: $period)
            }
            .onDelete { vm.removeTimePeriod(at: $0) }

            if vm.config.timePeriods.count < AudioMothConstants.maxPeriods {
                Button {
                    vm.addTimePeriod()
                } label: {
                    Label("Add recording period", systemImage: "plus")
                }
            }
        } header: {
            Text("Recording periods (max \(AudioMothConstants.maxPeriods))")
        }
    }

    // MARK: - Sun schedule

    @ViewBuilder
    private var sunScheduleSections: some View {
        Section("Sun event") {
            Picker("Mode", selection: Binding(
                get: { vm.config.sunMode },
                set: { vm.config.sunMode = $0 }
            )) {
                ForEach(SunMode.allCases, id: \.self) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }

            Picker("Definition", selection: Binding(
                get: { vm.config.sunDefinition },
                set: { vm.config.sunDefinition = $0 }
            )) {
                ForEach(SunDefinition.allCases, id: \.self) { def in
                    Text(def.displayName).tag(def)
                }
            }

            Stepper("Rounding: \(vm.config.sunRounding) min", value: $vm.config.sunRounding, in: 0...60, step: 1)
        }

        Section("Sun intervals (minutes)") {
            @Bindable var vm = vm
            SunIntervalRow(label: "Before sunrise", value: $vm.config.sunPeriods.sunriseBefore)
            SunIntervalRow(label: "After sunrise",  value: $vm.config.sunPeriods.sunriseAfter)
            SunIntervalRow(label: "Before sunset",  value: $vm.config.sunPeriods.sunsetBefore)
            SunIntervalRow(label: "After sunset",   value: $vm.config.sunPeriods.sunsetAfter)
        }

        Section("Location") {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Latitude")
                        .font(.caption).foregroundStyle(.secondary)
                    Text(String(format: "%.2f° %@",
                                Double(vm.config.latitude.degrees) + Double(vm.config.latitude.hundredths) / 100,
                                vm.config.latitude.isPositive ? "N" : "S"))
                }
                Spacer()
                VStack(alignment: .leading, spacing: 2) {
                    Text("Longitude")
                        .font(.caption).foregroundStyle(.secondary)
                    Text(String(format: "%.2f° %@",
                                Double(vm.config.longitude.degrees) + Double(vm.config.longitude.hundredths) / 100,
                                vm.config.longitude.isPositive ? "E" : "W"))
                }
                Spacer()
                Button("Edit") { showLocationPicker = true }
                    .font(.callout)
            }
            if let sunriseMin = nextSunriseMinutes, let sunsetMin = nextSunsetMinutes {
                HStack {
                    Label(minutesToTimeString(sunriseMin), systemImage: "sunrise.fill")
                        .foregroundStyle(.orange)
                    Spacer()
                    Label(minutesToTimeString(sunsetMin), systemImage: "sunset.fill")
                        .foregroundStyle(.indigo)
                }
                .font(.caption)
            }
        }
        .sheet(isPresented: $showLocationPicker) {
            @Bindable var vm = vm
            LocationPickerView(latitude: $vm.config.latitude, longitude: $vm.config.longitude)
        }
    }

    // MARK: - Date range

    @ViewBuilder
    private var dateRangeSection: some View {
        @Bindable var vm = vm
        Section("Date range") {
            Toggle("First recording date", isOn: $vm.config.firstRecordingDateEnabled)
            if vm.config.firstRecordingDateEnabled {
                DatePickerRow(label: "First date", dateString: $vm.config.firstRecordingDate)
            }
            Toggle("Last recording date", isOn: $vm.config.lastRecordingDateEnabled)
            if vm.config.lastRecordingDateEnabled {
                DatePickerRow(label: "Last date", dateString: $vm.config.lastRecordingDate)
            }
        }
    }

    // MARK: - Computed

    private var nextSunriseMinutes: Int? {
        SunCalculator.eventTime(
            event: .sunrise, date: Date(),
            latitude: vm.config.latitude.decimalDegrees,
            longitude: vm.config.longitude.decimalDegrees
        )
    }

    private var nextSunsetMinutes: Int? {
        SunCalculator.eventTime(
            event: .sunset, date: Date(),
            latitude: vm.config.latitude.decimalDegrees,
            longitude: vm.config.longitude.decimalDegrees
        )
    }

    private func minutesToTimeString(_ mins: Int) -> String {
        let m = mins % 1440
        return String(format: "%02d:%02d", m / 60, m % 60)
    }
}

struct SunIntervalRow: View {
    let label: String
    @Binding var value: Int

    var body: some View {
        Stepper("\(label): \(value) min", value: $value, in: 0...1023, step: 1)
    }
}

struct DatePickerRow: View {
    let label: String
    @Binding var dateString: String

    private var dateBinding: Binding<Date> {
        Binding(
            get: {
                let fmt = DateFormatter()
                fmt.dateFormat = "yyyy-MM-dd"
                return fmt.date(from: dateString) ?? Date()
            },
            set: {
                let fmt = DateFormatter()
                fmt.dateFormat = "yyyy-MM-dd"
                dateString = fmt.string(from: $0)
            }
        )
    }

    var body: some View {
        DatePicker(label, selection: dateBinding, displayedComponents: .date)
    }
}
