import SwiftUI

/// Calendrier mensuel de sélection de dates avec indicateur de vélos disponibles par jour.
struct AvailabilityCalendarView: View {
    let bike: Bike
    /// Taille concernée : la disponibilité affichée ne compte que son stock.
    let variant: BikeVariant
    @Binding var startDate: Date
    @Binding var endDate: Date

    @EnvironmentObject private var reservationStore: ReservationStore
    @State private var visibleMonth = Calendar.current.startOfDay(for: .now)
    @State private var isSelectingRangeEnd = false

    private let calendar = Calendar.current

    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMMM yyyy")
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter
    }()

    private static let weekdaySymbols = ["L", "M", "M", "J", "V", "S", "D"]

    private var today: Date { calendar.startOfDay(for: .now) }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Text("Dates")
                    .font(Theme.Fonts.body(12, weight: .semibold))
                    .tracking(1.5)
                    .foregroundStyle(Theme.Colors.sage)
                Spacer()
                Text("Taille \(variant.size)")
                    .font(Theme.Fonts.body(11, weight: .semibold))
                    .foregroundStyle(Theme.Colors.primaryStrong)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Theme.Colors.surfaceAlt)
                    .clipShape(Capsule())
            }

            monthHeader
            weekdayHeader
            dayGrid
            legend
            summary
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .stroke(Theme.Colors.line, lineWidth: 1)
        )
    }

    // MARK: - Header

    private var monthHeader: some View {
        HStack {
            Button {
                changeMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
            }
            .disabled(!canGoToPreviousMonth)
            .opacity(canGoToPreviousMonth ? 1 : 0.3)

            Spacer()

            Text(Self.monthFormatter.string(from: visibleMonth).capitalized)
                .font(Theme.Fonts.display(15, weight: .semibold))
                .foregroundStyle(Theme.Colors.ink)

            Spacer()

            Button {
                changeMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
            }
        }
        .foregroundStyle(Theme.Colors.primaryStrong)
    }

    private var weekdayHeader: some View {
        HStack {
            ForEach(Array(Self.weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                Text(symbol)
                    .font(Theme.Fonts.body(11, weight: .semibold))
                    .foregroundStyle(Theme.Colors.inkSoft)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Grid

    private var dayGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
            ForEach(Array(daysInVisibleMonth.enumerated()), id: \.offset) { _, date in
                if let date {
                    dayCell(for: date)
                } else {
                    Color.clear.frame(minHeight: 40)
                }
            }
        }
    }

    private func dayCell(for date: Date) -> some View {
        let day = calendar.startOfDay(for: date)
        let isPast = day < today
        let available = reservationStore.availableUnits(for: bike, variant: variant, on: day)
        let isRangeEdge = calendar.isDate(day, inSameDayAs: startDate) || calendar.isDate(day, inSameDayAs: endDate)
        let isInRange = isInSelectedRange(day)

        return Button {
            select(day: day)
        } label: {
            VStack(spacing: 3) {
                Text("\(calendar.component(.day, from: day))")
                    .font(Theme.Fonts.body(13, weight: isRangeEdge ? .semibold : .regular))
                    .foregroundStyle(
                        isPast ? Theme.Colors.inkSoft.opacity(0.4)
                        : isRangeEdge ? Theme.Colors.surface
                        : Theme.Colors.ink
                    )

                Circle()
                    .fill(indicatorColor(available: available, isPast: isPast))
                    .frame(width: 6, height: 6)
            }
            .frame(maxWidth: .infinity, minHeight: 40)
            .background(
                Circle()
                    .fill(isRangeEdge ? Theme.Colors.primary : (isInRange ? Theme.Colors.primary.opacity(0.16) : Color.clear))
            )
        }
        .buttonStyle(.plain)
        .disabled(isPast || available <= 0)
    }

    private func indicatorColor(available: Int, isPast: Bool) -> Color {
        guard !isPast else { return .clear }
        if available <= 0 { return Theme.Colors.warning }
        if available < variant.units { return Theme.Colors.sand }
        return Theme.Colors.sage
    }

    // MARK: - Legend & summary

    private var legend: some View {
        HStack(spacing: Theme.Spacing.md) {
            legendItem(color: Theme.Colors.sage, label: "Disponible")
            legendItem(color: Theme.Colors.sand, label: "Places limitées")
            legendItem(color: Theme.Colors.warning, label: "Complet")
        }
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(label)
                .font(Theme.Fonts.body(11))
                .foregroundStyle(Theme.Colors.inkSoft)
        }
    }

    private var summary: some View {
        let available = reservationStore.availableUnits(for: bike, variant: variant, from: startDate, to: endDate)
        return HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: available > 0 ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(available > 0 ? Theme.Colors.primary : Theme.Colors.warning)
            Text(
                available > 0
                ? "\(available) vélo\(available > 1 ? "s" : "") en \(variant.size) disponible\(available > 1 ? "s" : "") sur la période choisie"
                : "Taille \(variant.size) complète sur une partie de cette période"
            )
            .font(Theme.Fonts.body(13, weight: .semibold))
            .foregroundStyle(Theme.Colors.ink)
        }
        .padding(.top, Theme.Spacing.xs)
    }

    // MARK: - Selection logic

    private func isInSelectedRange(_ day: Date) -> Bool {
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)
        return day >= start && day <= end
    }

    private func select(day: Date) {
        if isSelectingRangeEnd, day >= calendar.startOfDay(for: startDate) {
            endDate = day
            isSelectingRangeEnd = false
        } else {
            startDate = day
            endDate = day
            isSelectingRangeEnd = true
        }
    }

    // MARK: - Month navigation

    private var canGoToPreviousMonth: Bool {
        !calendar.isDate(visibleMonth, equalTo: today, toGranularity: .month)
    }

    private func changeMonth(by value: Int) {
        guard let newMonth = calendar.date(byAdding: .month, value: value, to: visibleMonth) else { return }
        visibleMonth = newMonth
    }

    private var daysInVisibleMonth: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: visibleMonth) else { return [] }
        let firstOfMonth = monthInterval.start
        let weekday = calendar.component(.weekday, from: firstOfMonth) // 1 = dimanche ... 7 = samedi
        let leadingEmptyDays = (weekday + 5) % 7 // décalage pour démarrer la semaine un lundi
        let daysCount = calendar.range(of: .day, in: .month, for: visibleMonth)?.count ?? 30

        var days: [Date?] = Array(repeating: nil, count: leadingEmptyDays)
        days += (0..<daysCount).compactMap { calendar.date(byAdding: .day, value: $0, to: firstOfMonth) }
        return days
    }
}
