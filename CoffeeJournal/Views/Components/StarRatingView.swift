import SwiftUI

struct StarRatingView: View {
    @Binding var rating: Int
    let maxRating: Int = 5

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            ForEach(1...maxRating, id: \.self) { index in
                Image(systemName: index <= rating ? "star.fill" : "star")
                    .font(.title2)
                    .foregroundStyle(index <= rating ? AppColors.primary : AppColors.muted)
                    .onTapGesture {
                        rating = index == rating ? 0 : index
                    }
            }
        }
    }
}
