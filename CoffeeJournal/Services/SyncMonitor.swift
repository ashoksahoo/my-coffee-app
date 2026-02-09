import SwiftData
import CoreData
import CloudKit
import Observation

@Observable
final class SyncMonitor {
    enum SyncState: Equatable {
        case idle
        case syncing
        case succeeded
        case failed(String)
        case noAccount
    }

    private(set) var importState: SyncState = .idle
    private(set) var exportState: SyncState = .idle
    private(set) var lastSuccessfulSync: Date?

    var overallState: SyncState {
        if case .failed(let msg) = importState { return .failed(msg) }
        if case .failed(let msg) = exportState { return .failed(msg) }
        if case .noAccount = importState { return .noAccount }
        if case .noAccount = exportState { return .noAccount }
        if importState == .syncing || exportState == .syncing { return .syncing }
        if importState == .succeeded && exportState == .succeeded { return .succeeded }
        return .idle
    }

    init() {
        NotificationCenter.default.addObserver(
            forName: NSPersistentCloudKitContainer.eventChangedNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleEvent(notification)
        }

        NotificationCenter.default.addObserver(
            forName: .CKAccountChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { await self?.checkAccountStatus() }
        }

        // Check account status on initialization
        Task {
            await checkAccountStatus()
        }
    }

    private func handleEvent(_ notification: Notification) {
        guard let event = notification.userInfo?[
            NSPersistentCloudKitContainer.eventNotificationUserInfoKey
        ] as? NSPersistentCloudKitContainer.Event else { return }

        let isFinished = event.endDate != nil
        let state: SyncState = {
            if let error = event.error {
                return .failed(error.localizedDescription)
            }
            return isFinished ? .succeeded : .syncing
        }()

        switch event.type {
        case .import:
            importState = state
        case .export:
            exportState = state
        case .setup:
            break
        @unknown default:
            break
        }

        if isFinished && event.error == nil {
            lastSuccessfulSync = Date()
        }
    }

    @MainActor
    func checkAccountStatus() async {
        do {
            let status = try await CKContainer.default().accountStatus()
            switch status {
            case .available:
                // Account is available, clear any no-account state
                if importState == .noAccount {
                    importState = .idle
                }
                if exportState == .noAccount {
                    exportState = .idle
                }
            case .noAccount, .restricted:
                importState = .noAccount
                exportState = .noAccount
            case .couldNotDetermine, .temporarilyUnavailable:
                // Don't change state, might be temporary
                break
            @unknown default:
                break
            }
        } catch {
            // If we can't check account status, assume no account rather than crashing
            importState = .noAccount
            exportState = .noAccount
        }
    }
}
