import SwiftUI

enum Theme {
    static let cardCornerRadius: CGFloat = 24

    static let accent = Color.adaptive(
        light: UIColor(red: 0.13, green: 0.58, blue: 0.39, alpha: 1),
        dark: UIColor(red: 0.35, green: 0.80, blue: 0.55, alpha: 1)
    )

    static let treeCanopy = Color.adaptive(
        light: UIColor(red: 0.34, green: 0.63, blue: 0.37, alpha: 1),
        dark: UIColor(red: 0.46, green: 0.76, blue: 0.48, alpha: 1)
    )

    static let treeTrunk = Color.adaptive(
        light: UIColor(red: 0.55, green: 0.41, blue: 0.28, alpha: 1),
        dark: UIColor(red: 0.68, green: 0.52, blue: 0.36, alpha: 1)
    )

    static let flower = Color.adaptive(
        light: UIColor(red: 0.92, green: 0.45, blue: 0.55, alpha: 1),
        dark: UIColor(red: 0.95, green: 0.58, blue: 0.66, alpha: 1)
    )

    static let calmGradient = LinearGradient(
        colors: [Color(uiColor: .systemBackground), accent.opacity(0.12)],
        startPoint: .top,
        endPoint: .bottom
    )
}

extension Color {
    static func adaptive(light: UIColor, dark: UIColor) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }
}
