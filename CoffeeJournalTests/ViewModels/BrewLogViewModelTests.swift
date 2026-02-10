import Testing
import Foundation
@testable import CoffeeJournal

@Suite("BrewLogViewModel")
struct BrewLogViewModelTests {

    // MARK: - Brew Ratio

    @Test("brewRatio returns '--' when dose is 0")
    func ratioWithZeroDose() {
        let vm = BrewLogViewModel()
        vm.dose = 0
        vm.waterAmount = 250
        #expect(vm.brewRatio == "--")
    }

    @Test("brewRatio returns '--' when waterAmount is 0 and no espresso method")
    func ratioWithZeroWater() {
        let vm = BrewLogViewModel()
        vm.dose = 15
        vm.waterAmount = 0
        // selectedMethod is nil, defaults to non-espresso path using waterAmount
        #expect(vm.brewRatio == "--")
    }

    @Test("brewRatio calculates correctly: dose=15, waterAmount=250 -> 1:16.7")
    func ratioCalculation() {
        let vm = BrewLogViewModel()
        vm.dose = 15
        vm.waterAmount = 250
        #expect(vm.brewRatio == "1:16.7")
    }

    @Test("brewRatio calculates correctly: dose=18, waterAmount=300 -> 1:16.7")
    func ratioCalculation18g() {
        let vm = BrewLogViewModel()
        vm.dose = 18
        vm.waterAmount = 300
        #expect(vm.brewRatio == "1:16.7")
    }

    @Test("brewRatio with 1:1 ratio")
    func ratioOneToOne() {
        let vm = BrewLogViewModel()
        vm.dose = 20
        vm.waterAmount = 20
        #expect(vm.brewRatio == "1:1.0")
    }

    // MARK: - canSave Validation

    @Test("canSave is false when no method selected even with dose > 0")
    func canSaveRequiresMethod() {
        let vm = BrewLogViewModel()
        vm.dose = 15
        // selectedMethod is nil
        #expect(vm.canSave == false)
    }

    @Test("canSave is false when dose is 0")
    func canSaveRequiresDose() {
        let vm = BrewLogViewModel()
        // selectedMethod is nil, dose is 0
        #expect(vm.canSave == false)
    }

    @Test("canSave is false for fresh ViewModel with all defaults")
    func canSaveFreshVM() {
        let vm = BrewLogViewModel()
        #expect(vm.canSave == false)
    }

    // MARK: - Manual Brew Time

    @Test("manualBrewTimeTotal: 3 minutes 30 seconds = 210.0")
    func manualBrewTimeTotal() {
        let vm = BrewLogViewModel()
        vm.brewTimeMinutes = 3
        vm.brewTimeSeconds = 30
        #expect(vm.manualBrewTimeTotal == 210.0)
    }

    @Test("manualBrewTimeTotal: 0 minutes 0 seconds = 0.0")
    func manualBrewTimeZero() {
        let vm = BrewLogViewModel()
        #expect(vm.manualBrewTimeTotal == 0.0)
    }

    @Test("manualBrewTimeTotal: 1 minute 0 seconds = 60.0")
    func manualBrewTimeOneMinute() {
        let vm = BrewLogViewModel()
        vm.brewTimeMinutes = 1
        vm.brewTimeSeconds = 0
        #expect(vm.manualBrewTimeTotal == 60.0)
    }

    // MARK: - hasUnsavedChanges

    @Test("hasUnsavedChanges is false for fresh ViewModel")
    func noUnsavedChangesOnFreshVM() {
        let vm = BrewLogViewModel()
        #expect(vm.hasUnsavedChanges == false)
    }

    @Test("hasUnsavedChanges is true after setting dose")
    func unsavedChangesAfterDose() {
        let vm = BrewLogViewModel()
        vm.dose = 15
        #expect(vm.hasUnsavedChanges == true)
    }

    @Test("hasUnsavedChanges is true after setting waterAmount")
    func unsavedChangesAfterWater() {
        let vm = BrewLogViewModel()
        vm.waterAmount = 250
        #expect(vm.hasUnsavedChanges == true)
    }

    @Test("hasUnsavedChanges is true after setting notes")
    func unsavedChangesAfterNotes() {
        let vm = BrewLogViewModel()
        vm.notes = "Great brew"
        #expect(vm.hasUnsavedChanges == true)
    }

    @Test("hasUnsavedChanges is true after setting rating")
    func unsavedChangesAfterRating() {
        let vm = BrewLogViewModel()
        vm.rating = 4
        #expect(vm.hasUnsavedChanges == true)
    }

    // MARK: - Timer State Machine

    @Test("Timer starts in idle state")
    func timerStartsIdle() {
        let vm = BrewLogViewModel()
        #expect(vm.timerState == .idle)
    }

    @Test("startTimer transitions idle -> running")
    func startTimerTransition() {
        let vm = BrewLogViewModel()
        vm.startTimer()
        #expect(vm.timerState == .running)
    }

    @Test("pauseTimer transitions running -> paused")
    func pauseTimerTransition() {
        let vm = BrewLogViewModel()
        vm.startTimer()
        vm.pauseTimer()
        #expect(vm.timerState == .paused)
    }

    @Test("resumeTimer transitions paused -> running")
    func resumeTimerTransition() {
        let vm = BrewLogViewModel()
        vm.startTimer()
        vm.pauseTimer()
        vm.resumeTimer()
        #expect(vm.timerState == .running)
    }

    @Test("stopTimer transitions running -> stopped")
    func stopTimerTransition() {
        let vm = BrewLogViewModel()
        vm.startTimer()
        vm.stopTimer()
        #expect(vm.timerState == .stopped)
    }

    @Test("resetTimer transitions stopped -> idle")
    func resetTimerTransition() {
        let vm = BrewLogViewModel()
        vm.startTimer()
        vm.stopTimer()
        vm.resetTimer()
        #expect(vm.timerState == .idle)
    }

    @Test("Full timer cycle: idle -> running -> paused -> running -> stopped -> idle")
    func fullTimerCycle() {
        let vm = BrewLogViewModel()
        #expect(vm.timerState == .idle)
        vm.startTimer()
        #expect(vm.timerState == .running)
        vm.pauseTimer()
        #expect(vm.timerState == .paused)
        vm.resumeTimer()
        #expect(vm.timerState == .running)
        vm.stopTimer()
        #expect(vm.timerState == .stopped)
        vm.resetTimer()
        #expect(vm.timerState == .idle)
    }

    // MARK: - resetTimer Clears State

    @Test("resetTimer clears elapsedSeconds, pausedElapsed, currentStepIndex, stepElapsedSeconds")
    func resetTimerClearsState() {
        let vm = BrewLogViewModel()
        vm.startTimer()
        vm.elapsedSeconds = 120
        vm.pausedElapsed = 60
        vm.currentStepIndex = 2
        vm.stepElapsedSeconds = 30
        vm.resetTimer()
        #expect(vm.elapsedSeconds == 0)
        #expect(vm.pausedElapsed == 0)
        #expect(vm.currentStepIndex == 0)
        #expect(vm.stepElapsedSeconds == 0)
    }

    // MARK: - showsYield / showsWaterAmount

    @Test("showsYield is false when selectedMethod is nil")
    func showsYieldNilMethod() {
        let vm = BrewLogViewModel()
        #expect(vm.showsYield == false)
    }

    @Test("showsWaterAmount is true when selectedMethod is nil")
    func showsWaterAmountNilMethod() {
        let vm = BrewLogViewModel()
        // nil?.category != .espresso evaluates to false != .espresso which is true
        #expect(vm.showsWaterAmount == true)
    }
}
