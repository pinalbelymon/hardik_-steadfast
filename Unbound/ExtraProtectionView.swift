import SwiftUI

struct ExtraProtectionView: View {
    @Environment(BlockingStore.self) private var blocking
    @Environment(\.dismiss) private var dismiss

    @State private var activated = false
    @State private var pulse = false

    var body: some View {
        Group {
            if activated {
                activatedView
            } else {
                optionsView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: activated)
        .navigationTitle(L("protection.title"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var optionsView: some View {
        VStack(spacing: 18) {
            Text(L("protection.need_extra"))
                .font(.title2.bold())
                .padding(.top, 24)
            Text(L("protection.block_description"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            VStack(spacing: 12) {
                ForEach([QuickBlockOption.thirtyMinutes, .oneHour, .threeHours], id: \.self) { option in
                    Button {
                        blocking.startQuickBlock(option)
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { activated = true }
                    } label: {
                        HStack {
                            Image(systemName: "shield.fill").foregroundStyle(Theme.accent)
                            Text(option.title).font(.headline)
                            Spacer()
                            Image(systemName: "chevron.right").font(.footnote.bold()).foregroundStyle(.tertiary)
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
            .padding(.horizontal, 24)
            Spacer()
            Button(L("protection.no_thanks")) { dismiss() }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.bottom, 12)
        }
        .transition(.scale.combined(with: .opacity))
    }

    private var activatedView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Theme.accent.opacity(0.15))
                    .frame(width: 180, height: 180)
                    .scaleEffect(pulse ? 1.1 : 0.9)
                    .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: pulse)
                Image(systemName: "shield.checkered")
                    .font(.system(size: 72))
                    .foregroundStyle(Theme.accent)
                    .symbolEffect(.bounce, value: activated)
            }
            .frame(height: 200)
            .onAppear { pulse = true }
            Text(L("protection.activated"))
                .font(.title2.bold())
            Text(L("protection.urge_pass"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            PrimaryButton(title: L("common.done"), systemImage: "checkmark") { dismiss() }
                .padding(.horizontal, 24)
        }
        .transition(.scale.combined(with: .opacity))
    }
}
