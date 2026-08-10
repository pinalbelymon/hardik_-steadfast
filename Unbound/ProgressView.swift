import SwiftUI

struct UserProgressView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                NavigationLink {
                    MilestonesView()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "flag.fill")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(Theme.accent, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(L("progress.milestones.title"))
                                .font(.subheadline.weight(.semibold))
                            Text(L("progress.milestones.unlocked",
                                   Milestone.all.filter { store.isMilestoneEarned($0) }.count,
                                   Milestone.all.count))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.footnote.bold())
                            .foregroundStyle(.tertiary)
                    }
                    .padding(16)
                    .background(
                        Color(uiColor: .secondarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                    )
                }
                .buttonStyle(PressableButtonStyle())
                .stagger(0)

                HStack(spacing: 12) {
                    StatCard(value: "\(store.currentStreak)", label: L("progress.stat.current_streak"), icon: "flame.fill")
                    StatCard(value: "\(store.bestStreak)", label: L("progress.stat.best_streak"), icon: "trophy.fill")
                }
                .stagger(1)

                StatCard(value: "\(store.totalSuccessfulDays)", label: L("progress.stat.total_days"), icon: "calendar.badge.checkmark")
                    .stagger(2)

                if let next = store.nextMilestone {
                    nextMilestoneCard(next)
                        .stagger(3)
                }

                journeySection
                    .stagger(4)
            }
            .padding()
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(L("progress.title"))
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: store.bestStreak)
    }

    private func nextMilestoneCard(_ next: Milestone) -> some View {
        let progress = min(Double(store.bestStreak) / Double(next.day), 1)
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(L("progress.next_milestone.title"))
                    .font(.headline)
                Spacer()
                Text(L("progress.next_milestone.progress", min(store.bestStreak, next.day), next.day))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(L("progress.next_milestone.at_day", next.title, next.day))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(uiColor: .tertiarySystemFill))
                    Capsule()
                        .fill(LinearGradient(
                            colors: [Theme.accent, Theme.accent.opacity(0.6)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 10)
        }
        .glassCard()
    }

    private var journeySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L("progress.journey.title"))
                .font(.title3.bold())
            HStack {
                ForEach([1, 7, 14, 30, 60, 90], id: \.self) { day in
                    journeyDay(day)
                    if day != 90 { Spacer() }
                }
            }
        }
        .glassCard()
    }

    private func journeyDay(_ day: Int) -> some View {
        let reached = store.bestStreak >= day
        return VStack(spacing: 6) {
            Image(systemName: reached ? "checkmark" : "lock.fill")
                .font(.caption.bold())
                .foregroundStyle(reached ? .white : Color(uiColor: .secondaryLabel))
                .frame(width: 30, height: 30)
                .background(reached ? Theme.accent : Color(uiColor: .tertiarySystemFill), in: Circle())
                .symbolEffect(.bounce, value: reached)
            Text(L("milestone.day_label", day))
                .font(.caption2)
                .foregroundStyle(reached ? .primary : .secondary)
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: store.bestStreak)
    }
}
