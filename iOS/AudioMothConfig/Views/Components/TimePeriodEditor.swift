import SwiftUI

struct TimePeriodEditor: View {

    @Binding var period: TimePeriod

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Start").font(.caption).foregroundStyle(.secondary)
                TimeMinutePicker(minutesSinceMidnight: Binding(
                    get: { period.startMins },
                    set: { period.startMins = $0 }
                ))
            }

            Image(systemName: "arrow.right")
                .font(.caption)
                .foregroundStyle(.tertiary)

            VStack(alignment: .leading, spacing: 2) {
                Text("End").font(.caption).foregroundStyle(.secondary)
                TimeMinutePicker(minutesSinceMidnight: Binding(
                    get: { period.endMins == 0 ? 1440 : period.endMins },
                    set: { period.endMins = ($0 == 1440) ? 0 : $0 }
                ))
            }

            Spacer()
        }
    }
}

struct TimeMinutePicker: View {

    @Binding var minutesSinceMidnight: Int
    @State private var showPicker = false

    var displayText: String {
        let m = minutesSinceMidnight % 1440
        return String(format: "%02d:%02d", m / 60, m % 60)
    }

    var body: some View {
        Button(displayText) { showPicker = true }
            .font(.system(.body, design: .monospaced))
            .sheet(isPresented: $showPicker) {
                TimePickerSheet(value: $minutesSinceMidnight, isPresented: $showPicker)
            }
    }
}

struct TimePickerSheet: View {

    @Binding var value: Int
    @Binding var isPresented: Bool

    @State private var hour: Int = 0
    @State private var minute: Int = 0

    var body: some View {
        NavigationStack {
            HStack(spacing: 0) {
                Picker("Hour", selection: $hour) {
                    ForEach(0..<25, id: \.self) { h in
                        Text(String(format: "%02d", h)).tag(h)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)

                Text(":")
                    .font(.title2.bold())

                Picker("Minute", selection: $minute) {
                    ForEach(0..<60, id: \.self) { m in
                        Text(String(format: "%02d", m)).tag(m)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
            }
            .padding()
            .navigationTitle("Select time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        value = hour * 60 + minute
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
            }
        }
        .presentationDetents([.height(280)])
        .onAppear {
            hour   = (value % 1440) / 60
            minute = (value % 1440) % 60
        }
    }
}
