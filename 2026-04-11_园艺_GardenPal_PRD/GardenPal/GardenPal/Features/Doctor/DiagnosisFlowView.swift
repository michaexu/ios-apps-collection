import SwiftUI
import SwiftData

struct DiagnosisFlowView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Plant.nickname) private var plants: [Plant]

    @State private var selectedPlant: Plant?
    @State private var selectedSymptoms: Set<String> = []
    @State private var didSave = false

    private let book = SymptomRulebook.shared

    var body: some View {
        Form {
            Section("关联植物（可选）") {
                Picker("植物", selection: $selectedPlant) {
                    Text("不关联").tag(nil as Plant?)
                    ForEach(plants) { p in
                        Text(p.nickname).tag(p as Plant?)
                    }
                }
            }

            Section("选择症状（可多选）") {
                ForEach(book.rules) { rule in
                    Toggle(isOn: Binding(
                        get: { selectedSymptoms.contains(rule.id) },
                        set: { on in
                            if on { selectedSymptoms.insert(rule.id) }
                            else { selectedSymptoms.remove(rule.id) }
                        }
                    )) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(rule.label)
                            Text(rule.causes)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section {
                Button("生成本地方案") {
                    saveDiagnosis()
                }
                .disabled(selectedSymptoms.isEmpty)
            }
        }
        .navigationTitle("本地问诊")
        .navigationBarTitleDisplayMode(.inline)
        .alert("已保存", isPresented: $didSave) {
            Button("好的") { dismiss() }
        } message: {
            Text("方案已写入历史记录，可在列表中打开查看处理清单。")
        }
    }

    private func saveDiagnosis() {
        let keys = Array(selectedSymptoms)
        let plan = book.mergedPlan(symptomIds: keys)
        let session = DiagnosisSession(
            symptomKeys: keys,
            title: plan.title,
            prevention: plan.prevention,
            severity: plan.severity,
            steps: plan.steps,
            plant: selectedPlant
        )
        modelContext.insert(session)
        didSave = true
    }
}

struct DiagnosisResultView: View {
    @Bindable var session: DiagnosisSession

    var body: some View {
        List {
            Section("摘要") {
                Text(session.title)
                Text("严重度（本地规则）: \(session.severity)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section("处理清单") {
                ForEach(session.treatmentSteps) { step in
                    Toggle(isOn: Binding(
                        get: { session.treatmentSteps.first(where: { $0.id == step.id })?.done ?? false },
                        set: { session.setStep(done: $0, stepId: step.id) }
                    )) {
                        Text(step.text)
                            .font(.body)
                    }
                }
            }
            Section("预防建议") {
                Text(session.prevention)
                    .font(.footnote)
            }
        }
        .navigationTitle("诊断结果")
    }
}
