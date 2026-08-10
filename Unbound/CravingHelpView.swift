import SwiftUI

struct CravingHelpView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var destination: Destination?
    @State private var pulse = false

    private enum Destination: Hashable {
        case calm
        case rescue(RescueAction)
        case blocking
    }

    var body: some View {
        NavigationStack {
            menu
                .navigationDestination(item: $destination) { dest in
                    switch dest {
                    case .calm:
                        BreathingView()
                    case .rescue(let action):
                        RescueActionView(action: action)
                    case .blocking:
                        ExtraProtectionView()
                    }
                }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private var menu: some View {
        VStack(spacing: 22) {
            VStack(spacing: 6) {
                Text(L("craving.take_breath"))
                    .font(.title.bold())
                Text(L("craving.urge_will_pass"))
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 20)

            breatheButton
                .padding(.vertical, 6)

            VStack(spacing: 12) {
                rescueButton(L("craving.distract_me"), icon: "gamecontroller.fill", color: .blue) {
                    destination = .rescue(RescueAction.distract.randomElement() ?? RescueAction(emoji: "💧", titleKey: "rescue.drink_water"))
                }
                rescueButton(L("craving.calm_me"), icon: "wind", color: Theme.accent) {
                    destination = .calm
                }
                rescueButton(L("craving.give_challenge"), icon: "bolt.fill", color: .orange) {
                    destination = .rescue(RescueAction.challenge.randomElement() ?? RescueAction(emoji: "🌬️", titleKey: "rescue.deep_breaths"))
                }
                rescueButton(L("craving.block_apps"), icon: "shield.fill", color: Theme.accent) {
                    destination = .blocking
                }
            }

            Spacer()

            Button(L("common.close")) { dismiss() }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.bottom, 8)
        }
        .padding(.horizontal, 24)
        .navigationTitle(L("craving.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(L("common.close")) { dismiss() }
            }
        }
    }

    private var breatheButton: some View {
        Button {
            destination = .calm
        } label: {
            ZStack {
                Circle()
                    .stroke(Theme.accent.opacity(0.3), lineWidth: 3)
                    .frame(width: 168, height: 168)
                    .scaleEffect(pulse ? 1.25 : 0.9)
                    .opacity(pulse ? 0 : 0.7)
                Circle()
                    .fill(Theme.accent.opacity(0.14))
                    .frame(width: 168, height: 168)
                VStack(spacing: 4) {
                    Image(systemName: "wind")
                        .font(.system(size: 34))
                    Text(L("craving.breathe"))
                        .font(.headline)
                }
                .foregroundStyle(Theme.accent)
            }
        }
        .buttonStyle(PressableButtonStyle())
        .onAppear {
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }

    private func rescueButton(_ title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundStyle(color)
                    .frame(width: 40, height: 40)
                    .background(color.opacity(0.15), in: Circle())
                Text(title)
                    .font(.headline)
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
    }
}

struct RescueActionView: View {
    let action: RescueAction

    @Environment(\.dismiss) private var dismiss
    @State private var done = false
    @State private var pulse = false

    var body: some View {
        VStack(spacing: 26) {
            Spacer()
            ZStack {
                Circle()
                    .stroke(Theme.accent.opacity(0.25), lineWidth: 3)
                    .frame(width: 200, height: 200)
                    .scaleEffect(pulse ? 1.15 : 0.9)
                    .opacity(pulse ? 0 : 0.7)
                Circle()
                    .fill(Theme.accent.opacity(0.1))
                    .frame(width: 200, height: 200)
                Text(action.emoji)
                    .font(.system(size: 72))
            }
            .frame(height: 220)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }

            VStack(spacing: 8) {
                Text(action.title)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                Text(L("craving.stay_present"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if done {
                Label(L("craving.got_through"), systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .foregroundStyle(Theme.accent)
                    .transition(.scale.combined(with: .opacity))
            } else {
                PrimaryButton(title: L("craving.i_got_through"), systemImage: "checkmark") {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                        done = true
                    }
                    Task {
                        try? await Task.sleep(for: .seconds(1.4))
                        dismiss()
                    }
                }
                .transition(.scale.combined(with: .opacity))
            }

            Button(L("craving.not_yet")) { dismiss() }
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: done)
        .padding(24)
        .navigationTitle(L("craving.keep_going"))
        .navigationBarTitleDisplayMode(.inline)
    }
}
