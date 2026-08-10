import SwiftUI

struct CheckInView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var step = 1
    @State private var feeling: Feeling?
    @State private var urge: UrgeLevel?
    @State private var finished = false

    var body: some View {
        NavigationStack {
            Group {
                if finished || store.hasCheckedInToday {
                    completionView
                } else if step == 1 {
                    feelingStep
                } else {
                    urgeStep
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .animation(.spring(response: 0.5, dampingFraction: 0.85), value: step)
            .animation(.spring(response: 0.5, dampingFraction: 0.85), value: finished)
            .navigationTitle(L("checkin.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L("common.close")) { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .dismissKeyboardOnTap()
    }

    private var feelingStep: some View {
        VStack(spacing: 16) {
            Text(L("checkin.feeling.question"))
                .font(.title2.bold())
                .multilineTextAlignment(.center)
                .padding(.top, 8)
            VStack(spacing: 12) {
                ForEach(Array(Feeling.allCases.enumerated()), id: \.element.id) { index, option in
                    OptionCard(
                        title: option.title,
                        icon: option.icon,
                        isSelected: feeling == option,
                        action: {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                feeling = option
                                step = 2
                            }
                        }
                    )
                    .stagger(index)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }

    private var urgeStep: some View {
        VStack(spacing: 16) {
            Text(L("checkin.urge.question"))
                .font(.title2.bold())
                .multilineTextAlignment(.center)
                .padding(.top, 8)
            VStack(spacing: 12) {
                ForEach(Array(UrgeLevel.allCases.enumerated()), id: \.element.id) { index, option in
                    OptionCard(
                        title: option.title,
                        subtitle: urgeSubtitle(option),
                        icon: option.icon,
                        isSelected: urge == option,
                        action: { urge = option }
                    )
                    .stagger(index)
                }
            }
            Spacer()
            PrimaryButton(title: L("checkin.button.complete"), systemImage: "checkmark.circle.fill") {
                guard let feeling, let urge else { return }
                store.completeCheckIn(feeling: feeling, urge: urge)
                if store.celebrationMilestone != nil {
                    dismiss()
                } else {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        finished = true
                    }
                }
            }
            .opacity(urge == nil ? 0.5 : 1)
            .allowsHitTesting(urge != nil)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }

    private var completionView: some View {
        VStack(spacing: 24) {
            CelebrationView(
                emoji: "✅",
                title: L("checkin.complete.title"),
                subtitle: L("checkin.complete.subtitle")
            )
            PrimaryButton(title: L("common.done"), systemImage: "checkmark") { dismiss() }
        }
        .padding(24)
        .transition(.scale.combined(with: .opacity))
    }

    private func urgeSubtitle(_ level: UrgeLevel) -> String {
        switch level {
        case .low: return L("checkin.urge.low_subtitle")
        case .medium: return L("checkin.urge.medium_subtitle")
        case .high: return L("checkin.urge.high_subtitle")
        }
    }
}
