import Foundation
import Observation

@Observable
final class ExerciseStore {
    private static let key = "unbound.exercises.v1"

    var completedIDs: [Int]
    var favoriteIDs: Set<Int>
    var lastCompletedID: Int?
    var dailyExerciseDate: Date?
    var completedCountByCategory: [String: Int]

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.key),
           let decoded = try? JSONDecoder().decode(PersistedExercises.self, from: data) {
            completedIDs = decoded.completedIDs
            favoriteIDs = Set(decoded.favoriteIDs)
            lastCompletedID = decoded.lastCompletedID
            dailyExerciseDate = decoded.dailyExerciseDate
            completedCountByCategory = decoded.completedCountByCategory
        } else {
            completedIDs = []
            favoriteIDs = []
            lastCompletedID = nil
            dailyExerciseDate = nil
            completedCountByCategory = [:]
        }
    }

    var completedCount: Int { completedIDs.count }

    var favoriteCount: Int { favoriteIDs.count }

    var doneToday: Bool {
        guard let date = dailyExerciseDate else { return false }
        return date.isSameDay(as: Date())
    }

    var lastCompleted: Exercise? {
        guard let id = lastCompletedID else { return nil }
        return Exercise.all.first { $0.id == id }
    }

    var mostUsedCategory: ExerciseCategory? {
        guard let max = completedCountByCategory.max(by: { $0.value < $1.value }) else { return nil }
        return ExerciseCategory(rawValue: max.key)
    }

    func available(showFavoritesOnly: Bool) -> [Exercise] {
        showFavoritesOnly ? Exercise.all.filter { favoriteIDs.contains($0.id) } : Exercise.all
    }

    func isFavorite(_ id: Int) -> Bool {
        favoriteIDs.contains(id)
    }

    func toggleFavorite(_ id: Int) {
        if favoriteIDs.contains(id) {
            favoriteIDs.remove(id)
        } else {
            favoriteIDs.insert(id)
        }
        save()
    }

    func complete(_ exercise: Exercise) {
        completedIDs.append(exercise.id)
        lastCompletedID = exercise.id
        dailyExerciseDate = Date()
        completedCountByCategory[exercise.category.rawValue, default: 0] += 1
        save()
    }

    func dailyExercise(appStore: AppStore) -> Exercise {
        let pool: [Exercise]
        if appStore.todayUrge == .high || appStore.todayFeeling == .struggling {
            pool = Exercise.all.filter { $0.category == .emergency }
        } else if appStore.todayFeeling == .great || appStore.todayFeeling == .good {
            pool = Exercise.all.filter { $0.category == .confidence || $0.category == .gratitude }
        } else {
            pool = Exercise.all.filter { [.quickReset, .breathing, .mindfulness].contains($0.category) }
        }
        let candidates = pool.filter { $0.id != lastCompletedID }
        let source = candidates.isEmpty ? pool : candidates
        let day = Calendar.current.ordinality(of: .day, in: .era, for: Date()) ?? 1
        return source[(day - 1) % source.count]
    }

    private func save() {
        let state = PersistedExercises(
            completedIDs: completedIDs,
            favoriteIDs: Array(favoriteIDs),
            lastCompletedID: lastCompletedID,
            dailyExerciseDate: dailyExerciseDate,
            completedCountByCategory: completedCountByCategory
        )
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: Self.key)
        }
    }
}

private struct PersistedExercises: Codable {
    var completedIDs: [Int]
    var favoriteIDs: [Int]
    var lastCompletedID: Int?
    var dailyExerciseDate: Date?
    var completedCountByCategory: [String: Int]
}
