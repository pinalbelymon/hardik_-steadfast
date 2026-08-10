import SwiftUI

struct BreathingView: View {
    @Environment(\.dismiss) private var dismiss

    private enum Phase {
        case inhale, hold, exhale

        var title: String {
            switch self {
            case .inhale: return L("breathing.inhale")
            case .hold: return L("breathing.hold")
            case .exhale: return L("breathing.exhale")
            }
        }

        var duration: Int {
            switch self {
            case .inhale: return 4
            case .hold: return 4
            case .exhale: return 6
            }
        }

        var targetScale: CGFloat {
            switch self {
            case .inhale: return 1.0
            case .hold: return 1.0
            case .exhale: return 0.55
            }
        }
    }

    @State private var phase: Phase = .inhale
    @State private var countdown = 4
    @State private var scale: CGFloat = 0.55
    @State private var cycles = 0
    @State private var runningTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Theme.accent.opacity(0.08))
                    .frame(width: 260, height: 260)
                Circle()
                    .fill(Theme.accent.opacity(0.14))
                    .frame(width: 220, height: 220)
                Circle()
                    .fill(RadialGradient(
                        colors: [Theme.accent, Theme.accent.opacity(0.55)],
                        center: .center,
                        startRadius: 10,
                        endRadius: 110
                    ))
                    .frame(width: 180, height: 180)
                    .scaleEffect(scale)
                VStack(spacing: 4) {
                    Text(phase.title)
                        .font(.title2.bold())
                    Text("\(countdown)")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .animation(.easeInOut(duration: 0.3), value: countdown)
                }
                .foregroundStyle(.white)
            }
            .frame(height: 300)

            Text(L("breathing.with_circle"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(cycles > 0 ? L("breathing.completed_rounds", cycles, cycles == 1 ? L("breathing.round") : L("breathing.rounds")) : "")
                .font(.caption)
                .foregroundStyle(.secondary)
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: cycles)

            Spacer()

            PrimaryButton(title: L("common.done"), systemImage: "checkmark") { dismiss() }
        }
        .padding(24)
        .navigationTitle(L("breathing.calm"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { start() }
        .onDisappear { runningTask?.cancel() }
    }

    private func start() {
        runningTask = Task {
            while !Task.isCancelled {
                for next in [Phase.inhale, .hold, .exhale] {
                    guard !Task.isCancelled else { return }
                    phase = next
                    countdown = next.duration
                    withAnimation(.easeInOut(duration: TimeInterval(next.duration))) {
                        scale = next.targetScale
                    }
                    for second in stride(from: next.duration, through: 1, by: -1) {
                        countdown = second
                        try? await Task.sleep(for: .seconds(1))
                        guard !Task.isCancelled else { return }
                    }
                }
                cycles += 1
            }
        }
    }
}
