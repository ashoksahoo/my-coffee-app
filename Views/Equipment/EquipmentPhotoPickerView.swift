import SwiftUI
import PhotosUI

struct EquipmentPhotoPickerView: View {
    @Binding var photoData: Data?
    @State private var selectedItem: PhotosPickerItem?
    @State private var isLoading = false
    @State private var loadFailed = false

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            photoArea
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 16))

            HStack(spacing: AppSpacing.md) {
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Text(photoData != nil ? "Change Photo" : "Add Photo")
                        .monochromeButtonStyle()
                }
                .buttonStyle(.plain)

                if photoData != nil {
                    Button {
                        photoData = nil
                    } label: {
                        Text("Remove Photo")
                            .monochromeButtonStyle()
                    }
                    .buttonStyle(.plain)
                }
            }

            if loadFailed {
                Text("Failed to load photo")
                    .font(AppTypography.caption)
                    .fontWeight(.bold)
            }
        }
        .onChange(of: selectedItem) { _, newItem in
            guard let newItem else { return }
            isLoading = true
            loadFailed = false

            Task {
                do {
                    if let data = try await newItem.loadTransferable(type: Data.self) {
                        if let compressed = ImageCompressor.compress(
                            imageData: data,
                            maxDimension: 1024,
                            quality: 0.7
                        ) {
                            photoData = compressed
                        } else {
                            loadFailed = true
                        }
                    } else {
                        loadFailed = true
                    }
                } catch {
                    loadFailed = true
                }
                isLoading = false
            }
        }
    }

    @ViewBuilder
    private var photoArea: some View {
        if isLoading {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppColors.secondaryBackground)
                ProgressView()
            }
        } else if let photoData, let uiImage = UIImage(data: photoData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .clipped()
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
                    .foregroundStyle(AppColors.muted)
                VStack(spacing: AppSpacing.sm) {
                    Image(systemName: "camera")
                        .font(.system(size: 32))
                        .foregroundStyle(AppColors.subtle)
                    Text("Add Photo")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.subtle)
                }
            }
        }
    }
}
