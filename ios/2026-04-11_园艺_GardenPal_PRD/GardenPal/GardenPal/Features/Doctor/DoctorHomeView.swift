import SwiftUI
import SwiftData

struct DoctorHomeView: View {
    @Query(sort: \DiagnosisSession.createdAt, order: .reverse) private var sessions: [DiagnosisSession]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        DiagnosisFlowView()
                    } label: {
                        Label("开始本地问诊", systemImage: "camera.metering.multispot")
                    }
                    Text("根据症状规则生成本地处理清单，可逐项勾选完成。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("养护咨询（本地）") {
                    Text("出差一周怎么办？")
                    Text("建议：出发前浇透水；途中请亲友按周期补水；回家先检查盆土与叶片再补水。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text("为什么不开花？")
                    Text("常见因素：光照不足、氮肥过多、未休眠春化等。请结合品种百科中的光照与施肥建议调整。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("历史诊断") {
                    if sessions.isEmpty {
                        Text("暂无记录")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(sessions) { session in
                            NavigationLink {
                                DiagnosisResultView(session: session)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(session.title)
                                        .font(.headline)
                                    Text(session.createdAt.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    if let plant = session.plant {
                                        Text(plant.nickname)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("AI 医生")
        }
    }
}
