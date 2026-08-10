import SwiftUI

enum ExerciseCategory: String, CaseIterable, Codable, Identifiable {
    case quickReset, breathing, mindfulness, physicalActivity, distraction, focus,
         selfReflection, environmentReset, digitalDetox, confidence, sleep,
         stressManagement, triggerAwareness, habitBuilding, gratitude,
         socialConnection, productivity, emergency

    var id: String { rawValue }

    var title: String {
        switch self {
        case .quickReset: return L("exercise_category.quick_reset")
        case .breathing: return L("exercise_category.breathing")
        case .mindfulness: return L("exercise_category.mindfulness")
        case .physicalActivity: return L("exercise_category.physical_activity")
        case .distraction: return L("exercise_category.distraction")
        case .focus: return L("exercise_category.focus")
        case .selfReflection: return L("exercise_category.self_reflection")
        case .environmentReset: return L("exercise_category.environment_reset")
        case .digitalDetox: return L("exercise_category.digital_detox")
        case .confidence: return L("exercise_category.confidence")
        case .sleep: return L("exercise_category.sleep")
        case .stressManagement: return L("exercise_category.stress_management")
        case .triggerAwareness: return L("exercise_category.trigger_awareness")
        case .habitBuilding: return L("exercise_category.habit_building")
        case .gratitude: return L("exercise_category.gratitude")
        case .socialConnection: return L("exercise_category.social_connection")
        case .productivity: return L("exercise_category.productivity")
        case .emergency: return L("exercise_category.emergency")
        }
    }

    var icon: String {
        switch self {
        case .quickReset: return "arrow.clockwise"
        case .breathing: return "wind"
        case .mindfulness: return "leaf.fill"
        case .physicalActivity: return "figure.run"
        case .distraction: return "sparkles"
        case .focus: return "scope"
        case .selfReflection: return "book.fill"
        case .environmentReset: return "house.fill"
        case .digitalDetox: return "iphone.slash"
        case .confidence: return "heart.fill"
        case .sleep: return "moon.fill"
        case .stressManagement: return "brain.head.profile"
        case .triggerAwareness: return "exclamationmark.triangle.fill"
        case .habitBuilding: return "arrow.triangle.2.circlepath"
        case .gratitude: return "hands.sparkles.fill"
        case .socialConnection: return "person.2.fill"
        case .productivity: return "checklist"
        case .emergency: return "waveform.path.ecg"
        }
    }
}

struct Exercise: Identifiable, Hashable, Codable {
    let id: Int
    let title: String
    let category: ExerciseCategory
    let minutes: Int

    var localizedTitle: String { L("exercise.\(id)") }

    var localizedDescription: String {
        let key = "exercise.\(id).desc"
        let localized = L(key)
        return localized == key ? L("exercise.description") : localized
    }
}
