import SwiftUI

enum Goal: String, CaseIterable, Codable, Identifiable {
    case reduce, quit, selfControl

    var id: String { rawValue }

    var title: String {
        switch self {
        case .reduce: return L("goal.reduce")
        case .quit: return L("goal.quit")
        case .selfControl: return L("goal.self_control")
        }
    }

    var icon: String {
        switch self {
        case .reduce: return "minus.circle.fill"
        case .quit: return "hand.raised.fill"
        case .selfControl: return "brain.head.profile.fill"
        }
    }
}

enum Motivation: String, CaseIterable, Codable, Identifiable {
    case focus, confidence, relationships, time, growth

    var id: String { rawValue }

    var title: String {
        switch self {
        case .focus: return L("motivation.focus")
        case .confidence: return L("motivation.confidence")
        case .relationships: return L("motivation.relationships")
        case .time: return L("motivation.time")
        case .growth: return L("motivation.growth")
        }
    }

    var icon: String {
        switch self {
        case .focus: return "scope"
        case .confidence: return "heart.fill"
        case .relationships: return "person.2.fill"
        case .time: return "clock.fill"
        case .growth: return "sparkles"
        }
    }
}

enum ReminderFrequency: String, CaseIterable, Codable, Identifiable {
    case daily, fewTimesAWeek, none

    var id: String { rawValue }

    var title: String {
        switch self {
        case .daily: return L("reminder.daily")
        case .fewTimesAWeek: return L("reminder.few_times_week")
        case .none: return L("reminder.none")
        }
    }

    var icon: String {
        switch self {
        case .daily: return "bell.fill"
        case .fewTimesAWeek: return "bell.badge.fill"
        case .none: return "bell.slash.fill"
        }
    }
}

enum Feeling: String, CaseIterable, Codable, Identifiable {
    case great, good, okay, struggling

    var id: String { rawValue }

    var title: String {
        switch self {
        case .great: return L("feeling.great")
        case .good: return L("feeling.good")
        case .okay: return L("feeling.okay")
        case .struggling: return L("feeling.struggling")
        }
    }

    var icon: String {
        switch self {
        case .great: return "face.smiling.fill"
        case .good: return "face.smiling"
        case .okay: return "face.dashed"
        case .struggling: return "cloud.rain.fill"
        }
    }

    var color: Color {
        switch self {
        case .great: return Theme.accent
        case .good: return .blue
        case .okay: return .orange
        case .struggling: return .red
        }
    }
}

enum UrgeLevel: String, CaseIterable, Codable, Identifiable {
    case low, medium, high

    var id: String { rawValue }

    var title: String {
        switch self {
        case .low: return L("urge.low")
        case .medium: return L("urge.medium")
        case .high: return L("urge.high")
        }
    }

    var icon: String {
        switch self {
        case .low: return "thermometer.low"
        case .medium: return "thermometer.medium"
        case .high: return "thermometer.high"
        }
    }
}

enum RelapseReason: String, CaseIterable, Codable, Identifiable {
    case stress, boredom, socialMedia, loneliness, habit, other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .stress: return L("relapse.stress")
        case .boredom: return L("relapse.boredom")
        case .socialMedia: return L("relapse.social_media")
        case .loneliness: return L("relapse.loneliness")
        case .habit: return L("relapse.habit")
        case .other: return L("relapse.other")
        }
    }

    var icon: String {
        switch self {
        case .stress: return "tornado"
        case .boredom: return "hourglass"
        case .socialMedia: return "iphone"
        case .loneliness: return "person.crop.circle.dashed"
        case .habit: return "arrow.triangle.2.circlepath"
        case .other: return "ellipsis.circle.fill"
        }
    }
}

enum AgeGroup: String, CaseIterable, Codable, Identifiable {
    case under18, eighteenTo24, twentyFiveTo34, thirtyFiveTo44, fortyFivePlus

    var id: String { rawValue }

    var title: String {
        switch self {
        case .under18: return L("age.under_18")
        case .eighteenTo24: return L("age.18_24")
        case .twentyFiveTo34: return L("age.25_34")
        case .thirtyFiveTo44: return L("age.35_44")
        case .fortyFivePlus: return L("age.45_plus")
        }
    }

    var icon: String {
        switch self {
        case .under18: return "figure.child"
        case .eighteenTo24: return "graduationcap.fill"
        case .twentyFiveTo34: return "briefcase.fill"
        case .thirtyFiveTo44: return "house.fill"
        case .fortyFivePlus: return "hands.sparkles.fill"
        }
    }
}

struct DailyChallenge: Identifiable, Hashable {
    let titleKey: String
    let descriptionKey: String
    let emoji: String
    let durationKey: String

    var id: String { titleKey }
    var title: String { L(titleKey) }
    var description: String { L(descriptionKey) }
    var duration: String { L(durationKey) }

    private static func c(_ title: String, _ desc: String, _ emoji: String, _ duration: String) -> DailyChallenge {
        DailyChallenge(titleKey: title, descriptionKey: desc, emoji: emoji, durationKey: duration)
    }

    // MARK: - Challenge library

    private static let deepBreaths = c("challenge.deep_breaths", "challenge.deep_breaths.desc", "🌬️", "duration.1_min")
    private static let drinkWater = c("challenge.drink_water", "challenge.drink_water.desc", "💧", "duration.1_min")
    private static let jumpingJacks = c("challenge.jumping_jacks", "challenge.jumping_jacks.desc", "🤸", "duration.1_min")
    private static let phoneAway5 = c("challenge.phone_away_5min", "challenge.phone_away_5min.desc", "📵", "duration.5_min")
    private static let grateful = c("challenge.grateful", "challenge.grateful.desc", "✍️", "duration.2_min")
    private static let walk2 = c("challenge.walk_2min", "challenge.walk_2min.desc", "🚶", "duration.2_min")
    private static let name5Things = c("challenge.name_5_things", "challenge.name_5_things.desc", "👀", "duration.1_min")
    private static let mindfulness2 = c("challenge.mindfulness_2min", "challenge.mindfulness_2min.desc", "🧘", "duration.2_min")
    private static let socialMedia5 = c("challenge.social_media_5min", "challenge.social_media_5min.desc", "🌿", "duration.5_min")
    private static let stretch2 = c("challenge.stretch_2min", "challenge.stretch_2min.desc", "🙆", "duration.2_min")
    private static let walk5 = c("challenge.walk_5min", "challenge.walk_5min.desc", "🚶", "duration.5_min")
    private static let listenSong = c("challenge.listen_song", "challenge.listen_song.desc", "🎵", "duration.3_min")
    private static let sitOutside = c("challenge.sit_outside", "challenge.sit_outside.desc", "🌳", "duration.2_min")
    private static let washFace = c("challenge.wash_face", "challenge.wash_face.desc", "💦", "duration.1_min")
    private static let openWindow = c("challenge.open_window", "challenge.open_window.desc", "🪟", "duration.1_min")
    private static let tidyDesk = c("challenge.tidy_desk", "challenge.tidy_desk.desc", "🗂️", "duration.3_min")
    private static let read2Pages = c("challenge.read_2_pages", "challenge.read_2_pages.desc", "📖", "duration.5_min")
    private static let messageFriend = c("challenge.message_friend", "challenge.message_friend.desc", "💬", "duration.3_min")
    private static let squats10 = c("challenge.squats_10", "challenge.squats_10.desc", "🏋️", "duration.2_min")
    private static let journalLine = c("challenge.journal_line", "challenge.journal_line.desc", "📝", "duration.2_min")
    private static let boxBreathing = c("challenge.box_breathing", "challenge.box_breathing.desc", "⬜", "duration.1_min")
    private static let sunlight2 = c("challenge.sunlight_2min", "challenge.sunlight_2min.desc", "☀️", "duration.2_min")
    private static let makeBed = c("challenge.make_bed", "challenge.make_bed.desc", "🛏️", "duration.3_min")
    private static let calmAudio = c("challenge.calm_audio", "challenge.calm_audio.desc", "🎧", "duration.3_min")
    private static let phoneOtherRoom = c("challenge.phone_other_room", "challenge.phone_other_room.desc", "📱", "duration.1_min")
    private static let planTomorrow = c("challenge.plan_tomorrow", "challenge.plan_tomorrow.desc", "📋", "duration.2_min")
    private static let kindSelf = c("challenge.kind_self", "challenge.kind_self.desc", "💛", "duration.1_min")
    private static let digitalBreak10 = c("challenge.digital_break_10", "challenge.digital_break_10.desc", "🔕", "duration.10_min")
    private static let standStretch = c("challenge.stand_stretch", "challenge.stand_stretch.desc", "🧍", "duration.1_min")
    private static let drawSomething = c("challenge.draw_something", "challenge.draw_something.desc", "🎨", "duration.5_min")
    private static let cleanOneArea = c("challenge.clean_one_area", "challenge.clean_one_area.desc", "🧹", "duration.5_min")
    private static let noPhoneMeal = c("challenge.no_phone_meal", "challenge.no_phone_meal.desc", "🍽️", "duration.10_min")
    private static let pushUps5 = c("challenge.pushups_5", "challenge.pushups_5.desc", "💪", "duration.2_min")
    private static let focus5 = c("challenge.focus_5min", "challenge.focus_5min.desc", "🎯", "duration.5_min")
    private static let gratitudeText = c("challenge.gratitude_text", "challenge.gratitude_text.desc", "🙏", "duration.2_min")
    private static let walkOutside = c("challenge.walk_outside", "challenge.walk_outside.desc", "🌤️", "duration.5_min")
    private static let teaBreak = c("challenge.tea_break", "challenge.tea_break.desc", "🍵", "duration.3_min")
    private static let neckStretch = c("challenge.neck_stretch", "challenge.neck_stretch.desc", "🔄", "duration.2_min")
    private static let deleteShortcut = c("challenge.delete_shortcut", "challenge.delete_shortcut.desc", "🗑️", "duration.2_min")

    static func challenges(for ageGroup: AgeGroup) -> [DailyChallenge] {
        switch ageGroup {
        case .under18:
            return [
                deepBreaths, drinkWater, jumpingJacks, phoneAway5, grateful, walk2,
                name5Things, mindfulness2, washFace, openWindow, squats10, standStretch,
                drawSomething, journalLine, boxBreathing, sunlight2, tidyDesk, kindSelf,
            ]
        case .eighteenTo24:
            return [
                deepBreaths, drinkWater, jumpingJacks, walk2, grateful, phoneAway5,
                mindfulness2, socialMedia5, digitalBreak10, messageFriend, deleteShortcut,
                focus5, listenSong, pushUps5, planTomorrow, phoneOtherRoom, calmAudio,
                journalLine, boxBreathing, cleanOneArea,
            ]
        case .twentyFiveTo34:
            return [
                deepBreaths, drinkWater, stretch2, mindfulness2, grateful, walk2,
                phoneAway5, socialMedia5, tidyDesk, planTomorrow, focus5, neckStretch,
                digitalBreak10, phoneOtherRoom, makeBed, teaBreak, journalLine,
                boxBreathing, cleanOneArea, walkOutside,
            ]
        case .thirtyFiveTo44:
            return [
                deepBreaths, drinkWater, stretch2, mindfulness2, grateful, walk5,
                listenSong, socialMedia5, sitOutside, sunlight2, read2Pages, planTomorrow,
                neckStretch, calmAudio, tidyDesk, teaBreak, walkOutside, journalLine,
                makeBed, noPhoneMeal,
            ]
        case .fortyFivePlus:
            return [
                deepBreaths, drinkWater, stretch2, mindfulness2, grateful, walk5,
                sitOutside, name5Things, sunlight2, read2Pages, calmAudio, teaBreak,
                neckStretch, walkOutside, journalLine, gratitudeText, makeBed,
                openWindow, washFace, noPhoneMeal,
            ]
        }
    }

    static func forToday(ageGroup: AgeGroup) -> DailyChallenge {
        let day = Calendar.current.ordinality(of: .day, in: .era, for: Date()) ?? 1
        let list = challenges(for: ageGroup)
        return list[(day - 1) % list.count]
    }
}

enum TreeStage: Int, CaseIterable {
    case seed, sprout, smallPlant, youngTree, bigTree, floweringTree, strongTree

    static func stage(forDay day: Int) -> TreeStage {
        switch day {
        case ..<3: return .seed
        case 3..<7: return .sprout
        case 7..<14: return .smallPlant
        case 14..<30: return .youngTree
        case 30..<60: return .bigTree
        case 60..<90: return .floweringTree
        default: return .strongTree
        }
    }

    var title: String {
        switch self {
        case .seed: return L("tree.seed")
        case .sprout: return L("tree.sprout")
        case .smallPlant: return L("tree.small_plant")
        case .youngTree: return L("tree.young_tree")
        case .bigTree: return L("tree.big_tree")
        case .floweringTree: return L("tree.flowering_tree")
        case .strongTree: return L("tree.strong_tree")
        }
    }

    var imageName: String {
        switch self {
        case .seed: return "Seed"
        case .sprout: return "Sprout"
        case .smallPlant: return "Small Plant"
        case .youngTree: return "Young Tree"
        case .bigTree: return "Big Tree"
        case .floweringTree: return "Flowering Tree"
        case .strongTree: return "Strong Tree"
        }
    }

    var nextDay: Int? {
        switch self {
        case .seed: return 3
        case .sprout: return 7
        case .smallPlant: return 14
        case .youngTree: return 30
        case .bigTree: return 60
        case .floweringTree: return 90
        case .strongTree: return nil
        }
    }

    var showingFlowers: Bool {
        self == .floweringTree || self == .strongTree
    }
}

struct Milestone: Identifiable, Hashable {
    let day: Int

    var id: Int { day }

    static let all: [Milestone] = [1, 3, 7, 14, 30, 60, 90].map { Milestone(day: $0) }

    var title: String {
        switch day {
        case 1: return L("milestone.day_1")
        case 3: return L("milestone.day_3")
        case 7: return L("milestone.day_7")
        case 14: return L("milestone.day_14")
        case 30: return L("milestone.day_30")
        case 60: return L("milestone.day_60")
        case 90: return L("milestone.day_90")
        default: return L("milestone.day_1")
        }
    }

    var icon: String {
        switch day {
        case 1: return "figure.walk"
        case 3: return "leaf.fill"
        case 7: return "calendar.badge.checkmark"
        case 14: return "calendar"
        case 30: return "star.fill"
        case 60: return "brain.head.profile.fill"
        case 90: return "trophy.fill"
        default: return "flag.fill"
        }
    }

    var treeStage: TreeStage { TreeStage.stage(forDay: day) }

    var celebrationSubtitle: String {
        switch day {
        case 1: return L("milestone.celebration.day_1")
        case 3: return L("milestone.celebration.day_3")
        case 7: return L("milestone.celebration.day_7")
        case 14: return L("milestone.celebration.day_14")
        case 30: return L("milestone.celebration.day_30")
        case 60: return L("milestone.celebration.day_60")
        default: return L("milestone.celebration.default")
        }
    }
}

struct RescueAction: Identifiable, Hashable {
    let emoji: String
    let titleKey: String

    var id: String { titleKey }
    var title: String { L(titleKey) }

    static let distract: [RescueAction] = [
        RescueAction(emoji: "🚶", titleKey: "rescue.walk_2min"),
        RescueAction(emoji: "💧", titleKey: "rescue.drink_water"),
        RescueAction(emoji: "📵", titleKey: "rescue.phone_away"),
        RescueAction(emoji: "🚪", titleKey: "rescue.change_rooms"),
        RescueAction(emoji: "🤸", titleKey: "rescue.jumping_jacks"),
        RescueAction(emoji: "🎧", titleKey: "rescue.calming_audio"),
        RescueAction(emoji: "📋", titleKey: "rescue.simple_task"),
    ]

    static let challenge: [RescueAction] = [
        RescueAction(emoji: "🌬️", titleKey: "rescue.deep_breaths"),
        RescueAction(emoji: "👀", titleKey: "rescue.name_5_things"),
        RescueAction(emoji: "🧍", titleKey: "rescue.stand_walk"),
        RescueAction(emoji: "📱", titleKey: "rescue.phone_elsewhere"),
        RescueAction(emoji: "🏃", titleKey: "rescue.physical_30sec"),
    ]
}
