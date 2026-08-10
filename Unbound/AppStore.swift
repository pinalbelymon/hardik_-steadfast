import Foundation
import Observation
import UserNotifications

@Observable
final class AppStore {
    private static let storageKey = "unbound.state.v1"

    var hasCompletedOnboarding: Bool
    var hasCompletedIntro: Bool
    var ageGroup: AgeGroup?
    var goal: Goal?
    var motivation: Motivation?
    var reminderFrequency: ReminderFrequency
    var currentStreak: Int
    var bestStreak: Int
    var totalSuccessfulDays: Int
    var startDate: Date
    var lastCheckInDate: Date?
    var relapseReasons: [RelapseReason]
    var todayFeeling: Feeling?
    var todayUrge: UrgeLevel?
    var challengeCompletedDate: Date?
    var reminderEnabled: Bool
    var reminderTime: Date
    var celebrationMilestone: Milestone?
    private var celebratedMilestoneDays: Set<Int>
    private var celebrationQueue: [Milestone] = []

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.storageKey),
           let decoded = try? JSONDecoder().decode(PersistedState.self, from: data) {
            hasCompletedOnboarding = decoded.hasCompletedOnboarding
            hasCompletedIntro = decoded.hasCompletedIntro ?? (decoded.hasCompletedOnboarding ? true : false)
            ageGroup = decoded.ageGroup
            goal = decoded.goal
            motivation = decoded.motivation
            reminderFrequency = decoded.reminderFrequency
            currentStreak = decoded.currentStreak
            bestStreak = decoded.bestStreak
            totalSuccessfulDays = decoded.totalSuccessfulDays
            startDate = decoded.startDate
            lastCheckInDate = decoded.lastCheckInDate
            relapseReasons = decoded.relapseReasons
            todayFeeling = decoded.todayFeeling
            todayUrge = decoded.todayUrge
            challengeCompletedDate = decoded.challengeCompletedDate
            reminderEnabled = decoded.reminderEnabled
            reminderTime = decoded.reminderTime
            celebratedMilestoneDays = Set(decoded.celebratedMilestoneDays ?? [])
        } else {
            hasCompletedOnboarding = false
            hasCompletedIntro = false
            ageGroup = nil
            goal = nil
            motivation = nil
            reminderFrequency = .none
            currentStreak = 0
            bestStreak = 0
            totalSuccessfulDays = 0
            startDate = Date()
            lastCheckInDate = nil
            relapseReasons = []
            todayFeeling = nil
            todayUrge = nil
            challengeCompletedDate = nil
            reminderEnabled = false
            reminderTime = Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date()
            celebratedMilestoneDays = []
        }
        celebrationMilestone = nil
        backfillCelebratedMilestones()
    }

    var todayChallenge: DailyChallenge {
        DailyChallenge.forToday(ageGroup: ageGroup ?? .eighteenTo24)
    }

    var hasCheckedInToday: Bool {
        guard let last = lastCheckInDate else { return false }
        return last.isSameDay(as: Date())
    }

    var challengeCompletedToday: Bool {
        guard let date = challengeCompletedDate else { return false }
        return date.isSameDay(as: Date())
    }

    var treeStage: TreeStage { TreeStage.stage(forDay: currentStreak) }

    var nextMilestone: Milestone? { Milestone.all.first { bestStreak < $0.day } }

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return L("home.greeting.morning")
        case 12..<17: return L("home.greeting.afternoon")
        case 17..<22: return L("home.greeting.evening")
        default: return L("home.greeting.night")
        }
    }

    var encouragement: String {
        switch currentStreak {
        case 0: return L("home.encouragement.day_0")
        case 1..<3: return L("home.encouragement.day_1_2")
        case 3..<7: return L("home.encouragement.day_3_6")
        case 7..<14: return L("home.encouragement.day_7_13")
        case 14..<30: return L("home.encouragement.day_14_29")
        case 30..<60: return L("home.encouragement.day_30_59")
        default: return L("home.encouragement.day_60_plus")
        }
    }

    func isMilestoneEarned(_ milestone: Milestone) -> Bool {
        bestStreak >= milestone.day
    }

    func completeOnboarding(ageGroup: AgeGroup, goal: Goal, motivation: Motivation, reminder: ReminderFrequency) {
        self.ageGroup = ageGroup
        self.goal = goal
        self.motivation = motivation
        self.reminderFrequency = reminder
        reminderEnabled = reminder != .none
        hasCompletedOnboarding = true
        hasCompletedIntro = false
        save()
        NotificationManager.schedule(frequency: reminder, at: reminderTime)
    }

    func completeIntro() {
        hasCompletedIntro = true
        save()
    }

    func updateProfile(ageGroup: AgeGroup, goal: Goal, motivation: Motivation) {
        self.ageGroup = ageGroup
        self.goal = goal
        self.motivation = motivation
        save()
    }

    func completeCheckIn(feeling: Feeling, urge: UrgeLevel) {
        guard !hasCheckedInToday else { return }
        let previousBest = bestStreak
        todayFeeling = feeling
        todayUrge = urge
        let previous = lastCheckInDate
        lastCheckInDate = Date()
        if let previous {
            let gap = Calendar.current.dateComponents([.day], from: previous.startOfDay, to: Date().startOfDay).day ?? 0
            currentStreak = gap <= 1 ? currentStreak + 1 : 1
        } else {
            currentStreak = 1
        }
        if currentStreak > bestStreak { bestStreak = currentStreak }
        totalSuccessfulDays += 1
        queueMilestoneCelebrations(previousBest: previousBest, newBest: bestStreak)
        save()
    }

    func dismissMilestoneCelebration() {
        if celebrationQueue.isEmpty {
            celebrationMilestone = nil
        } else {
            celebrationMilestone = celebrationQueue.removeFirst()
        }
    }

    private func backfillCelebratedMilestones() {
        for milestone in Milestone.all where bestStreak >= milestone.day {
            celebratedMilestoneDays.insert(milestone.day)
        }
    }

    private func queueMilestoneCelebrations(previousBest: Int, newBest: Int) {
        guard newBest > previousBest else { return }

        let newlyUnlocked = Milestone.all.filter { milestone in
            milestone.day > previousBest
                && milestone.day <= newBest
                && !celebratedMilestoneDays.contains(milestone.day)
        }

        guard !newlyUnlocked.isEmpty else { return }

        for milestone in newlyUnlocked {
            celebratedMilestoneDays.insert(milestone.day)
        }

        celebrationQueue = Array(newlyUnlocked.dropFirst())
        celebrationMilestone = newlyUnlocked.first
    }

    func completeTodayChallenge() {
        challengeCompletedDate = Date()
        save()
    }

    func logRelapse(reason: RelapseReason) {
        relapseReasons.append(reason)
        currentStreak = 0
        lastCheckInDate = nil
        save()
    }

    func refreshLocalizedNotifications() {
        guard reminderEnabled else { return }
        let frequency: ReminderFrequency = reminderFrequency == .fewTimesAWeek ? .fewTimesAWeek : .daily
        NotificationManager.schedule(frequency: frequency, at: reminderTime)
    }

    func setReminder(enabled: Bool, time: Date? = nil) {
        reminderEnabled = enabled
        if let time { reminderTime = time }
        if enabled {
            NotificationManager.schedule(frequency: reminderFrequency == .fewTimesAWeek ? .fewTimesAWeek : .daily, at: reminderTime)
        } else {
            NotificationManager.cancelAll()
        }
        save()
    }

    func resetProgress() {
        currentStreak = 0
        bestStreak = 0
        totalSuccessfulDays = 0
        startDate = Date()
        lastCheckInDate = nil
        todayFeeling = nil
        todayUrge = nil
        challengeCompletedDate = nil
        relapseReasons = []
        celebratedMilestoneDays = []
        celebrationQueue = []
        celebrationMilestone = nil
        save()
    }

    func deleteAccount() {
        UserDefaults.standard.removeObject(forKey: Self.storageKey)
        ageGroup = nil
        goal = nil
        motivation = nil
        reminderFrequency = .none
        currentStreak = 0
        bestStreak = 0
        totalSuccessfulDays = 0
        startDate = Date()
        lastCheckInDate = nil
        relapseReasons = []
        todayFeeling = nil
        todayUrge = nil
        challengeCompletedDate = nil
        reminderEnabled = false
        reminderTime = Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date()
        hasCompletedOnboarding = false
        hasCompletedIntro = false
        celebratedMilestoneDays = []
        celebrationQueue = []
        celebrationMilestone = nil
        NotificationManager.cancelAll()
        save()
    }

    private func save() {
        let state = PersistedState(
            hasCompletedOnboarding: hasCompletedOnboarding,
            hasCompletedIntro: hasCompletedIntro,
            ageGroup: ageGroup,
            goal: goal,
            motivation: motivation,
            reminderFrequency: reminderFrequency,
            currentStreak: currentStreak,
            bestStreak: bestStreak,
            totalSuccessfulDays: totalSuccessfulDays,
            startDate: startDate,
            lastCheckInDate: lastCheckInDate,
            relapseReasons: relapseReasons,
            todayFeeling: todayFeeling,
            todayUrge: todayUrge,
            challengeCompletedDate: challengeCompletedDate,
            reminderEnabled: reminderEnabled,
            reminderTime: reminderTime,
            celebratedMilestoneDays: Array(celebratedMilestoneDays)
        )
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }
}

private struct PersistedState: Codable {
    var hasCompletedOnboarding: Bool
    var hasCompletedIntro: Bool?
    var ageGroup: AgeGroup?
    var goal: Goal?
    var motivation: Motivation?
    var reminderFrequency: ReminderFrequency
    var currentStreak: Int
    var bestStreak: Int
    var totalSuccessfulDays: Int
    var startDate: Date
    var lastCheckInDate: Date?
    var relapseReasons: [RelapseReason]
    var todayFeeling: Feeling?
    var todayUrge: UrgeLevel?
    var challengeCompletedDate: Date?
    var reminderEnabled: Bool
    var reminderTime: Date
    var celebratedMilestoneDays: [Int]?
}

enum NotificationManager {
    @discardableResult
    static func requestPermission() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])) ?? false
    }

    static func schedule(frequency: ReminderFrequency, at time: Date) {
        cancelAll()
        guard frequency != .none else { return }
        let content = UNMutableNotificationContent()
        content.title = L("notification.reminder.title")
        content.body = L("notification.reminder.body")
        content.sound = .default
        var components = Calendar.current.dateComponents([.hour, .minute], from: time)
        switch frequency {
        case .daily:
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: "daily-reminder", content: content, trigger: trigger))
        case .fewTimesAWeek:
            for weekday in [2, 4, 6] {
                components.weekday = weekday
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: "reminder-\(weekday)", content: content, trigger: trigger))
            }
        case .none:
            break
        }
    }

    static func cancelAll() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["daily-reminder", "reminder-2", "reminder-4", "reminder-6"]
        )
    }
}
