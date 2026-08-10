import SwiftUI

struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct PrimaryButton: View {
    let title: String
    var systemImage: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.capsule)
        .controlSize(.regular)
    }
}

struct OptionCard: View {
    let title: String
    var subtitle: String? = nil
    let icon: String
    var isSelected: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundStyle(isSelected ? .white : Theme.accent)
                    .frame(width: 42, height: 42)
                    .background(
                        isSelected ? Theme.accent : Theme.accent.opacity(0.12),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )
                    .symbolEffect(.bounce, value: isSelected)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                    if let subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Theme.accent : Color(uiColor: .tertiaryLabel))
            }
            .padding(16)
            .background(
                Color(uiColor: .secondarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isSelected ? Theme.accent : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(PressableButtonStyle())
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isSelected)
    }
}

struct StatCard: View {
    let value: String
    let label: String
    var icon: String? = nil

    var body: some View {
        VStack(spacing: 6) {
            if let icon {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundStyle(Theme.accent)
            }
            Text(value)
                .font(.system(.title, design: .rounded, weight: .bold))
                .contentTransition(.numericText())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .padding(.horizontal, 8)
        .background(
            Color(uiColor: .secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
    }
}

struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat = Theme.cardCornerRadius

    func body(content: Content) -> some View {
        content
            .padding(20)
            .continuousCard(cornerRadius: cornerRadius)
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = Theme.cardCornerRadius) -> some View {
        modifier(GlassCard(cornerRadius: cornerRadius))
    }

    /// Applies iOS continuous (squircle) card background with optional border.
    func continuousCard(
        cornerRadius: CGFloat = Theme.cardCornerRadius,
        fill: Color = Color(uiColor: .secondarySystemGroupedBackground),
        border: Color? = nil,
        borderWidth: CGFloat = 1
    ) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        return background(fill, in: shape)
            .clipShape(shape)
            .overlay {
                if let border {
                    shape.stroke(border, lineWidth: borderWidth)
                }
            }
    }
}

struct StaggerAppear: ViewModifier {
    let index: Int
    @State private var appeared = false

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 22)
            .scaleEffect(appeared ? 1 : 0.96)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.82).delay(Double(index) * 0.08)) {
                    appeared = true
                }
            }
    }
}

extension View {
    func stagger(_ index: Int) -> some View {
        modifier(StaggerAppear(index: index))
    }
}

struct CelebrationView: View {
    let emoji: String
    let title: String
    var subtitle: String? = nil

    @State private var appeared = false
    @State private var burst = false

    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                ForEach(0..<10, id: \.self) { index in
                    Image(systemName: "sparkle")
                        .font(.system(size: 12 + CGFloat(index % 3) * 4))
                        .foregroundStyle(Theme.accent.opacity(burst ? 0 : 0.9))
                        .offset(sparkleOffset(index))
                        .scaleEffect(burst ? 0.2 : 1)
                }
                Text(emoji)
                    .font(.system(size: 68))
                    .scaleEffect(appeared ? 1 : 0.2)
                    .rotationEffect(.degrees(appeared ? 0 : -20))
            }
            .frame(height: 150)

            VStack(spacing: 6) {
                Text(title)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.55)) {
                appeared = true
            }
            withAnimation(.easeOut(duration: 1.1).delay(0.15)) {
                burst = true
            }
        }
    }

    private func sparkleOffset(_ index: Int) -> CGSize {
        let angle = Double(index) / 10 * 2 * .pi
        let radius = burst ? 92.0 : 28.0
        return CGSize(width: cos(angle) * radius, height: sin(angle) * radius - 8)
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    isSelected ? Theme.accent : Color(uiColor: .secondarySystemGroupedBackground),
                    in: Capsule()
                )
                .foregroundStyle(isSelected ? .white : .primary)
                .overlay(
                    Capsule().stroke(isSelected ? Theme.accent : Color(uiColor: .separator), lineWidth: 1)
                )
        }
        .buttonStyle(PressableButtonStyle())
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isSelected)
    }
}

struct ProgressRingView: View {
    let progress: Double
    var lineWidth: CGFloat = 10
    var size: CGFloat = 120

    @State private var animated = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(uiColor: .tertiarySystemFill), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: animated ? min(max(progress, 0), 1) : 0)
                .stroke(
                    AngularGradient(
                        colors: [Theme.accent, Theme.accent.opacity(0.5), Theme.accent],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.spring(response: 1.0, dampingFraction: 0.8)) {
                animated = true
            }
        }
        .onChange(of: progress) { _, _ in
            withAnimation(.spring(response: 0.8, dampingFraction: 0.85)) {
                animated = true
            }
        }
    }
}

import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

extension View {
    /// Hides the root TabView tab bar while this screen is visible.
    func hidesTabBar() -> some View {
        toolbar(.hidden, for: .tabBar)
    }

    /// Dismisses the keyboard when the user taps outside a text field.
    func dismissKeyboardOnTap() -> some View {
        modifier(DismissKeyboardOnTapModifier())
    }
}

private struct DismissKeyboardOnTapModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.simultaneousGesture(
            TapGesture().onEnded {
                #if canImport(UIKit)
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder),
                    to: nil,
                    from: nil,
                    for: nil
                )
                #endif
            }
        )
    }
}
