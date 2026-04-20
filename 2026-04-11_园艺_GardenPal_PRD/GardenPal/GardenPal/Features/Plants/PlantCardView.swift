import SwiftUI
import SwiftData
import UIKit

struct PlantCardView: View {
    @Bindable var plant: Plant
    let catalog: SpeciesCatalog

    private var health: HealthStatus {
        plant.recomputeHealthStatus()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                plantImage
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(plant.nickname)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(plant.displaySpeciesName(catalog: catalog))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    HealthStatusRow(status: health)
                }
                Spacer(minLength: 0)
            }

            if let hint = todayHint {
                Label(hint, systemImage: "checklist")
                    .font(.caption)
                    .foregroundStyle(Theme.primary)
            }

            HStack {
                if let next = plant.nextWateringAt {
                    Label("下次浇水 \(next.formatted(date: .abbreviated, time: .shortened))", systemImage: "drop.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            HStack(spacing: 12) {
                Button("已浇水") {
                    CareScheduling.applyWatered(plant: plant)
                    let log = CareLog(careKind: .water, notes: "快捷记录", plant: plant)
                    plant.careLogs.append(log)
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.primary)
                .controlSize(.small)

                Button("推迟一天") {
                    CareScheduling.applyRainDefer(plant: plant, days: 1)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(12)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    @ViewBuilder
    private var plantImage: some View {
        if let data = plant.photoData, let ui = UIImage(data: data) {
            Image(uiImage: ui)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                Theme.backgroundTint
                Image(systemName: "leaf.fill")
                    .foregroundStyle(Theme.primary)
            }
        }
    }

    private var todayHint: String? {
        if CareScheduling.isDueToday(plant.nextWateringAt) {
            return "今日待办：浇水"
        }
        if CareScheduling.isDueToday(plant.nextFertilizerAt) {
            return "今日待办：施肥"
        }
        return nil
    }
}

private struct HealthStatusRow: View {
    let status: HealthStatus

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            Text(statusText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var statusColor: Color {
        switch status {
        case .healthy: Theme.healthy
        case .watch: Theme.watch
        case .urgent: Theme.urgent
        case .withered: Color.gray
        }
    }

    private var statusText: String {
        switch status {
        case .healthy: return "状态：健康"
        case .watch: return "状态：需关注"
        case .urgent: return "状态：紧急"
        case .withered: return "状态：已枯萎"
        }
    }
}
