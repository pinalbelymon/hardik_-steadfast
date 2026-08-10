import Foundation

extension Exercise {
    static let all: [Exercise] = {
        var result: [Exercise] = []
        var nextID = 1
        func add(_ title: String, _ category: ExerciseCategory, _ minutes: Int) {
            result.append(Exercise(id: nextID, title: title, category: category, minutes: minutes))
            nextID += 1
        }

        // Quick Reset — 10
        add("Take 10 deep breaths", .quickReset, 1)
        add("Drink a glass of water", .quickReset, 1)
        add("Stand up and stretch", .quickReset, 2)
        add("Walk for 2 minutes", .quickReset, 2)
        add("Change rooms", .quickReset, 1)
        add("Put your phone down for 5 minutes", .quickReset, 5)
        add("Open a window", .quickReset, 1)
        add("Wash your face", .quickReset, 2)
        add("Take 30 slow steps", .quickReset, 2)
        add("Do a 60-second reset", .quickReset, 1)

        // Breathing — 8
        add("Box breathing", .breathing, 3)
        add("Slow breathing", .breathing, 3)
        add("4-second inhale", .breathing, 2)
        add("Extended exhale", .breathing, 2)
        add("One-minute breathing", .breathing, 1)
        add("Calm breathing", .breathing, 2)
        add("Pre-sleep breathing", .breathing, 3)
        add("Emergency breathing", .breathing, 1)

        // Mindfulness — 8
        add("Notice five things around you", .mindfulness, 1)
        add("Body scan", .mindfulness, 5)
        add("Observe your surroundings", .mindfulness, 3)
        add("Focus on your breathing", .mindfulness, 2)
        add("Listen to three sounds", .mindfulness, 2)
        add("Mindful walking", .mindfulness, 5)
        add("Mindful drinking", .mindfulness, 2)
        add("One-minute present-moment exercise", .mindfulness, 1)

        // Physical Activity — 10
        add("20 jumping jacks", .physicalActivity, 1)
        add("10 squats", .physicalActivity, 2)
        add("10 push-ups", .physicalActivity, 2)
        add("One-minute plank", .physicalActivity, 1)
        add("Two-minute walk", .physicalActivity, 2)
        add("Stretching routine", .physicalActivity, 5)
        add("Shoulder stretch", .physicalActivity, 2)
        add("Neck stretch", .physicalActivity, 2)
        add("Leg stretch", .physicalActivity, 2)
        add("Quick full-body movement", .physicalActivity, 3)

        // Distraction — 8
        add("Start a 5-minute task", .distraction, 5)
        add("Clean your desk", .distraction, 5)
        add("Organize your room", .distraction, 5)
        add("Make your bed", .distraction, 3)
        add("Listen to one song", .distraction, 3)
        add("Read two pages", .distraction, 5)
        add("Draw something", .distraction, 5)
        add("Solve a small puzzle", .distraction, 5)

        // Focus — 6
        add("Focus for 5 minutes", .focus, 5)
        add("Write your top priority", .focus, 1)
        add("Remove three distractions", .focus, 2)
        add("Complete one small task", .focus, 5)
        add("Start a timer", .focus, 1)
        add("Put your phone away", .focus, 1)

        // Self-Reflection — 10
        add("Why did I start?", .selfReflection, 2)
        add("What do I want to improve?", .selfReflection, 2)
        add("What triggers me?", .selfReflection, 3)
        add("What helps me most?", .selfReflection, 3)
        add("What am I proud of?", .selfReflection, 2)
        add("What would tomorrow look like?", .selfReflection, 3)
        add("What is one thing I can control?", .selfReflection, 2)
        add("What habit do I want to build?", .selfReflection, 3)
        add("What is one small win today?", .selfReflection, 2)
        add("Write a message to your future self", .selfReflection, 5)

        // Environment Reset — 6
        add("Move your phone away", .environmentReset, 1)
        add("Leave the room", .environmentReset, 1)
        add("Turn off unnecessary notifications", .environmentReset, 2)
        add("Clean your workspace", .environmentReset, 5)
        add("Change your environment", .environmentReset, 3)
        add("Put your phone outside the bedroom", .environmentReset, 1)

        // Digital Detox — 8
        add("10-minute phone break", .digitalDetox, 10)
        add("Disable unnecessary notifications", .digitalDetox, 3)
        add("Remove one distracting shortcut", .digitalDetox, 2)
        add("Move social apps off the home screen", .digitalDetox, 5)
        add("Turn on Focus mode", .digitalDetox, 1)
        add("Put the phone in another room", .digitalDetox, 1)
        add("Take a no-screen meal", .digitalDetox, 20)
        add("One-hour digital break", .digitalDetox, 60)

        // Confidence — 6
        add("Write three strengths", .confidence, 3)
        add("Remember a recent achievement", .confidence, 2)
        add("Write one positive statement", .confidence, 1)
        add("List three things you respect about yourself", .confidence, 3)
        add("Set one small goal", .confidence, 2)
        add("Complete one task you've delayed", .confidence, 5)

        // Sleep — 6
        add("Put phone away before bed", .sleep, 1)
        add("Dim the lights", .sleep, 1)
        add("Take slow breaths", .sleep, 2)
        add("Write tomorrow's tasks", .sleep, 3)
        add("Stretch for two minutes", .sleep, 2)
        add("Start a no-screen wind-down", .sleep, 10)

        // Stress Management — 6
        add("Write what's stressing you", .stressManagement, 3)
        add("Take a short walk", .stressManagement, 5)
        add("Breathing reset", .stressManagement, 2)
        add("Progressive muscle relaxation", .stressManagement, 5)
        add("Listen to calming audio", .stressManagement, 5)
        add("Write one thing you can control", .stressManagement, 2)

        // Trigger Awareness — 6
        add("Identify today's trigger", .triggerAwareness, 2)
        add("Identify where the urge started", .triggerAwareness, 2)
        add("Identify the emotion", .triggerAwareness, 2)
        add("Identify the situation", .triggerAwareness, 2)
        add("Write your alternative action", .triggerAwareness, 3)
        add("Create a trigger plan", .triggerAwareness, 3)

        // Habit Building — 6
        add("Choose tomorrow's goal", .habitBuilding, 2)
        add("Prepare your environment", .habitBuilding, 3)
        add("Create a replacement habit", .habitBuilding, 3)
        add("Set a reminder", .habitBuilding, 1)
        add("Plan a healthy activity", .habitBuilding, 3)
        add("Review today's progress", .habitBuilding, 3)

        // Gratitude — 4
        add("Write three good things", .gratitude, 2)
        add("Think of someone you appreciate", .gratitude, 2)
        add("Write one thing you enjoyed today", .gratitude, 2)
        add("Write one thing you are looking forward to", .gratitude, 2)

        // Social Connection — 4
        add("Message a friend", .socialConnection, 3)
        add("Call someone", .socialConnection, 5)
        add("Spend time with family", .socialConnection, 5)
        add("Go outside with someone", .socialConnection, 5)

        // Productivity — 4
        add("Five-minute cleanup", .productivity, 5)
        add("Finish one small task", .productivity, 5)
        add("Plan tomorrow", .productivity, 5)
        add("Organize your to-do list", .productivity, 5)

        // Emergency Craving Support — 10
        add("60-second breathing reset", .emergency, 1)
        add("Stand and move", .emergency, 1)
        add("Leave the room", .emergency, 1)
        add("Drink water", .emergency, 1)
        add("Put the phone away", .emergency, 1)
        add("Take a two-minute walk", .emergency, 2)
        add("Wash your face", .emergency, 2)
        add("Name five things you see", .emergency, 1)
        add("Start a five-minute task", .emergency, 5)
        add("Activate temporary app blocking", .emergency, 1)

        return result
    }()

    static var count: Int { all.count }
}
