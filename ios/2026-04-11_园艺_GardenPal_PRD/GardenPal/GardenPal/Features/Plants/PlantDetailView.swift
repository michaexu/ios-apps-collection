import SwiftUI
import SwiftData
import UIKit

struct PlantDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var plant: Plant
    let catalog: SpeciesCatalog

    @State private var note: String = ""

    var body: some View {
        List {
            Section {
                HStack(spacing: 16) {
                    detailImage
                        .frame(width: 96, height: 96)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    VStack(alignment: .leading, spacing: 6) {
                        Text(plant.nickname)
                            .font(.title2.bold())
                        Text(plant.displaySpeciesName(catalog: catalog))
                            .foregroundStyle(.secondary)
                        Text("\(plant.position.rawValue) · \(plant.orientation.rawValue)向 · \(plant.environment.rawValue)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            Section("今日与计划") {
                if CareScheduling.isDueToday(plant.nextWateringAt) {
                    Label("今日需要浇水", systemImage: "drop.fill")
                        .foregroundStyle(Theme.primary)
                }
                if let next = plant.nextWateringAt {
                    LabeledContent("下次浇水") {
                        Text(next.formatted(date: .abbreviated, time: .shortened))
                    }
                }
                if let nextF = plant.nextFertilizerAt {
                    LabeledContent("下次施肥") {
                        Text(nextF.formatted(date: .abbreviated, time: .shortened))
                    }
                }
            }

            Section("快捷操作") {
                Button {
                    CareScheduling.applyWatered(plant: plant)
                    plant.careLogs.append(CareLog(careKind: .water, notes: note.isEmpty ? nil : note, plant: plant))
                    note = ""
                } label: {
                    Label("记录已浇水", systemImage: "drop.fill")
                }
                Button {
                    CareScheduling.applyRainDefer(plant: plant, days: 1)
                } label: {
                    Label("雨天：浇水推迟 1 天", systemImage: "cloud.rain")
                }
                Button {
                    CareScheduling.applyFertilized(plant: plant)
                    plant.careLogs.append(CareLog(careKind: .fertilize, plant: plant))
                } label: {
                    Label("记录已施肥", systemImage: "aqi.medium")
                }
                Toggle("标记为需关注", isOn: $plant.userFlagNeedsAttention)
            }

            Section("备注（随浇水保存）") {
                TextField("可选备注", text: $note)
            }

            Section("生长日志") {
                let logs = plant.careLogs.sorted { $0.createdAt > $1.createdAt }
                if logs.isEmpty {
                    Text("暂无记录")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(logs, id: \.persistentModelID) { log in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(log.careKind.rawValue)
                                .font(.headline)
                            Text(log.createdAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if let n = log.notes, !n.isEmpty {
                                Text(n)
                                    .font(.subheadline)
                            }
                        }
                    }
                }
            }

            if let speciesId = plant.speciesCatalogId, let s = catalog.species(byId: speciesId) {
                Section("环境评估（本地）") {
                    LabeledContent("光照需求", value: s.sunlight)
                    if let soil = s.soilType { LabeledContent("土壤", value: soil) }
                    if let t = s.temperatureRange { LabeledContent("温度", value: t) }
                    if let h = s.humidity { LabeledContent("湿度", value: h) }
                    Text(environmentAdvice(for: s))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("植物详情")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var detailImage: some View {
        if let data = plant.photoData, let ui = UIImage(data: data) {
            Image(uiImage: ui)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                Theme.backgroundTint
                Image(systemName: "leaf.fill")
                    .font(.largeTitle)
                    .foregroundStyle(Theme.primary)
            }
        }
    }

    private func environmentAdvice(for s: SpeciesDTO) -> String {
        switch plant.orientation {
        case .south, .west:
            if s.sunlight.contains("散射") || s.sunlight.contains("阴") {
                return "朝南/西光照较强，该品种偏耐阴，建议避开正午直射，或拉纱帘柔化光线。"
            }
            return "当前朝向光照充足，与该品种需求较匹配；注意盆土干湿循环，避免积水。"
        case .north, .east:
            if s.sunlight.contains("全日照") || s.sunlight.contains("直射") {
                return "朝北/东相对偏弱光，喜阳品种可能徒长，可适当补光或更靠近窗沿。"
            }
            return "当前朝向偏柔和光照，较适合耐阴与散射光植物。"
        }
    }
}
