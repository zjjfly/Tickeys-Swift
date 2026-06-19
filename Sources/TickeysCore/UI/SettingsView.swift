#if canImport(SwiftUI)
import SwiftUI
#if canImport(AppKit)
import AppKit
#endif

public struct SettingsView: View {
    @ObservedObject private var model: SettingsObservableModel
    @State private var selectedFilterApp: String?

    public init(viewModel: SettingsViewModel) {
        self.model = SettingsObservableModel(viewModel: viewModel)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            soundSection

            filterSection

            footer
        }
        .padding(22)
        .frame(width: 500)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("Tickeys-Swift")
                .font(.title2.weight(.semibold))
            Text(LocalizedStrings.text("settings_subtitle"))
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var soundSection: some View {
        GroupBox(label: sectionTitle("settings_sound_section")) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    fieldLabel("settings_sound")
                    Picker("", selection: $model.selectedSchemeName) {
                        ForEach(model.availableSchemes, id: \.name) { scheme in
                            Text(LocalizedStrings.text(scheme.displayName)).tag(scheme.name)
                        }
                    }
                    .labelsHidden()
                    .frame(maxWidth: .infinity)
                }

                HStack {
                    fieldLabel("settings_test_sound")
                    Button(LocalizedStrings.text("settings_play_test_sound")) {
                        model.playTestSound()
                    }
                    Spacer()
                }

                sliderRow(
                    labelKey: "settings_volume",
                    value: $model.volume,
                    range: 0...1,
                    valueText: "\(Int((model.volume * 100).rounded()))%"
                )

                sliderRow(
                    labelKey: "settings_pitch",
                    value: $model.pitchSliderValue,
                    range: 0.5...1.5,
                    valueText: String(format: "%.1fx", model.pitchSliderValue)
                )
            }
            .padding(.vertical, 4)
        }
    }

    private var filterSection: some View {
        GroupBox(label: sectionTitle("settings_filter_section")) {
            VStack(alignment: .leading, spacing: 10) {
                Picker("", selection: $model.filterListMode) {
                    Text(LocalizedStrings.text("settings_blacklist")).tag(FilterListMode.blacklist)
                    Text(LocalizedStrings.text("settings_whitelist")).tag(FilterListMode.whitelist)
                }
                .labelsHidden()
                .pickerStyle(.segmented)

                Text(filterDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)

                ZStack {
                    List(selection: $selectedFilterApp) {
                        ForEach(model.filterList, id: \.self) { appName in
                            Text(appName)
                                .lineLimit(1)
                                .tag(appName)
                        }
                    }
                    .frame(height: 124)

                    if model.filterList.isEmpty {
                        VStack(spacing: 6) {
                            Text(LocalizedStrings.text("settings_filter_empty"))
                                .font(.callout)
                            Text(LocalizedStrings.text("settings_filter_empty_hint"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                    }
                }

                HStack {
                    Spacer()
                    Button(action: removeSelectedFilterApp) {
                        Text("-")
                            .frame(width: 18)
                    }
                    .help(LocalizedStrings.text("settings_remove_app"))
                    .disabled(selectedFilterApp == nil)

                    Button(action: addFilterApps) {
                        Text("+")
                            .frame(width: 18)
                    }
                    .help(LocalizedStrings.text("settings_add_app"))
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var footer: some View {
        HStack {
            Link(LocalizedStrings.text("menu_website"), destination: URL(string: "https://github.com/zjjfly/Tickeys-Swift")!)
            Spacer()
            Text(LocalizedStrings.format("settings_version_format", "0.1.0"))
                .foregroundColor(.secondary)
        }
        .font(.caption)
    }

    private var filterDescription: String {
        switch model.filterListMode {
        case .blacklist:
            return LocalizedStrings.text("settings_blacklist_description")
        case .whitelist:
            return LocalizedStrings.text("settings_whitelist_description")
        }
    }

    private func sectionTitle(_ key: String) -> some View {
        Text(LocalizedStrings.text(key))
            .font(.headline)
    }

    private func fieldLabel(_ key: String) -> some View {
        Text(LocalizedStrings.text(key))
            .foregroundColor(.secondary)
            .frame(width: 72, alignment: .trailing)
    }

    private func sliderRow(
        labelKey: String,
        value: Binding<Float>,
        range: ClosedRange<Float>,
        valueText: String
    ) -> some View {
        HStack {
            fieldLabel(labelKey)
            Slider(value: value, in: range)
            Text(valueText)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 48, alignment: .trailing)
        }
    }

    private func addFilterApps() {
        #if canImport(AppKit)
        let panel = NSOpenPanel()
        panel.title = LocalizedStrings.text("settings_add_app")
        panel.prompt = LocalizedStrings.text("settings_choose")
        panel.directoryURL = URL(fileURLWithPath: "/Applications", isDirectory: true)
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        panel.allowedContentTypes = [.applicationBundle]

        guard panel.runModal() == .OK else {
            return
        }

        model.addFilterAppURLs(panel.urls)
        #endif
    }

    private func removeSelectedFilterApp() {
        guard let selectedFilterApp else {
            return
        }

        model.removeFilterApp(named: selectedFilterApp)
        self.selectedFilterApp = nil
    }
}

private final class SettingsObservableModel: ObservableObject {
    @Published var availableSchemes: [AudioScheme]
    @Published var selectedSchemeName: String {
        didSet {
            guard oldValue != selectedSchemeName else { return }
            try? viewModel.selectScheme(selectedSchemeName)
        }
    }
    @Published var volume: Float {
        didSet {
            guard oldValue != volume else { return }
            viewModel.setVolume(volume)
        }
    }
    @Published var pitchSliderValue: Float {
        didSet {
            guard oldValue != pitchSliderValue else { return }
            viewModel.setPitchSliderValue(pitchSliderValue)
        }
    }
    @Published var filterList: [String]
    @Published var filterListMode: FilterListMode {
        didSet {
            guard oldValue != filterListMode else { return }
            viewModel.setFilterListMode(filterListMode)
        }
    }

    private let viewModel: SettingsViewModel

    init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
        self.availableSchemes = viewModel.availableSchemes
        self.selectedSchemeName = viewModel.selectedSchemeName
        self.volume = viewModel.volume
        self.pitchSliderValue = viewModel.pitchSliderValue
        self.filterList = viewModel.filterList
        self.filterListMode = viewModel.filterListMode
    }

    func addFilterAppURLs(_ urls: [URL]) {
        viewModel.addFilterAppURLs(urls)
        filterList = viewModel.filterList
    }

    func playTestSound() {
        _ = viewModel.playTestSound()
    }

    func removeFilterApp(named appName: String) {
        guard let index = filterList.firstIndex(of: appName) else {
            return
        }

        viewModel.removeFilterApp(atOffsets: [index])
        filterList = viewModel.filterList
    }
}
#endif
