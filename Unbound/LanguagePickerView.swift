import SwiftUI

struct LanguagePickerView: View {
    @Environment(LanguageStore.self) private var languageStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section {
                Text(L("settings.language.description"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .listRowBackground(Color.clear)
            }

            Section(L("settings.language.title")) {
                ForEach(AppLanguage.pickerLanguages) { language in
                    Button {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                            languageStore.current = language
                        }
                        dismiss()
                    } label: {
                        HStack(spacing: 14) {
                            Text(language.flag)
                                .font(.title2)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(language.displayName)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                if language.englishName != language.displayName {
                                    Text(language.englishName)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            if languageStore.current == language {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Theme.accent)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle(L("settings.language.title"))
        .navigationBarTitleDisplayMode(.inline)
        .hidesTabBar()
    }
}
