import SwiftUI

struct MilestonesView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                headerCard
                    .stagger(0)
                ForEach(Array(Milestone.all.enumerated()), id: \.element.id) { index, milestone in
                    milestoneRow(milestone)
                        .stagger(index + 1)
                }
            }
            .padding()
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(L("milestones.title"))
        .hidesTabBar()
    }

    private var headerCard: some View {
        let unlocked = Milestone.all.filter { store.isMilestoneEarned($0) }.count
        let total = Milestone.all.count
        let progress = Double(unlocked) / Double(total)
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(L("milestones.unlocked_count", unlocked, total))
                    .font(.headline)
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
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

    private func milestoneRow(_ milestone: Milestone) -> some View {
        let unlocked = store.isMilestoneEarned(milestone)
        return HStack(spacing: 14) {
            Image(systemName: milestone.icon)
                .font(.title3)
                .foregroundStyle(unlocked ? .white : Color(uiColor: .secondaryLabel))
                .frame(width: 46, height: 46)
                .background(
                    unlocked ? Theme.accent : Color(uiColor: .tertiarySystemFill),
                    in: RoundedRectangle(cornerRadius: 13, style: .continuous)
                )
                .symbolEffect(.bounce, value: unlocked)
            VStack(alignment: .leading, spacing: 2) {
                Text(milestone.title)
                    .font(.headline)
                    .foregroundStyle(unlocked ? .primary : .secondary)
                Text(L("milestone.day_label", milestone.day))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if unlocked {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(Theme.accent)
                    .symbolEffect(.bounce, value: unlocked)
            } else {
                Image(systemName: "lock.fill")
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(16)
        .background(
            Color(uiColor: .secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: store.bestStreak)
    }
}
