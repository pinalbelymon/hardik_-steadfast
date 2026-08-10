import SwiftUI

struct ExercisesView: View {
    @Environment(ExerciseStore.self) private var exerciseStore

    @State private var searchText = ""
    @State private var selectedCategory: ExerciseCategory?
    @State private var durationFilter: DurationFilter = .all
    @State private var showFavoritesOnly = false

    private enum DurationFilter: String, CaseIterable, Identifiable {
        case all
        case oneToTwo
        case threeToFive
        case fivePlus

        var id: String { rawValue }

        var title: String {
            switch self {
            case .all: return L("exercises.filter.all")
            case .oneToTwo: return L("exercises.filter.1_2_min")
            case .threeToFive: return L("exercises.filter.3_5_min")
            case .fivePlus: return L("exercises.filter.5_plus_min")
            }
        }
    }

    private var filtered: [Exercise] {
        exerciseStore.available(showFavoritesOnly: showFavoritesOnly)
            .filter { exercise in
                (selectedCategory == nil || exercise.category == selectedCategory)
                    && matchesDuration(exercise)
                    && (searchText.isEmpty || exercise.localizedTitle.localizedCaseInsensitiveContains(searchText))
            }
    }

    private func matchesDuration(_ exercise: Exercise) -> Bool {
        switch durationFilter {
        case .all: return true
        case .oneToTwo: return (1...2).contains(exercise.minutes)
        case .threeToFive: return (3...5).contains(exercise.minutes)
        case .fivePlus: return exercise.minutes > 5
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                headerCount
                searchField
                categoryChips
                favoritesRow
                if filtered.isEmpty {
                    ContentUnavailableView(
                        L("exercises.empty.title"),
                        systemImage: "magnifyingglass",
                        description: Text(L("exercises.empty.description"))
                    )
                    .padding(.top, 30)
                } else {
                    LazyVStack(spacing: 10) {
                        ForEach(filtered) { exercise in
                            NavigationLink {
                                ExerciseDetailView(exercise: exercise)
                            } label: {
                                exerciseRow(exercise)
                            }
                            .buttonStyle(PressableButtonStyle())
                        }
                    }
                }
            }
            .padding()
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(L("exercises.title"))
        .navigationBarTitleDisplayMode(.large)
        .hidesTabBar()
        .dismissKeyboardOnTap()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    ForEach(DurationFilter.allCases) { filter in
                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                durationFilter = filter
                            }
                        } label: {
                            if durationFilter == filter {
                                Label(filter.title, systemImage: "checkmark")
                            } else {
                                Text(filter.title)
                            }
                        }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(Theme.accent)
                }
                .accessibilityLabel(L("exercises.filter.accessibility"))
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: filtered)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: searchText)
    }

    private var headerCount: some View {
        HStack {
            Text(L("exercises.count", Exercise.all.count))
                .font(.footnote)
                .foregroundStyle(.secondary)
            Spacer()
            if durationFilter != .all {
                Text(durationFilter.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Theme.accent.opacity(0.12), in: Capsule())
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            TextField(L("exercises.search.placeholder"), text: $searchText)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .background(
            Color(uiColor: .secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
    }

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: L("exercises.filter.all"), isSelected: selectedCategory == nil) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { selectedCategory = nil }
                }
                ForEach(ExerciseCategory.allCases) { category in
                    FilterChip(title: category.title, isSelected: selectedCategory == category) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { selectedCategory = category }
                    }
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private var favoritesRow: some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                showFavoritesOnly.toggle()
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: showFavoritesOnly ? "heart.fill" : "heart")
                    .foregroundStyle(showFavoritesOnly ? .pink : Theme.accent)
                Text(showFavoritesOnly ? L("exercises.favorites.showing") : L("exercises.favorites"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer()
                Text("\(exerciseStore.favoriteCount)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(14)
            .background(
                Color(uiColor: .secondarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(showFavoritesOnly ? Color.pink.opacity(0.5) : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(PressableButtonStyle())
    }

    private func exerciseRow(_ exercise: Exercise) -> some View {
        HStack(spacing: 12) {
            Image(systemName: exercise.category.icon)
                .font(.subheadline)
                .foregroundStyle(Theme.accent)
                .frame(width: 36, height: 36)
                .background(Theme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.localizedTitle)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                HStack(spacing: 6) {
                    Text(exercise.category.title)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Circle().fill(Color(uiColor: .tertiaryLabel)).frame(width: 3, height: 3)
                    Text(L("common.min", exercise.minutes))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    if exerciseStore.isFavorite(exercise.id) {
                        Image(systemName: "heart.fill")
                            .font(.caption2)
                            .foregroundStyle(.pink)
                    }
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.footnote.bold())
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .background(
            Color(uiColor: .secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
    }
}
