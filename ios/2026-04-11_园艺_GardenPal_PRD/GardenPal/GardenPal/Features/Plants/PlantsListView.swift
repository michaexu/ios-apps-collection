import SwiftUI
import SwiftData

struct PlantsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Plant.createdAt, order: .reverse) private var plants: [Plant]
    @State private var showAdd = false

    private let catalog = SpeciesCatalog.shared

    var body: some View {
        NavigationStack {
            Group {
                if plants.isEmpty {
                    ContentUnavailableView(
                        "还没有植物",
                        systemImage: "leaf",
                        description: Text("添加第一株植物，开始本地养护计划。")
                    )
                } else {
                    List {
                        ForEach(plants) { plant in
                            NavigationLink {
                                PlantDetailView(plant: plant, catalog: catalog)
                            } label: {
                                PlantCardView(plant: plant, catalog: catalog)
                            }
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                        }
                        .onDelete(perform: delete)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Theme.backgroundTint.opacity(0.35))
            .navigationTitle("我的植物")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAdd = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .accessibilityLabel("添加植物")
                }
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink {
                        AboutView()
                    } label: {
                        Image(systemName: "info.circle")
                    }
                }
            }
            .sheet(isPresented: $showAdd) {
                AddPlantFlowView()
            }
            .task(id: plants.count) {
                await refreshNotifications()
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(plants[index])
        }
    }

    private func refreshNotifications() async {
        let count = plants.filter { CareScheduling.isDueToday($0.nextWateringAt) }.count
        await NotificationScheduler.scheduleMorningSummary(plantsNeedingWater: count)
    }
}
