import SwiftUI
import Charts

struct BrewCommitCalendarView: View {
    let dailyBrews: [CoffeeBrew]
    
    private var calendar: Calendar { .current }
    
    var body: some View {
        Chart(dailyBrews) { brew in
            RectangleMark(
                xStart: .value("Start week", brew.createdAt, unit: .weekOfYear),
                xEnd: .value("End week", brew.createdAt, unit: .weekOfYear),
                yStart: .value("Start weekday", weekday(for: brew.createdAt)),
                yEnd: .value("End weekday", weekday(for: brew.createdAt) + 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 4).inset(by: 2))
            .foregroundStyle(.brown)
        }
        .chartPlotStyle { content in
            content
                .aspectRatio(aspectRatio, contentMode: .fit)
        }
        .chartForegroundStyleScale(range: Gradient(colors: colors))
        .chartXAxis {
            AxisMarks(position: .top, values: .stride(by: .month)) {
                AxisValueLabel(format: .dateTime.month())
                    .foregroundStyle(Color(.label))
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: [1, 3, 5]) { value in
                if let value = value.as(Int.self) {
                    AxisValueLabel {
                        Text(shortWeekdaySymbols[value - 1])
                    }
                    .foregroundStyle(Color(.label))
                }
            }
        }
        .chartYScale(domain: .automatic(includesZero: false, reversed: true))
        .chartLegend {
            HStack(spacing: 4) {
                Text("Less")
                ForEach(legendColors, id: \.self) { color in
                    color
                        .frame(width: 10, height: 10)
                        .cornerRadius(2)
                }
                Text("More")
            }
            .padding(4)
            .foregroundStyle(Color(.label))
            .font(.caption2)
        }
        .padding()
    }

    // MARK: - Private

    private func weekday(for date: Date) -> Int {
        let weekday = Calendar.current.component(.weekday, from: date)
        let adjustedWeekday = (weekday == 1) ? 7 : (weekday - 1)
        return adjustedWeekday
    }

    private var aspectRatio: Double {
        if dailyBrews.isEmpty {
            return 1
        }
        let firstDate = dailyBrews.first!.createdAt
        let lastDate = dailyBrews.last!.createdAt
        let weeksCount = Calendar.current.dateComponents([.weekOfYear], from: firstDate, to: lastDate).weekOfYear!
        return Double(weeksCount + 1) / 7
    }

    private var colors: [Color] {
        (0...10).map { index in
            if index == 0 {
                return Color(.systemGray5)
            }
            return Color(.systemGreen).opacity(Double(index) / 10)
        }
    }

    private var legendColors: [Color] {
        Array(stride(from: 0, to: colors.count, by: 2).map { colors[$0] })
    }

    private let shortWeekdaySymbols: [String] = {
        var shortWeekdaySymbols = Calendar.current.shortWeekdaySymbols
        let sunday = shortWeekdaySymbols.removeFirst()
        shortWeekdaySymbols.append(sunday)
        return shortWeekdaySymbols
    }()
}
