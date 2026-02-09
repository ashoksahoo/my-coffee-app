import Foundation
import SwiftData

// MARK: - Timer State

enum TimerState {
    case idle
    case running
    case paused
    case stopped
}

// MARK: - Brew Log ViewModel

@Observable
class BrewLogViewModel {

    // MARK: - Equipment Selection

    var selectedMethod: BrewMethod?
    var selectedGrinder: Grinder?
    var selectedBean: CoffeeBean?

    // MARK: - Core Parameters

    var dose: Double = 0
    var waterAmount: Double = 0
    var waterTemperature: Double = 0
    var grinderSetting: Double = 0

    // MARK: - Method-Specific (Espresso)

    var yieldAmount: Double = 0
    var pressureProfile: String = ""

    // MARK: - Manual Brew Time Entry

    var brewTimeMinutes: Int = 0
    var brewTimeSeconds: Int = 0

    // MARK: - Rating & Notes

    var rating: Int = 0
    var notes: String = ""

    // MARK: - Timer State

    var timerState: TimerState = .idle
    var timerStartDate: Date?
    var pausedElapsed: TimeInterval = 0
    var elapsedSeconds: TimeInterval = 0
    var brewTime: Double = 0

    // MARK: - Computed Properties

    var brewRatio: String {
        guard dose > 0 else { return "--" }
        let divisor: Double
        if selectedMethod?.category == .espresso {
            divisor = yieldAmount
        } else {
            divisor = waterAmount
        }
        guard divisor > 0 else { return "--" }
        let ratio = divisor / dose
        return String(format: "1:%.1f", ratio)
    }

    var canSave: Bool {
        selectedMethod != nil && dose > 0
    }

    var showsYield: Bool {
        selectedMethod?.category == .espresso
    }

    var showsWaterAmount: Bool {
        selectedMethod?.category != .espresso
    }

    var showsPressure: Bool {
        selectedMethod?.category == .espresso
    }

    var showsSteepTime: Bool {
        selectedMethod?.category == .immersion
    }

    var hasUnsavedChanges: Bool {
        dose > 0 || selectedMethod != nil || !notes.isEmpty || rating > 0 ||
        waterAmount > 0 || waterTemperature > 0 || yieldAmount > 0 ||
        !pressureProfile.isEmpty || brewTimeMinutes > 0 || brewTimeSeconds > 0
    }

    var manualBrewTimeTotal: Double {
        Double(brewTimeMinutes * 60 + brewTimeSeconds)
    }

    // MARK: - Grinder Change Handler

    func onGrinderChanged() {
        guard let grinder = selectedGrinder else { return }
        grinderSetting = (grinder.settingMin + grinder.settingMax) / 2
    }

    // MARK: - Save

    func saveBrew(context: ModelContext) {
        let log = BrewLog()
        log.brewMethod = selectedMethod
        log.grinder = selectedGrinder
        log.coffeeBean = selectedBean
        log.dose = dose
        log.waterAmount = waterAmount
        log.waterTemperature = waterTemperature
        log.yieldAmount = yieldAmount
        log.pressureProfile = pressureProfile
        log.grinderSetting = grinderSetting
        log.rating = rating
        log.notes = notes

        // Set brew time: timer takes priority over manual entry
        if timerState == .stopped {
            log.brewTime = elapsedSeconds
        } else {
            log.brewTime = manualBrewTimeTotal
        }

        context.insert(log)

        // Update equipment usage stats
        if let method = selectedMethod {
            method.brewCount += 1
            method.lastUsedDate = Date()
        }
        if let grinder = selectedGrinder {
            grinder.brewCount += 1
            grinder.lastUsedDate = Date()
        }
    }
}
