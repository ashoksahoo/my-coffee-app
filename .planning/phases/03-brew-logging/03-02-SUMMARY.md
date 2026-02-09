---
phase: 03-brew-logging
plan: 02
subsystem: ui
tags: [swiftui, timer, brew-steps, state-machine, timer-publish, step-guidance]

# Dependency graph
requires:
  - phase: 03-brew-logging
    plan: 01
    provides: "BrewLogViewModel with TimerState enum, timer properties, AddBrewLogView with manual brew time Steppers"
  - phase: 01-foundation-equipment
    plan: 01
    provides: "MethodCategory enum for category-specific brew step templates"
provides:
  - "BrewStepTemplates with category-specific brew steps (pour-over bloom/pour/drawdown, espresso pre-infusion/extraction, immersion add-water/steep/plunge)"
  - "BrewTimerView embedded timer with M:SS.t display and start/pause/resume/stop/reset controls"
  - "BrewStepGuideView optional step-by-step guidance with progress, water hints, manual advance"
  - "Timer control methods on BrewLogViewModel: startTimer, pauseTimer, resumeTimer, stopTimer, resetTimer, updateTimer, advanceStep"
  - "Step guidance state on BrewLogViewModel: guidanceEnabled, currentStepIndex, stepElapsedSeconds, currentSteps, currentStep"
affects: [03-brew-logging/03, 04-tasting-notes]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Timer.publish(every: 0.1) + onReceive for real-time timer updates with Date-based elapsed calculation (no drift)"
    - "Timer state machine (idle/running/paused/stopped) with control methods on ViewModel"
    - "Static brew step templates per MethodCategory (not stored in SwiftData)"
    - "Auto-advancing step guidance based on cumulative duration tracking"
    - "ProgressView for step duration indicator with remaining time"

key-files:
  created:
    - CoffeeJournal/Utilities/BrewStepTemplates.swift
    - CoffeeJournal/Views/Brewing/BrewTimerView.swift
    - CoffeeJournal/Views/Brewing/BrewStepGuideView.swift
  modified:
    - CoffeeJournal/ViewModels/BrewLogViewModel.swift
    - CoffeeJournal/Views/Brewing/AddBrewLogView.swift
    - Package.swift

key-decisions:
  - "Step Guide toggle only visible when timer is idle or stopped -- prevents changing guidance mode mid-brew"
  - "Manual Stepper fallback preserved within timer section for users who prefer not to use the timer"
  - "BrewStepGuideView Next Step button always shown (not just for untimed steps) to allow manual override"

patterns-established:
  - "Timer.publish + Date-based elapsed time for drift-free timer across pause/resume cycles"
  - "BrewStepTemplate static data pattern for category-specific guidance without SwiftData storage"
  - "Cumulative duration tracking for auto-advancing through multi-step brew processes"

# Metrics
duration: 2min
completed: 2026-02-09
---

# Phase 3 Plan 2: Brew Timer & Step Guidance Summary

**Integrated brew timer with Date-based state machine, optional category-specific step guidance (bloom/pour/drawdown, pre-infusion/extraction, steep/plunge), and BrewStepTemplates static data**

## Performance

- **Duration:** 2 min
- **Started:** 2026-02-09T12:34:58Z
- **Completed:** 2026-02-09T12:37:18Z
- **Tasks:** 2
- **Files modified:** 6 (3 created, 3 modified)

## Accomplishments
- BrewStepTemplates provides category-specific brew steps: pour-over (4 steps), espresso (2 steps), immersion (3 steps), other (1 step) with duration and water percentage data
- BrewLogViewModel extended with full timer control methods (start/pause/resume/stop/reset), auto-advancing step guidance with cumulative duration tracking, and manual step advancement
- BrewTimerView displays real-time M:SS.t elapsed time with monospaced font and state-appropriate control buttons
- BrewStepGuideView shows current step name, description, progress bar, water amount hints, and Next Step button when guidance is enabled
- AddBrewLogView "Brew Timer" section replaces manual-only "Brew Time" section, with manual Stepper fallback preserved for idle state

## Task Commits

Each task was committed atomically:

1. **Task 1: Create BrewStepTemplates and add timer methods to ViewModel** - `14a30ae` (feat)
2. **Task 2: Create BrewTimerView, BrewStepGuideView, and replace manual Steppers in AddBrewLogView** - `77c020e` (feat)

## Files Created/Modified
- `CoffeeJournal/Utilities/BrewStepTemplates.swift` - BrewStep model and BrewStepTemplate with static steps(for:) returning category-specific brew guidance data
- `CoffeeJournal/ViewModels/BrewLogViewModel.swift` - Added step guidance state (guidanceEnabled, currentStepIndex, stepElapsedSeconds), computed currentSteps/currentStep, timer controls (start/pause/resume/stop/reset), updateTimer with auto-advance, advanceStep
- `CoffeeJournal/Views/Brewing/BrewTimerView.swift` - Embedded timer component with 48pt monospaced display, state-switched control buttons, Step Guide toggle, Timer.publish onReceive
- `CoffeeJournal/Views/Brewing/BrewStepGuideView.swift` - Step guidance overlay with progress indicator, step name/description, ProgressView duration bar, water amount hints, Next Step button
- `CoffeeJournal/Views/Brewing/AddBrewLogView.swift` - Replaced "Brew Time" manual Steppers section with "Brew Timer" section containing BrewTimerView, BrewStepGuideView, and conditional manual Stepper fallback
- `Package.swift` - Added BrewStepTemplates.swift, BrewTimerView.swift, BrewStepGuideView.swift

## Decisions Made
- Step Guide toggle only visible when timer is idle or stopped to prevent changing guidance mode mid-brew (consistency during active brewing)
- Manual Stepper fallback preserved within the timer section when timer is in idle state -- serves users who prefer post-hoc time entry
- BrewStepGuideView "Next Step" button always shown (not hidden for timed steps) to allow manual override during any step

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Timer is fully integrated into the brew log form, ready for Plan 03 (brew log list, detail views, photos)
- BrewStepGuideView renders conditionally -- no impact on form when guidance is disabled
- Timer state machine works with existing saveBrew() logic (timerState == .stopped uses elapsedSeconds, idle uses manualBrewTimeTotal)

## Self-Check: PASSED

All files verified present:
- CoffeeJournal/Utilities/BrewStepTemplates.swift: FOUND
- CoffeeJournal/ViewModels/BrewLogViewModel.swift: FOUND
- CoffeeJournal/Views/Brewing/BrewTimerView.swift: FOUND
- CoffeeJournal/Views/Brewing/BrewStepGuideView.swift: FOUND
- CoffeeJournal/Views/Brewing/AddBrewLogView.swift: FOUND

All commits verified:
- 14a30ae: FOUND
- 77c020e: FOUND

---
*Phase: 03-brew-logging*
*Completed: 2026-02-09*
