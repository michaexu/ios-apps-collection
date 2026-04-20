import Foundation

struct SymptomRuleDTO: Codable, Equatable, Identifiable {
    var id: String
    var label: String
    var severity: Int
    var title: String
    var causes: String
    var steps: [String]
    var prevention: String
}

final class SymptomRulebook: @unchecked Sendable {
    static let shared = SymptomRulebook()

    private(set) var rules: [SymptomRuleDTO] = []
    private var byId: [String: SymptomRuleDTO] = [:]

    private init() { reload() }

    func reload() {
        guard let url = Bundle.main.url(forResource: "symptom_rules", withExtension: "json") else {
            rules = []
            byId = [:]
            return
        }
        do {
            let data = try Data(contentsOf: url)
            rules = try JSONDecoder().decode([SymptomRuleDTO].self, from: data)
            byId = Dictionary(uniqueKeysWithValues: rules.map { ($0.id, $0) })
        } catch {
            rules = []
            byId = [:]
        }
    }

    func rule(id: String) -> SymptomRuleDTO? { byId[id] }

    /// 合并多条症状：取最高严重度，合并步骤并去重，保留可读标题
    func mergedPlan(symptomIds: [String]) -> (title: String, prevention: String, severity: Int, steps: [TreatmentStep]) {
        let selected = symptomIds.compactMap { byId[$0] }
        guard !selected.isEmpty else {
            return ("暂无可匹配规则", "请尝试选择更具体的症状。", 1, [])
        }
        let severity = selected.map(\.severity).max() ?? 1
        var seen = Set<String>()
        var steps: [TreatmentStep] = []
        for rule in selected {
            for (idx, line) in rule.steps.enumerated() {
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty, !seen.contains(trimmed) else { continue }
                seen.insert(trimmed)
                steps.append(TreatmentStep(id: "\(rule.id)_\(idx)", text: trimmed, done: false))
            }
        }
        let title = selected.count == 1
            ? selected[0].title
            : "综合处理方案（\(selected.count) 项症状）"
        let prevention = selected.map(\.prevention).joined(separator: "\n")
        return (title, prevention, severity, steps)
    }
}
