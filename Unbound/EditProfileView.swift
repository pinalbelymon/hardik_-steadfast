import SwiftUI

struct EditProfileView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var ageGroup: AgeGroup
    @State private var goal: Goal
    @State private var motivation: Motivation
    @State private var appeared = false

    init(store: AppStore) {
        _ageGroup = State(initialValue: store.ageGroup ?? .eighteenTo24)
        _goal = State(initialValue: store.goal ?? .reduce)
        _motivation = State(initialValue: store.motivation ?? .growth)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    profileSection(
                        title: L("edit_profile.age.title"),
                        subtitle: L("edit_profile.age.subtitle")
                    ) {
                        ForEach(Array(AgeGroup.allCases.enumerated()), id: \.element.id) { index, option in
                            OptionCard(
                                title: option.title,
                                icon: option.icon,
                                isSelected: ageGroup == option,
                                action: { ageGroup = option }
                            )
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 10)
                            .animation(.spring(response: 0.5, dampingFraction: 0.82).delay(Double(index) * 0.04), value: appeared)
                        }
                    }

                    profileSection(
                        title: L("edit_profile.goal.title"),
                        subtitle: L("edit_profile.goal.subtitle")
                    ) {
                        ForEach(Array(Goal.allCases.enumerated()), id: \.element.id) { index, option in
                            OptionCard(
                                title: option.title,
                                icon: option.icon,
                                isSelected: goal == option,
                                action: { goal = option }
                            )
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 10)
                            .animation(.spring(response: 0.5, dampingFraction: 0.82).delay(0.12 + Double(index) * 0.04), value: appeared)
                        }
                    }

                    profileSection(
                        title: L("edit_profile.motivation.title"),
                        subtitle: L("edit_profile.motivation.subtitle")
                    ) {
                        ForEach(Array(Motivation.allCases.enumerated()), id: \.element.id) { index, option in
                            OptionCard(
                                title: option.title,
                                icon: option.icon,
                                isSelected: motivation == option,
                                action: { motivation = option }
                            )
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 10)
                            .animation(.spring(response: 0.5, dampingFraction: 0.82).delay(0.24 + Double(index) * 0.04), value: appeared)
                        }
                    }

                    Button {
                        store.updateProfile(ageGroup: ageGroup, goal: goal, motivation: motivation)
                        dismiss()
                    } label: {
                        Text(L("edit_profile.save"))
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .foregroundStyle(.white)
                            .background(
                                LinearGradient(
                                    colors: [Theme.accent, Theme.accent.opacity(0.75)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                in: Capsule()
                            )
                    }
                    .buttonStyle(PressableButtonStyle())
                    .padding(.top, 8)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle(L("edit_profile.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(L("common.cancel")) { dismiss() }
                }
            }
            .onAppear { appeared = true }
        }
    }

    private func profileSection<Content: View>(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title3.bold())
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            VStack(spacing: 10) {
                content()
            }
        }
    }
}
