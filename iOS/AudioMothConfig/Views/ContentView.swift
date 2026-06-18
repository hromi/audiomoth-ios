import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {

    @Environment(AppViewModel.self) private var vm
    @State private var selectedTab = 0
    @State private var showImporter = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                DeviceInfoView()
                    .padding(.horizontal)
                    .padding(.top, 8)

                TabView(selection: $selectedTab) {
                    RecordingSettingsView()
                        .tabItem { Label("Recording", systemImage: "mic.fill") }
                        .tag(0)
                    ScheduleView()
                        .tabItem { Label("Schedule", systemImage: "calendar") }
                        .tag(1)
                    FilteringView()
                        .tabItem { Label("Filtering", systemImage: "waveform.path.ecg") }
                        .tag(2)
                    AdvancedView()
                        .tabItem { Label("Advanced", systemImage: "slider.horizontal.3") }
                        .tag(3)
                    AddOnsView()
                        .tabItem { Label("Add-ons", systemImage: "plus.circle") }
                        .tag(4)
                }
            }
            .navigationTitle("AudioMoth")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button { showImporter = true } label: {
                        Image(systemName: "square.and.arrow.down")
                    }
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button { vm.exportConfig() } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    configureButton
                }
            }
        }
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.json, .audiomothConfig]) { result in
            if case .success(let url) = result,
               url.startAccessingSecurityScopedResource(),
               let data = try? Data(contentsOf: url) {
                vm.importConfig(from: data)
                url.stopAccessingSecurityScopedResource()
            }
        }
        .fileExporter(
            isPresented: Binding(get: { vm.showExporter }, set: { vm.showExporter = $0 }),
            document: ConfigDocument(data: vm.exportData ?? Data()),
            contentType: .json,
            defaultFilename: "AudioMoth_Config.json"
        ) { _ in }
        .overlay(configureOverlay)
    }

    private var configureButton: some View {
        Button {
            Task { await vm.configure() }
        } label: {
            if vm.isConfiguring {
                ProgressView().tint(.white)
            } else {
                Text("Configure")
                    .bold()
            }
        }
        .buttonStyle(.borderedProminent)
        .disabled(vm.isConfiguring || vm.connectedDevice == nil || !vm.isValid)
    }

    @ViewBuilder
    private var configureOverlay: some View {
        if vm.configureSuccess {
            ToastView(message: "Device configured successfully", systemImage: "checkmark.circle.fill", color: .green)
                .transition(.move(edge: .top).combined(with: .opacity))
                .onAppear {
                    Task {
                        try? await Task.sleep(for: .seconds(2))
                        vm.configureSuccess = false
                    }
                }
        }
        if let err = vm.configureError {
            ToastView(message: err, systemImage: "xmark.circle.fill", color: .red)
                .transition(.move(edge: .top).combined(with: .opacity))
                .onTapGesture { vm.configureError = nil }
        }
    }
}

struct ToastView: View {
    let message: String
    let systemImage: String
    let color: Color

    var body: some View {
        VStack {
            HStack(spacing: 8) {
                Image(systemName: systemImage).foregroundStyle(color)
                Text(message).font(.subheadline)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.regularMaterial, in: Capsule())
            .shadow(radius: 4)
            .padding(.top, 8)
            Spacer()
        }
    }
}

struct ConfigDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var data: Data

    init(data: Data) { self.data = data }
    init(configuration: ReadConfiguration) throws {
        data = try configuration.file.regularFileContents ?? { throw CocoaError(.fileReadCorruptFile) }()
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
