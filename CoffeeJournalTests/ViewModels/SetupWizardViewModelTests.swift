import Testing
import Foundation
@testable import CoffeeJournal

@Suite("SetupWizardViewModel")
struct SetupWizardViewModelTests {

    // MARK: - Initial State

    @Test("Initial state: currentStep is welcome")
    func initialStepIsWelcome() {
        let vm = SetupWizardViewModel()
        #expect(vm.currentStep == .welcome)
    }

    @Test("Initial state: selectedMethods is empty")
    func initialMethodsEmpty() {
        let vm = SetupWizardViewModel()
        #expect(vm.selectedMethods.isEmpty)
    }

    @Test("Initial state: grinderName is empty")
    func initialGrinderNameEmpty() {
        let vm = SetupWizardViewModel()
        #expect(vm.grinderName.isEmpty)
    }

    // MARK: - canProceed Per Step

    @Test("canProceed at welcome is true")
    func canProceedWelcome() {
        let vm = SetupWizardViewModel()
        vm.currentStep = .welcome
        #expect(vm.canProceed == true)
    }

    @Test("canProceed at methods with empty selection is false")
    func canProceedMethodsEmpty() {
        let vm = SetupWizardViewModel()
        vm.currentStep = .methods
        #expect(vm.canProceed == false)
    }

    @Test("canProceed at methods with selection is true")
    func canProceedMethodsWithSelection() {
        let vm = SetupWizardViewModel()
        vm.currentStep = .methods
        vm.selectedMethods.insert(MethodTemplate.curatedMethods[0])
        #expect(vm.canProceed == true)
    }

    @Test("canProceed at grinder is true (optional)")
    func canProceedGrinder() {
        let vm = SetupWizardViewModel()
        vm.currentStep = .grinder
        #expect(vm.canProceed == true)
    }

    @Test("canProceed at complete is true")
    func canProceedComplete() {
        let vm = SetupWizardViewModel()
        vm.currentStep = .complete
        #expect(vm.canProceed == true)
    }

    // MARK: - nextStep Navigation

    @Test("nextStep advances welcome -> methods")
    func nextStepWelcomeToMethods() {
        let vm = SetupWizardViewModel()
        vm.currentStep = .welcome
        vm.nextStep()
        #expect(vm.currentStep == .methods)
    }

    @Test("nextStep advances methods -> grinder")
    func nextStepMethodsToGrinder() {
        let vm = SetupWizardViewModel()
        vm.currentStep = .methods
        vm.nextStep()
        #expect(vm.currentStep == .grinder)
    }

    @Test("nextStep advances grinder -> complete")
    func nextStepGrinderToComplete() {
        let vm = SetupWizardViewModel()
        vm.currentStep = .grinder
        vm.nextStep()
        #expect(vm.currentStep == .complete)
    }

    @Test("nextStep at complete stays at complete (does not crash)")
    func nextStepAtCompleteStays() {
        let vm = SetupWizardViewModel()
        vm.currentStep = .complete
        vm.nextStep()
        #expect(vm.currentStep == .complete)
    }

    // MARK: - previousStep Navigation

    @Test("previousStep goes back complete -> grinder")
    func previousStepCompleteToGrinder() {
        let vm = SetupWizardViewModel()
        vm.currentStep = .complete
        vm.previousStep()
        #expect(vm.currentStep == .grinder)
    }

    @Test("previousStep goes back grinder -> methods")
    func previousStepGrinderToMethods() {
        let vm = SetupWizardViewModel()
        vm.currentStep = .grinder
        vm.previousStep()
        #expect(vm.currentStep == .methods)
    }

    @Test("previousStep goes back methods -> welcome")
    func previousStepMethodsToWelcome() {
        let vm = SetupWizardViewModel()
        vm.currentStep = .methods
        vm.previousStep()
        #expect(vm.currentStep == .welcome)
    }

    @Test("previousStep at welcome stays at welcome (does not crash)")
    func previousStepAtWelcomeStays() {
        let vm = SetupWizardViewModel()
        vm.currentStep = .welcome
        vm.previousStep()
        #expect(vm.currentStep == .welcome)
    }

    // MARK: - stepTitle

    @Test("Welcome step title is 'Welcome'")
    func welcomeTitle() {
        let vm = SetupWizardViewModel()
        vm.currentStep = .welcome
        #expect(vm.stepTitle == "Welcome")
    }

    @Test("Methods step title is 'Your Brew Methods'")
    func methodsTitle() {
        let vm = SetupWizardViewModel()
        vm.currentStep = .methods
        #expect(vm.stepTitle == "Your Brew Methods")
    }

    @Test("Grinder step title is 'Your Grinder'")
    func grinderTitle() {
        let vm = SetupWizardViewModel()
        vm.currentStep = .grinder
        #expect(vm.stepTitle == "Your Grinder")
    }

    @Test("Complete step title is 'All Set!'")
    func completeTitle() {
        let vm = SetupWizardViewModel()
        vm.currentStep = .complete
        #expect(vm.stepTitle == "All Set!")
    }

    // MARK: - stepNumber

    @Test("Welcome stepNumber is 1")
    func welcomeStepNumber() {
        let vm = SetupWizardViewModel()
        vm.currentStep = .welcome
        #expect(vm.stepNumber == 1)
    }

    @Test("Methods stepNumber is 2")
    func methodsStepNumber() {
        let vm = SetupWizardViewModel()
        vm.currentStep = .methods
        #expect(vm.stepNumber == 2)
    }

    @Test("Grinder stepNumber is 3")
    func grinderStepNumber() {
        let vm = SetupWizardViewModel()
        vm.currentStep = .grinder
        #expect(vm.stepNumber == 3)
    }

    @Test("Complete stepNumber is 4")
    func completeStepNumber() {
        let vm = SetupWizardViewModel()
        vm.currentStep = .complete
        #expect(vm.stepNumber == 4)
    }

    // MARK: - totalSteps

    @Test("totalSteps returns 4")
    func totalSteps() {
        let vm = SetupWizardViewModel()
        #expect(vm.totalSteps == 4)
    }

    // MARK: - reset

    @Test("reset returns to welcome with empty selections")
    func resetClearsState() {
        let vm = SetupWizardViewModel()
        vm.currentStep = .complete
        vm.selectedMethods.insert(MethodTemplate.curatedMethods[0])
        vm.grinderName = "Comandante"
        vm.reset()
        #expect(vm.currentStep == .welcome)
        #expect(vm.selectedMethods.isEmpty)
        #expect(vm.grinderName.isEmpty)
    }
}
