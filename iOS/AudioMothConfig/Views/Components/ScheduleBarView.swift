import SwiftUI

struct ScheduleBarView: View {

    let timePeriods: [TimePeriod]
    var height: CGFloat = 24

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))

                ForEach(timePeriods) { period in
                    let start = CGFloat(period.startMins) / 1440.0
                    let end   = CGFloat(period.endMins == 0 ? 1440 : period.endMins) / 1440.0
                    let width = max(0, end - start) * geo.size.width

                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.accentColor.opacity(0.8))
                        .frame(width: width)
                        .offset(x: start * geo.size.width)
                }

                // Hour tick marks
                ForEach([0, 6, 12, 18, 24], id: \.self) { hour in
                    Rectangle()
                        .fill(Color(.systemGray3))
                        .frame(width: 1, height: height)
                        .offset(x: CGFloat(hour) / 24.0 * geo.size.width - 0.5)
                }
            }
            .frame(height: height)
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .frame(height: height)
    }
}

struct ScheduleTimeAxis: View {

    var body: some View {
        HStack {
            Text("00:00").font(.caption2).foregroundStyle(.tertiary)
            Spacer()
            Text("06:00").font(.caption2).foregroundStyle(.tertiary)
            Spacer()
            Text("12:00").font(.caption2).foregroundStyle(.tertiary)
            Spacer()
            Text("18:00").font(.caption2).foregroundStyle(.tertiary)
            Spacer()
            Text("24:00").font(.caption2).foregroundStyle(.tertiary)
        }
    }
}
