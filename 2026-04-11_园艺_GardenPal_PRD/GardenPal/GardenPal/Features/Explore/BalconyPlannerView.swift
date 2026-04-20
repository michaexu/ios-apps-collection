import SwiftUI

struct BalconyPlannerView: View {
    @State private var orientation: BalconyOrientation = .south
    @State private var widthMeters: Double = 1.5
    @State private var isEnclosed: Bool = true

    private var catalog: SpeciesCatalog { SpeciesCatalog.shared }

    private var picks: [SpeciesDTO] {
        Array(catalog.recommendations(orientation: orientation, approximateWidthMeters: widthMeters).prefix(12))
    }

    var body: some View {
        Form {
            Section("阳台信息") {
                Picker("朝向", selection: $orientation) {
                    ForEach(BalconyOrientation.allCases) { o in
                        Text(o.rawValue).tag(o)
                    }
                }
                Toggle("封闭式阳台", isOn: $isEnclosed)
                VStack(alignment: .leading) {
                    Text("可用宽度约 \(widthMeters, specifier: "%.1f") 米")
                    Slider(value: $widthMeters, in: 0.6...3.0, step: 0.1)
                }
            }

            Section("适种清单（本地规则）") {
                if picks.isEmpty {
                    Text("暂无匹配，请尝试调整朝向或宽度。")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(picks) { s in
                        NavigationLink {
                            SpeciesDetailView(species: s)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(s.nameCN).font(.headline)
                                Text("\(s.sunlight) · 浇水约每 \(s.wateringCycleDays) 天")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            Section("摆放建议（文字）") {
                Text(layoutAdvice)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("阳台规划")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var layoutAdvice: String {
        let light = (orientation == .south || orientation == .west) ? "光照充足区靠外侧，耐阴品种靠内墙或下层。" : "光照柔和区优先安排散射光/半阴植物，喜阳品种尽量贴近窗沿并减少遮挡。"
        let air = isEnclosed ? "封闭阳台注意通风与控湿，浇水宁少勿多，高温季节午后适当开窗。" : "开放阳台风大易干盆，小盆植物注意固定与防风。"
        let space = widthMeters < 1.0 ? "空间较窄，建议层架竖向利用，避免大叶植物互相遮挡。" : "空间尚可，可采用高低错落：高株在后、矮株在前，保证每盆见光。"
        return [light, air, space].joined(separator: "\n")
    }
}
