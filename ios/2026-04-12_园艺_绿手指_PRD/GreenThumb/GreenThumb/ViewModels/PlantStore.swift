//
//  PlantStore.swift
//  GreenThumb
//
//  植物数据存储 ViewModel
//

import Foundation
import SwiftUI
import Combine

@MainActor
class PlantStore: ObservableObject {
    @Published var plants: [Plant] = []
    @Published var isLoading = false
    
    private let saveKey = "saved_plants"
    
    init() {
        loadPlants()
        if plants.isEmpty {
            plants = Plant.samplePlants
        }
    }
    
    func addPlant(_ plant: Plant) {
        plants.append(plant)
        savePlants()
    }
    
    func updatePlant(_ plant: Plant) {
        if let index = plants.firstIndex(where: { $0.id == plant.id }) {
            plants[index] = plant
            savePlants()
        }
    }
    
    func deletePlant(_ plant: Plant) {
        plants.removeAll { $0.id == plant.id }
        savePlants()
    }
    
    func waterPlant(_ plant: Plant) {
        if let index = plants.firstIndex(where: { $0.id == plant.id }) {
            plants[index].careInfo.lastWatered = Date()
            let nextDate = Calendar.current.date(
                byAdding: .day,
                value: plants[index].careInfo.wateringFrequencyDays,
                to: Date()
            )
            plants[index].careInfo.nextWateringDate = nextDate
            savePlants()
        }
    }
    
    func fertilizePlant(_ plant: Plant) {
        if let index = plants.firstIndex(where: { $0.id == plant.id }) {
            plants[index].careInfo.lastFertilized = Date()
            let nextDate = Calendar.current.date(
                byAdding: .day,
                value: plants[index].careInfo.fertilizingFrequencyDays,
                to: Date()
            )
            plants[index].careInfo.nextFertilizingDate = nextDate
            savePlants()
        }
    }
    
    func addDiaryEntry(_ entry: DiaryEntry, to plant: Plant) {
        if let index = plants.firstIndex(where: { $0.id == plant.id }) {
            plants[index].diaryEntries.insert(entry, at: 0)
            savePlants()
        }
    }
    
    func plantsNeedingWater() -> [Plant] {
        let today = Date()
        return plants.filter { plant in
            guard let nextDate = plant.careInfo.nextWateringDate else {
                return true
            }
            return nextDate <= today
        }
    }
    
    private func savePlants() {
        if let encoded = try? JSONEncoder().encode(plants) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    private func loadPlants() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([Plant].self, from: data) {
            plants = decoded
        }
    }
}

// MARK: - Sample Data

extension Plant {
    static var samplePlants: [Plant] {
        [
            Plant(
                name: "绿萝",
                scientificName: "Epipremnum aureum",
                family: "天南星科",
                description: "绿萝是一种常见的室内观叶植物，耐阴性强，净化空气效果好，非常适合新手养护。",
                localImageName: "plant_pothos",
                healthStatus: .healthy,
                careInfo: CareInfo(
                    wateringFrequencyDays: 7,
                    sunlightRequirement: .indirectLight,
                    temperatureMin: 15,
                    temperatureMax: 30,
                    humidityLevel: .medium,
                    soilType: "疏松透气的腐殖土",
                    fertilizingFrequencyDays: 30,
                    lastWatered: Calendar.current.date(byAdding: .day, value: -3, to: Date()),
                    nextWateringDate: Calendar.current.date(byAdding: .day, value: 4, to: Date()),
                    nextFertilizingDate: Calendar.current.date(byAdding: .day, value: 15, to: Date())
                ),
                tags: ["室内", "耐阴", "净化空气"]
            ),
            Plant(
                name: "多肉植物",
                scientificName: "Echeveria elegans",
                family: "景天科",
                description: "石莲花是多肉植物中最受欢迎的品种之一，叶片肥厚，形似莲花，养护简单。",
                localImageName: "plant_succulent",
                healthStatus: .healthy,
                careInfo: CareInfo(
                    wateringFrequencyDays: 14,
                    sunlightRequirement: .fullSun,
                    temperatureMin: 5,
                    temperatureMax: 35,
                    humidityLevel: .low,
                    soilType: "多肉专用颗粒土",
                    fertilizingFrequencyDays: 60,
                    lastWatered: Calendar.current.date(byAdding: .day, value: -10, to: Date()),
                    nextWateringDate: Calendar.current.date(byAdding: .day, value: 4, to: Date()),
                    nextFertilizingDate: Calendar.current.date(byAdding: .day, value: 30, to: Date())
                ),
                tags: ["多肉", "阳台", "耐旱"]
            ),
            Plant(
                name: "月季",
                scientificName: "Rosa chinensis",
                family: "蔷薇科",
                description: "月季被称为「花中皇后」，花色丰富，四季开花，是最受欢迎的观赏花卉之一。",
                localImageName: "plant_rose",
                healthStatus: .needsAttention,
                careInfo: CareInfo(
                    wateringFrequencyDays: 3,
                    sunlightRequirement: .fullSun,
                    temperatureMin: 10,
                    temperatureMax: 30,
                    humidityLevel: .medium,
                    soilType: "富含有机质的微酸性土壤",
                    fertilizingFrequencyDays: 14,
                    lastWatered: Calendar.current.date(byAdding: .day, value: -2, to: Date()),
                    nextWateringDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()),
                    nextFertilizingDate: Calendar.current.date(byAdding: .day, value: 7, to: Date())
                ),
                tags: ["花卉", "户外", "观赏"]
            )
        ]
    }
}
