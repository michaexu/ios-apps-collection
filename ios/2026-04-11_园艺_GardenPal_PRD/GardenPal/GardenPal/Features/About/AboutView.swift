import SwiftUI

/// 项目路径（本机构建）：`/Users/xuxd/code/ios/2026-04-11_园艺_GardenPal_PRD/GardenPal/`
struct AboutView: View {
    var body: some View {
        List {
            Section("GardenPal") {
                Text("城市阳台园艺智能助手（本地 MVP）")
                Text("数据保存在本机；植物识别与诊断均为本地规则与百科，不使用云端大模型与天气 API。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Section("主要功能") {
                Label("我的植物：卡片、添加、详情与生长日志", systemImage: "leaf")
                Label("AI 医生：症状规则 + 处理清单", systemImage: "stethoscope")
                Label("提醒：今日待办、简化月历、本地通知", systemImage: "bell")
                Label("探索：百科、阳台规划", systemImage: "book")
            }
            Section("系统要求") {
                Text("iOS 17+，SwiftUI + SwiftData")
                    .font(.footnote)
            }
        }
        .navigationTitle("关于")
        .navigationBarTitleDisplayMode(.inline)
    }
}
