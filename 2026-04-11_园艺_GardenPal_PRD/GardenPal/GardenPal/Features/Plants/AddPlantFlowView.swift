import SwiftUI
import SwiftData
import PhotosUI
import UIKit

struct AddPlantFlowView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var nickname: String = ""
    @State private var pickedItem: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var searchText: String = ""
    @State private var selectedSpecies: SpeciesDTO?
    @State private var manualSpecies: String = ""
    @State private var useManualSpecies: Bool = false
    @State private var orientation: BalconyOrientation = .south
    @State private var position: PlantPosition = .balcony
    @State private var environment: GrowingEnvironment = .potted

    private var catalog: SpeciesCatalog { SpeciesCatalog.shared }

    private var filteredSpecies: [SpeciesDTO] {
        catalog.search(searchText)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("说明") {
                    Text("本地模式：拍照仅作植物头像；品种请从百科选择或手动填写（非云端识别）。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("照片（可选）") {
                    PhotosPicker(selection: $pickedItem, matching: .images) {
                        Label(photoData == nil ? "选择照片" : "更换照片", systemImage: "photo")
                    }
                    .onChange(of: pickedItem) { _, new in
                        Task {
                            if let data = try? await new?.loadTransferable(type: Data.self) {
                                photoData = Self.compressImageData(data)
                            }
                        }
                    }
                    if let photoData, let ui = UIImage(data: photoData) {
                        Image(uiImage: ui)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 160)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }

                Section("昵称") {
                    TextField("例如：客厅绿萝", text: $nickname)
                }

                Section("品种") {
                    Toggle("手动填写品种（无百科条目时）", isOn: $useManualSpecies)
                    if useManualSpecies {
                        TextField("自定义品种名称", text: $manualSpecies)
                    } else {
                        TextField("搜索百科", text: $searchText)
                        if selectedSpecies != nil {
                            HStack {
                                Text("已选")
                                Spacer()
                                Text(selectedSpecies!.nameCN)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        ForEach(filteredSpecies.prefix(40)) { s in
                            Button {
                                selectedSpecies = s
                            } label: {
                                HStack {
                                    Text(s.nameCN)
                                    Spacer()
                                    if selectedSpecies?.id == s.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(Theme.primary)
                                    }
                                }
                            }
                        }
                    }
                }

                Section("环境") {
                    Picker("阳台朝向", selection: $orientation) {
                        ForEach(BalconyOrientation.allCases) { o in
                            Text(o.rawValue).tag(o)
                        }
                    }
                    Picker("放置位置", selection: $position) {
                        ForEach(PlantPosition.allCases) { p in
                            Text(p.rawValue).tag(p)
                        }
                    }
                    Picker("种植环境", selection: $environment) {
                        ForEach(GrowingEnvironment.allCases) { e in
                            Text(e.rawValue).tag(e)
                        }
                    }
                }
            }
            .navigationTitle("添加植物")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(!canSave)
                }
            }
        }
    }

    private var canSave: Bool {
        !nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && (useManualSpecies ? !manualSpecies.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty : selectedSpecies != nil)
    }

    private func save() {
        let interval: Int
        let speciesId: String?
        let custom: String?
        if useManualSpecies {
            interval = 5
            speciesId = nil
            custom = manualSpecies.trimmingCharacters(in: .whitespacesAndNewlines)
        } else if let s = selectedSpecies {
            interval = max(1, s.wateringCycleDays)
            speciesId = s.id
            custom = nil
        } else {
            return
        }

        let plant = Plant(
            nickname: nickname.trimmingCharacters(in: .whitespacesAndNewlines),
            speciesCatalogId: speciesId,
            customSpeciesLabel: custom,
            photoData: photoData,
            orientation: orientation,
            position: position,
            environment: environment,
            wateringIntervalDays: interval
        )
        modelContext.insert(plant)
        dismiss()
    }

    private static func compressImageData(_ data: Data, maxBytes: Int = 900_000) -> Data {
        guard let image = UIImage(data: data) else { return data }
        var compression: CGFloat = 0.85
        var result = image.jpegData(compressionQuality: compression) ?? data
        while result.count > maxBytes, compression > 0.2 {
            compression -= 0.1
            result = image.jpegData(compressionQuality: compression) ?? result
        }
        return result
    }
}
