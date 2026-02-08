import Foundation
import SwiftData

// MARK: - Wizard Step

enum WizardStep: Int, CaseIterable {
    case welcome = 0
    case methods = 1
    case grinder = 2
    case complete = 3
}

// MARK: - Setup Wizard ViewModel

@Observable
class SetupWizardViewModel {

    // MARK: - State

    var currentStep: WizardStep = .welcome
    var selectedMethods: Set<MethodTemplate> = []
    var grinderName: String = ""
    var grinderType: GrinderType = .burr

    // MARK: - Computed Properties

    var canProceed: Bool {
        switch currentStep {
        case .welcome:
            return true
        case .methods:
            return !selectedMethods.isEmpty
        case .grinder:
            return true // grinder is optional
        case .complete:
            return true
        }
    }

    var stepTitle: String {
        switch currentStep {
        case .welcome:
            return "Welcome"
        case .methods:
            return "Your Brew Methods"
        case .grinder:
            return "Your Grinder"
        case .complete:
            return "All Set!"
        }
    }

    var stepNumber: Int {
        currentStep.rawValue + 1
    }

    var totalSteps: Int {
        WizardStep.allCases.count
    }

    // MARK: - Navigation

    func nextStep() {
        guard let nextIndex = WizardStep(rawValue: currentStep.rawValue + 1) else { return }
        currentStep = nextIndex
    }

    func previousStep() {
        guard let prevIndex = WizardStep(rawValue: currentStep.rawValue - 1) else { return }
        currentStep = prevIndex
    }

    // MARK: - Persistence

    func saveEquipment(context: ModelContext) {
        for template in selectedMethods {
            let method = BrewMethod(from: template)
            context.insert(method)
        }

        if !grinderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let grinder = Grinder(name: grinderName.trimmingCharacters(in: .whitespacesAndNewlines), type: grinderType)
            context.insert(grinder)
        }

        try? context.save()
    }

    // MARK: - Reset

    func reset() {
        currentStep = .welcome
        selectedMethods = []
        grinderName = ""
        grinderType = .burr
    }
}
