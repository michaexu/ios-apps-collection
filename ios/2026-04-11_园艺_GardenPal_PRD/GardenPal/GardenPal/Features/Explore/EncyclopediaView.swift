import SwiftUI

struct EncyclopediaView: View {
    @State private var query: String = ""
    private var catalog: SpeciesCatalog { SpeciesCatalog.shared }

    private var rows: [SpeciesDTO] {
        catalog.search(query)
    }

    var body: some View {
        List(rows) { species in
            NavigationLink {
                SpeciesDetailView(species: species)
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(species.nameCN).font(.headline)
                    Text("浇水约每 \(species.wateringCycleDays) 天 · \(species.sunlight)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("百科")
        .searchable(text: $query, prompt: "搜索中文名 / 英文名")
    }
}

struct SpeciesDetailView: View {
    let species: SpeciesDTO

    var body: some View {
        List {
            Section("基础信息") {
                LabeledContent("中文名", value: species.nameCN)
                if let en = species.nameEN, !en.isEmpty {
                    LabeledContent("英文名", value: en)
                }
                if let family = species.family, !family.isEmpty {
                    LabeledContent("科属", value: family)
                }
            }
            Section("养护要点") {
                LabeledContent("光照", value: species.sunlight)
                LabeledContent("浇水周期", value: "约每 \(species.wateringCycleDays) 天")
                if let soil = species.soilType { LabeledContent("土壤", value: soil) }
                if let t = species.temperatureRange { LabeledContent("温度", value: t) }
                if let h = species.humidity { LabeledContent("湿度", value: h) }
            }
            if let tips = species.careTips, !tips.isEmpty {
                Section("建议") {
                    Text(tips)
                        .font(.footnote)
                }
            }
            if let issues = species.commonIssues, !issues.isEmpty {
                Section("常见问题") {
                    Text(issues)
                        .font(.footnote)
                }
            }
        }
        .navigationTitle(species.nameCN)
        .navigationBarTitleDisplayMode(.inline)
    }
}
