import SwiftUI
import SwiftData

struct AddBrewLogView: View {
    @State private var viewModel = BrewLogViewModel()
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \BrewMethod.name) private var methods: [BrewMethod]
    @Query(sort: \Grinder.name) private var grinders: [Grinder]
    @Query(filter: #Predicate<CoffeeBean> { !$0.isArchived },
           sort: \CoffeeBean.createdAt, order: .reverse) private var beans: [CoffeeBean]

    var body: some View {
        Form {
            brewMethodSection
            coffeeSection
            grinderSection
            brewParametersSection
            brewRatioSection
            brewTimeSection
            ratingAndNotesSection
            photoSection
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Log Brew")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundStyle(AppColors.primary)
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    viewModel.saveBrew(context: modelContext)
                    dismiss()
                }
                .fontWeight(.semibold)
                .foregroundStyle(AppColors.primary)
                .disabled(!viewModel.canSave)
            }
        }
        .interactiveDismissDisabled(viewModel.hasUnsavedChanges)
    }

    // MARK: - Brew Method

    @ViewBuilder
    private var brewMethodSection: some View {
        Section("Brew Method") {
            Picker("Method", selection: $viewModel.selectedMethod) {
                Text("Select...").tag(nil as BrewMethod?)
                ForEach(methods) { method in
                    Label(method.name, systemImage: method.category.iconName)
                        .tag(Optional(method))
                }
            }
        }
    }

    // MARK: - Coffee

    @ViewBuilder
    private var coffeeSection: some View {
        Section("Coffee") {
            Picker("Bean", selection: $viewModel.selectedBean) {
                Text("Select...").tag(nil as CoffeeBean?)
                ForEach(beans) { bean in
                    Text(bean.displayName).tag(Optional(bean))
                }
            }
        }
    }

    // MARK: - Grinder

    @ViewBuilder
    private var grinderSection: some View {
        Section("Grinder") {
            Picker("Grinder", selection: $viewModel.selectedGrinder) {
                Text("None").tag(nil as Grinder?)
                ForEach(grinders) { grinder in
                    Text(grinder.name).tag(Optional(grinder))
                }
            }
            .onChange(of: viewModel.selectedGrinder) {
                viewModel.onGrinderChanged()
            }

            if let grinder = viewModel.selectedGrinder {
                Slider(
                    value: $viewModel.grinderSetting,
                    in: grinder.settingMin...grinder.settingMax,
                    step: grinder.settingStep
                ) {
                    Text("Setting")
                } minimumValueLabel: {
                    Text("\(grinder.settingMin, specifier: "%.0f")")
                        .font(AppTypography.caption)
                } maximumValueLabel: {
                    Text("\(grinder.settingMax, specifier: "%.0f")")
                        .font(AppTypography.caption)
                }

                Text("Setting: \(viewModel.grinderSetting, specifier: "%.1f")")
                    .font(AppTypography.headline)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }

    // MARK: - Brew Parameters

    @ViewBuilder
    private var brewParametersSection: some View {
        Section("Brew Parameters") {
            HStack {
                Text("Dose")
                Spacer()
                TextField("g", value: $viewModel.dose, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
            }

            if viewModel.showsWaterAmount {
                HStack {
                    Text("Water")
                    Spacer()
                    TextField("g", value: $viewModel.waterAmount, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }
            }

            if viewModel.showsYield {
                HStack {
                    Text("Yield")
                    Spacer()
                    TextField("g", value: $viewModel.yieldAmount, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }
            }

            HStack {
                Text("Temperature")
                Spacer()
                TextField("\u{00B0}C", value: $viewModel.waterTemperature, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
            }

            if viewModel.showsPressure {
                HStack {
                    Text("Pressure")
                    Spacer()
                    TextField("bar", text: $viewModel.pressureProfile)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }
            }
        }
    }

    // MARK: - Brew Ratio

    @ViewBuilder
    private var brewRatioSection: some View {
        Section("Brew Ratio") {
            Text(viewModel.brewRatio)
                .font(AppTypography.title)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    // MARK: - Brew Timer

    @ViewBuilder
    private var brewTimeSection: some View {
        Section("Brew Timer") {
            BrewTimerView(viewModel: viewModel)

            BrewStepGuideView(viewModel: viewModel)

            // Manual time entry fallback -- only when timer not started
            if viewModel.timerState == .idle {
                VStack(spacing: AppSpacing.sm) {
                    Text("or enter manually")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.subtle)

                    Stepper("Minutes: \(viewModel.brewTimeMinutes)", value: $viewModel.brewTimeMinutes, in: 0...60)

                    Stepper("Seconds: \(viewModel.brewTimeSeconds)", value: $viewModel.brewTimeSeconds, in: 0...59)
                }
            }
        }
    }

    // MARK: - Rating & Notes

    @ViewBuilder
    private var ratingAndNotesSection: some View {
        Section("Rating & Notes") {
            StarRatingView(rating: $viewModel.rating)

            TextField("Tasting notes (optional)", text: $viewModel.notes, axis: .vertical)
                .font(AppTypography.body)
                .lineLimit(3...6)
        }
    }

    // MARK: - Photo

    @ViewBuilder
    private var photoSection: some View {
        Section("Photo") {
            EquipmentPhotoPickerView(photoData: $viewModel.photoData)
        }
    }
}
