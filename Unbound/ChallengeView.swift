import SwiftUI

struct ChallengeView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var finished = false
    @State private var challengePulse = false

    var body: some View {
        NavigationStack {
            Group {
                if finished || store.challengeCompletedToday {
                    completionView
                } else {
                    challengeView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: finished)
            .navigationTitle(L("challenge.daily_activity"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L("common.close")) { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var challengeView: some View {
        VStack(spacing: 20) {
            Text(store.todayChallenge.emoji)
                .font(.system(size: 76))
                .scaleEffect(challengePulse ? 1.06 : 0.94)
                .padding(.top, 24)
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                        challengePulse = true
                    }
                }
            Text(store.todayChallenge.title)
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            Label(store.todayChallenge.duration, systemImage: "timer")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(store.todayChallenge.description)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
            Text(L("challenge.keep_simple"))
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
            Spacer()
            PrimaryButton(title: L("challenge.i_did_it"), systemImage: "checkmark.seal.fill") {
                store.completeTodayChallenge()
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    finished = true
                }
            }
            .padding(.bottom, 24)
        }
        .padding(.horizontal, 24)
        .transition(.scale.combined(with: .opacity))
    }

    private var completionView: some View {
        VStack(spacing: 24) {
            CelebrationView(
                emoji: "🌿",
                title: L("challenge.complete_title"),
                subtitle: L("challenge.complete_subtitle")
            )
            PrimaryButton(title: L("common.done"), systemImage: "checkmark") { dismiss() }
        }
        .padding(24)
        .transition(.scale.combined(with: .opacity))
    }
}
