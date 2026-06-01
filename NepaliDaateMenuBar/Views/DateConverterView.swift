//
//  DateConverterView.swift
//  NepaliDaateMenuBar
//
//  BS ↔ AD date converter
//

import SwiftUI

struct DateConverterView: View {
    // Supported range: bs_calendar_data.json (91 years)
    private static let bsYearRange = 2000...2090
    private static let adYearRange = 1943...2034

    enum ConversionMode { case bsToAd, adToBs }

    @State private var mode: ConversionMode = .bsToAd

    // Inputs
    @State private var year: String = ""
    @State private var month: Int = 1
    @State private var day: String = ""

    // Output
    @State private var result: ConversionResult? = nil
    @State private var errorMessage: String = ""

    @State private var copyFeedback = false

    private let nepaliMonths = ["Baishakh", "Jeth", "Ashar", "Shrawan", "Bhadra", "Ashwin",
                                "Kartik", "Mangsir", "Poush", "Magh", "Falgun", "Chaitra"]
    private let gregorianMonths = ["January", "February", "March", "April", "May", "June",
                                   "July", "August", "September", "October", "November", "December"]

    private var months: [String] { mode == .bsToAd ? nepaliMonths : gregorianMonths }

    struct ConversionResult {
        let date: String
        let weekday: String
        let tithi: String
        let tithiVerified: Bool
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    modeSection
                    ConverterDivider()
                    inputSection
                    ConverterDivider()
                    resultSection
                }
            }
        }
        .frame(width: 360)
        .onChange(of: mode) { _ in clearAll() }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: 28, height: 28)
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.accentColor)
            }
            Text("Date Converter")
                .font(.system(size: 14, weight: .semibold))
            Spacer()
            Text("BS \(Self.bsYearRange.lowerBound)–\(Self.bsYearRange.upperBound)")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Mode section

    private var modeSection: some View {
        ConverterSection(icon: "arrow.2.squarepath", title: "Conversion") {
            HStack(spacing: 8) {
                ModeChip(label: "BS → AD", isSelected: mode == .bsToAd) { mode = .bsToAd }
                ModeChip(label: "AD → BS", isSelected: mode == .adToBs) { mode = .adToBs }
                Spacer()
            }
        }
    }

    // MARK: - Input section

    private var inputSection: some View {
        ConverterSection(
            icon: "calendar",
            title: mode == .bsToAd ? "Bikram Sambat Date" : "Gregorian Date"
        ) {
            VStack(spacing: 10) {
                // Month picker — full width
                VStack(alignment: .leading, spacing: 5) {
                    Text("Month")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                                            Picker("", selection: $month) {
                        ForEach(1...12, id: \.self) { i in
                            Text(months[i - 1]).tag(i)
                        }
                    }
                    .labelsHidden()
                    .frame(maxWidth: .infinity)
                }

                HStack(spacing: 10) {
                    // Year
                    VStack(alignment: .leading, spacing: 5) {
                        Text(mode == .bsToAd ? "BS Year" : "AD Year")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                                                    TextField(mode == .bsToAd ? "e.g. 2081" : "e.g. 2024", text: $year)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit(convert)
                    }

                    // Day
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Day")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                                                    TextField("DD", text: $day)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 64)
                            .onSubmit(convert)
                    }
                }

                // Error inline
                if !errorMessage.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(.orange)
                        Text(errorMessage)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.orange.opacity(0.07))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                    )
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // Convert button
                Button(action: convert) {
                    Text("Convert")
                        .font(.system(size: 12, weight: .semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
            }
        }
    }

    // MARK: - Result section

    @ViewBuilder
    private var resultSection: some View {
        if let result {
            ConverterSection(icon: "checkmark.circle", title: "Result", tint: .green) {
                VStack(spacing: 10) {
                    // Primary result — accent preview block matching settings style
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(result.date)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(Color.accentColor)

                            HStack(spacing: 4) {
                                if !result.weekday.isEmpty {
                                    Text(result.weekday)
                                        .font(.system(size: 11))
                                        .foregroundStyle(.secondary)
                                }
                                if !result.weekday.isEmpty && !result.tithi.isEmpty {
                                    Text("·")
                                        .font(.system(size: 11))
                                        .foregroundStyle(.secondary.opacity(0.5))
                                }
                                if !result.tithi.isEmpty {
                                    Text(result.tithi)
                                        .font(.system(size: 11))
                                        .foregroundStyle(.secondary)
                                    if !result.tithiVerified {
                                        Text("Predicted")
                                            .font(.system(size: 10, weight: .medium))
                                            .foregroundStyle(.orange)
                                            .padding(.horizontal, 5)
                                            .padding(.vertical, 1)
                                            .background(
                                                Capsule()
                                                    .fill(Color.orange.opacity(0.1))
                                            )
                                            .help("Algorithmically calculated — not vetted against the official Nepali calendar")
                                    }
                                }
                            }
                        }

                        Spacer()

                        // Copy button
                        Button {
                            let parts = [result.date, result.weekday, result.tithi].filter { !$0.isEmpty }
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(parts.joined(separator: " · "), forType: .string)
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                copyFeedback = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                withAnimation { copyFeedback = false }
                            }
                        } label: {
                            Image(systemName: copyFeedback ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(copyFeedback ? .green : .secondary)
                                .frame(width: 28, height: 28)
                                .background(
                                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                                        .fill(Color(NSColor.controlBackgroundColor))
                                )
                        }
                        .buttonStyle(.plain)
                        .help("Copy to clipboard")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.accentColor.opacity(0.07))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.accentColor.opacity(0.15), lineWidth: 1)
                    )
                    .cornerRadius(8)
                }
            }
            .transition(.opacity.combined(with: .move(edge: .bottom)))
        } else {
            // Placeholder keeps layout stable
            ConverterSection(icon: "checkmark.circle", title: "Result", tint: .secondary) {
                HStack(spacing: 8) {
                    Text("Enter a date and tap Convert")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.secondary.opacity(0.5))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color(NSColor.controlBackgroundColor).opacity(0.4))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Actions

    private func convert() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            errorMessage = ""
            result = nil
        }

        let trimmedYear = year.trimmingCharacters(in: .whitespaces)
        let trimmedDay = day.trimmingCharacters(in: .whitespaces)

        guard let y = Int(trimmedYear), let d = Int(trimmedDay) else {
            withAnimation { errorMessage = "Enter a valid year and day." }
            return
        }

        if mode == .bsToAd {
            guard Self.bsYearRange.contains(y) else {
                withAnimation { errorMessage = "BS year must be \(Self.bsYearRange.lowerBound)–\(Self.bsYearRange.upperBound)." }
                return
            }
            guard d >= 1 && d <= 32 else {
                withAnimation { errorMessage = "Day must be between 1 and 32." }
                return
            }

            let nepaliDate = NepaliDate(year: y, month: month, day: d)
            guard let adDate = NepaliDateConverter.convertNepaliToGregorian(nepaliDate: nepaliDate) else {
                withAnimation { errorMessage = "Invalid date — check the day is valid for the selected month." }
                return
            }

            let dateFmt = DateFormatter()
            dateFmt.locale = Locale(identifier: "en_US_POSIX")
            dateFmt.dateFormat = "MMMM d, yyyy"

            let wdFmt = DateFormatter()
            wdFmt.locale = Locale(identifier: "en_US_POSIX")
            wdFmt.dateFormat = "EEEE"

            let tithiInfo = NepaliDateConverter.getTithiInfo(for: adDate)

            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                result = ConversionResult(
                    date: dateFmt.string(from: adDate) + " AD",
                    weekday: wdFmt.string(from: adDate),
                    tithi: tithiInfo?.name ?? "",
                    tithiVerified: tithiInfo?.isOverridden ?? false
                )
            }
        } else {
            guard Self.adYearRange.contains(y) else {
                withAnimation { errorMessage = "AD year must be \(Self.adYearRange.lowerBound)–\(Self.adYearRange.upperBound)." }
                return
            }
            guard d >= 1 && d <= 31 else {
                withAnimation { errorMessage = "Day must be between 1 and 31." }
                return
            }

            guard let nepaliDate = NepaliDateConverter.convertToNepali(year: y, month: month, day: d) else {
                withAnimation { errorMessage = "Invalid date — check the day is valid for the selected month." }
                return
            }

            let calendar = Calendar(identifier: .gregorian)
            let adDate = calendar.date(from: DateComponents(year: y, month: month, day: d))

            let wdFmt = DateFormatter()
            wdFmt.locale = Locale(identifier: "en_US_POSIX")
            wdFmt.dateFormat = "EEEE"

            let tithiInfo = adDate.flatMap { NepaliDateConverter.getTithiInfo(for: $0) }

            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                result = ConversionResult(
                    date: "\(nepaliDate.englishMonthName) \(nepaliDate.day), \(nepaliDate.year) BS",
                    weekday: adDate.map { wdFmt.string(from: $0) } ?? "",
                    tithi: tithiInfo?.name ?? "",
                    tithiVerified: tithiInfo?.isOverridden ?? false
                )
            }
        }
    }

    private func clearAll() {
        year = ""
        month = 1
        day = ""
        result = nil
        errorMessage = ""
        copyFeedback = false
    }
}

// MARK: - Mode chip

private struct ModeChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.accentColor)
                }
                Text(label)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .accentColor : .primary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.12) : Color(NSColor.controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isSelected ? Color.accentColor.opacity(0.4) : Color.primary.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isHovered)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Section container (mirrors SettingsSection)

private struct ConverterSection<Content: View>: View {
    let icon: String
    let title: String
    var tint: Color = .accentColor
    let content: Content

    init(icon: String, title: String, tint: Color = .accentColor, @ViewBuilder content: () -> Content) {
        self.icon = icon
        self.title = title
        self.tint = tint
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 7) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(tint)
                    .frame(width: 16)
                Text(title.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)
                    .tracking(0.5)
            }
            content
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

// MARK: - Divider (mirrors SettingsDivider)

private struct ConverterDivider: View {
    var body: some View {
        Divider().padding(.horizontal, 16)
    }
}
