import SwiftUI

struct ExerciseDetailView: View {
    let exercise: Exercise

    @Environment(ExerciseStore.self) private var exerciseStore
    @Environment(\.dismiss) private var dismiss

    @State private var running = false
    @State private var completed = false

    var body: some View {
        Group {
            if completed {
                completionView
            } else if running {
                ExerciseRunnerView(exercise: exercise) {
                    exerciseStore.complete(exercise)
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { completed = true }
                } onClose: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { running = false }
                }
            } else {
                detailView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: running)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: completed)
        .navigationTitle(exercise.localizedTitle)
        .navigationBarTitleDisplayMode(.inline)
        .hidesTabBar()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                        exerciseStore.toggleFavorite(exercise.id)
                    }
                } label: {
                    Image(systemName: exerciseStore.isFavorite(exercise.id) ? "heart.fill" : "heart")
                        .foregroundStyle(exerciseStore.isFavorite(exercise.id) ? .pink : Theme.accent)
                }
            }
        }
    }

    private var detailView: some View {
        VStack(spacing: 22) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Theme.accent.opacity(0.12))
                    .frame(width: 170, height: 170)
                Image(systemName: exercise.category.icon)
                    .font(.system(size: 64))
                    .foregroundStyle(Theme.accent)
            }
            .frame(height: 190)
            Text(exercise.localizedTitle)
                .font(.title2.bold())
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            HStack(spacing: 8) {
                Label(L("common.min", exercise.minutes), systemImage: "timer")
                Text("·")
                Label(exercise.category.title, systemImage: exercise.category.icon)
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            Text(exercise.localizedDescription)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
            PrimaryButton(title: L("exercise.start"), systemImage: "play.fill") {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { running = true }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.calmGradient)
        .transition(.scale.combined(with: .opacity))
    }

    private var completionView: some View {
        VStack(spacing: 26) {
            Spacer()
            CelebrationView(
                emoji: "✨",
                title: L("exercise.nice_work"),
                subtitle: L("exercise.completed", exercise.localizedTitle)
            )
            PrimaryButton(title: L("common.done"), systemImage: "checkmark") { dismiss() }
                .padding(.horizontal, 24)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.scale.combined(with: .opacity))
    }
}

struct ExerciseRunnerView: View {
    let exercise: Exercise
    let onComplete: () -> Void
    let onClose: () -> Void

    @State private var remaining: Int
    @State private var total: Int
    @State private var progress: Double = 0
    @State private var task: Task<Void, Never>?

    init(exercise: Exercise, onComplete: @escaping () -> Void, onClose: @escaping () -> Void) {
        self.exercise = exercise
        self.onComplete = onComplete
        self.onClose = onClose
        let seconds = max(Int(exercise.minutes * 60), 60)
        _remaining = State(initialValue: seconds)
        _total = State(initialValue: seconds)
    }

    var body: some View {
        VStack(spacing: 24) {
            Text(L("exercise.stay_with_it"))
                .font(.title3.bold())
            ZStack {
                ProgressRingView(progress: progress, lineWidth: 14, size: 220)
                VStack(spacing: 4) {
                    Text(timeString(remaining))
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                    Text(exercise.localizedTitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            }
            Text(encouragement)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            VStack(spacing: 10) {
                PrimaryButton(title: L("exercise.i_finished"), systemImage: "checkmark.seal.fill") {
                    complete()
                }
                .padding(.horizontal, 24)
                Button(L("exercise.close_early")) { onClose() }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.calmGradient)
        .onAppear { start() }
        .onDisappear { task?.cancel() }
    }

    private var encouragement: String {
        if [.breathing, .mindfulness, .emergency].contains(exercise.category) {
            return L("exercise.encouragement.breathe")
        }
        return L("exercise.encouragement.general")
    }

    private func start() {
        task = Task {
            while remaining > 0 {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                remaining -= 1
                withAnimation(.linear(duration: 0.4)) {
                    progress = Double(total - remaining) / Double(total)
                }
            }
            guard !Task.isCancelled else { return }
            complete()
        }
    }

    private func complete() {
        task?.cancel()
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            progress = 1
        }
        onComplete()
    }

    private func timeString(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}
