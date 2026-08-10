import DeviceActivity
import ExtensionKit
import FamilyControls
import ManagedSettings
import SwiftUI

private func RL(_ key: String) -> String {
    SharedLocalization.text(key)
}

private func RL(_ key: String, _ arguments: CVarArg...) -> String {
    SharedLocalization.text(key, arguments)
}

private func formatDuration(_ seconds: TimeInterval) -> String {
    let total = max(0, Int(seconds.rounded()))
    let hours = total / 3600
    let minutes = (total % 3600) / 60

    if hours > 0 {
        if minutes > 0 {
            return RL("report.duration.hours_minutes", String(hours), String(minutes))
        }
        return RL("report.duration.hours", String(hours))
    }
    return RL("report.duration.minutes", String(minutes))
}

@main
struct UnboundReportExtension: DeviceActivityReportExtension {
    var body: some DeviceActivityReportScene {
        DailySummaryReport { configuration in
            DailySummaryView(configuration: configuration)
        }
    }
}

struct DailySummaryReport: DeviceActivityReportScene {
    let content: (DailySummaryConfiguration) -> DailySummaryView

    var context: DeviceActivityReport.Context = .dailySummary

    func makeConfiguration(
        representing data: DeviceActivityResults<DeviceActivityData>
    ) async -> DailySummaryConfiguration {
        var totalDuration: TimeInterval = 0
        var appDurations: [ApplicationToken: TimeInterval] = [:]

        for await deviceData in data {
            for await segment in deviceData.activitySegments {
                totalDuration += segment.totalActivityDuration
                for await category in segment.categories {
                    for await appActivity in category.applications {
                        guard let token = appActivity.application.token else { continue }
                        appDurations[token, default: 0] += appActivity.totalActivityDuration
                    }
                }
            }
        }

        let topApps = appDurations
            .sorted { $0.value > $1.value }
            .prefix(5)
            .map { TopAppUsage(token: $0.key, duration: $0.value) }

        persistTotals(totalDuration: totalDuration)

        return DailySummaryConfiguration(
            totalDuration: totalDuration,
            topApps: Array(topApps)
        )
    }

    private func persistTotals(totalDuration: TimeInterval) {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        if let previousDay = SharedSelectionStore.reportDayStart,
           !calendar.isDate(previousDay, inSameDayAs: todayStart) {
            SharedSelectionStore.yesterdayTotalSeconds = SharedSelectionStore.todayTotalSeconds
        }
        SharedSelectionStore.reportDayStart = todayStart
        SharedSelectionStore.todayTotalSeconds = totalDuration
    }
}

struct DailySummaryConfiguration {
    var totalDuration: TimeInterval
    var topApps: [TopAppUsage]
}

struct TopAppUsage: Identifiable {
    var id: ApplicationToken { token }
    let token: ApplicationToken
    let duration: TimeInterval
}

struct DailySummaryView: View {
    let configuration: DailySummaryConfiguration

    var body: some View {
        topAppsList
            .padding(.vertical, 2)
            .environment(\.layoutDirection, SharedLocalization.languageCode == "ar" ? .rightToLeft : .leftToRight)
    }

    private var topAppsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            if configuration.topApps.isEmpty {
                Text(RL("report.no_usage"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                let maxDuration = max(configuration.topApps.first?.duration ?? 1, 1)
                ForEach(configuration.topApps) { item in
                    TopAppRowView(item: item, maxDuration: maxDuration)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct TopAppRowView: View {
    let item: TopAppUsage
    let maxDuration: TimeInterval

    private var progress: Double {
        guard maxDuration > 0 else { return 0 }
        return min(max(item.duration / maxDuration, 0), 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Label(item.token)
                    .labelStyle(.iconOnly)
                    .frame(width: 28, height: 28)

                Label(item.token)
                    .labelStyle(.titleOnly)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .layoutPriority(0)

                Text(formatDuration(item.duration))
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: true, vertical: false)
                    .layoutPriority(1)
            }

            UsageProgressBar(progress: progress)
        }
    }
}

private struct UsageProgressBar: View {
    let progress: Double

    var body: some View {
        Capsule()
            .fill(Color.gray.opacity(0.2))
            .overlay(alignment: .leading) {
                Capsule()
                    .fill(Color.green.opacity(0.85))
                    .scaleEffect(x: progress, y: 1, anchor: .leading)
            }
            .frame(height: 6)
            .frame(maxWidth: .infinity)
    }
}
