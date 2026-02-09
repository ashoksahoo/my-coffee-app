import SwiftUI

// MARK: - SyncStatusSection (Settings)

struct SyncStatusSection: View {
    @Environment(SyncMonitor.self) private var syncMonitor
    @Environment(NetworkMonitor.self) private var networkMonitor

    var body: some View {
        Section {
            HStack {
                Label {
                    Text("iCloud Sync")
                } icon: {
                    Image(systemName: syncIconName)
                        .foregroundStyle(syncIconColor)
                }
                Spacer()
                Text(syncStatusText)
                    .foregroundStyle(AppColors.subtle)
            }

            if !networkMonitor.isConnected {
                Label {
                    Text("You're offline. Changes will sync when connected.")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.subtle)
                } icon: {
                    Image(systemName: "wifi.slash")
                        .foregroundStyle(AppColors.muted)
                }
            }

            if case .noAccount = syncMonitor.overallState {
                Label {
                    Text("Sign in to iCloud in Settings to sync across devices.")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.subtle)
                } icon: {
                    Image(systemName: "exclamationmark.icloud")
                        .foregroundStyle(AppColors.muted)
                }
            }
        } header: {
            Text("Data")
        } footer: {
            if let lastSync = syncMonitor.lastSuccessfulSync {
                Text("Last synced \(lastSync, style: .relative) ago")
            }
        }
    }

    private var syncIconName: String {
        switch syncMonitor.overallState {
        case .idle: return "icloud"
        case .syncing: return "arrow.triangle.2.circlepath.icloud"
        case .succeeded: return "checkmark.icloud"
        case .failed: return "exclamationmark.icloud"
        case .noAccount: return "xmark.icloud"
        }
    }

    private var syncIconColor: Color {
        switch syncMonitor.overallState {
        case .failed, .noAccount: return AppColors.primary
        default: return AppColors.subtle
        }
    }

    private var syncStatusText: String {
        if !networkMonitor.isConnected { return "Offline" }
        switch syncMonitor.overallState {
        case .idle: return "Enabled"
        case .syncing: return "Syncing..."
        case .succeeded: return "Up to date"
        case .failed: return "Error"
        case .noAccount: return "Not signed in"
        }
    }
}

// MARK: - OfflineBanner (Compact Capsule)

struct OfflineBanner: View {
    @Environment(NetworkMonitor.self) private var networkMonitor

    var body: some View {
        if !networkMonitor.isConnected {
            HStack(spacing: 8) {
                Image(systemName: "wifi.slash")
                Text("Offline mode")
                    .font(AppTypography.caption)
            }
            .foregroundStyle(AppColors.subtle)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(AppColors.secondaryBackground)
            .clipShape(Capsule())
        }
    }
}
