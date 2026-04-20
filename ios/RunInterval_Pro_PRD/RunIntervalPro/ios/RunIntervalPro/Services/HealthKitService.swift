import Foundation
import HealthKit
import OSLog

@MainActor
final class HealthKitService: ObservableObject {
    private let healthStore = HKHealthStore()
    private let logger = Logger(subsystem: "com.runinterval.pro", category: "HealthKit")
    
    // 数据类型
    private let workoutType: HKWorkoutType = .workoutType()
    private let heartRateType: HKQuantityType = .quantityType(forIdentifier: .heartRate)!
    private let activeEnergyType: HKQuantityType = .quantityType(forIdentifier: .activeEnergyBurned)!
    private let distanceType: HKQuantityType = .quantityType(forIdentifier: .distanceWalkingRunning)!
    
    @Published var isAuthorized = false
    @Published var currentHeartRate: Double = 0
    @Published var activeEnergyBurned: Double = 0
    @Published var distanceCovered: Double = 0
    
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?
    
    // MARK: - 初始化
    init() {
        checkAuthorizationStatus()
    }
    
    // MARK: - 检查授权状态
    private func checkAuthorizationStatus() {
        let typesToRead: Set<HKObjectType> = [
            workoutType,
            heartRateType,
            activeEnergyType,
            distanceType
        ]
        
        let typesToShare: Set<HKSampleType> = [
            workoutType,
            heartRateType,
            activeEnergyType,
            distanceType
        ]
        
        let status = healthStore.authorizationStatus(for: heartRateType)
        isAuthorized = (status == .sharingAuthorized)
    }
    
    // MARK: - 请求授权
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        let typesToRead: Set<HKObjectType> = [
            workoutType,
            heartRateType,
            activeEnergyType,
            distanceType
        ]
        
        let typesToShare: Set<HKSampleType> = [
            workoutType,
            heartRateType,
            activeEnergyType,
            distanceType
        ]
        
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { [weak self] success, error in
            DispatchQueue.main.async {
                self?.isAuthorized = success
                self?.logger.log("HealthKit authorization: \(success ? "成功" : "失败")")
                completion(success)
            }
        }
    }
    
    // MARK: - 开始锻炼
    func startWorkout(activityType: HKWorkoutActivityType) async throws {
        guard isAuthorized else {
            throw HealthKitError.notAuthorized
        }
        
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = activityType
        configuration.locationType = .outdoor
        
        do {
            let session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            let builder = session.associatedWorkoutBuilder()
            
            workoutSession = session
            workoutBuilder = builder
            
            // 设置数据源
            builder.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: configuration)
            
            // 开始会话
            session.startActivity(with: Date())
            builder.beginCollection(withStart: Date()) { success, error in
                if let error = error {
                    self.logger.error("开始锻炼收集失败: \(error.localizedDescription)")
                }
            }
            
            // 监听状态变化
            builder.delegate = self
            
            logger.info("HealthKit锻炼会话已开始")
        } catch {
            logger.error("创建锻炼会话失败: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - 暂停/恢复锻炼
    func pauseWorkout() {
        workoutSession?.pause()
        logger.info("锻炼已暂停")
    }
    
    func resumeWorkout() {
        workoutSession?.resume()
        logger.info("锻炼已恢复")
    }
    
    // MARK: - 结束锻炼
    func endWorkout() async throws {
        guard let builder = workoutBuilder else {
            throw HealthKitError.builderNotFound
        }
        
        builder.endCollection(withEnd: Date()) { success, error in
            if let error = error {
                self.logger.error("结束收集失败: \(error.localizedDescription)")
                return
            }
            
            // 保存到HealthKit
            builder.finishWorkout { workout, error in
                if let error = error {
                    self.logger.error("保存锻炼失败: \(error.localizedDescription)")
                    return
                }
                
                self.logger.info("锻炼已成功保存到HealthKit")
                self.resetMetrics()
            }
        }
        
        workoutSession = nil
        workoutBuilder = nil
    }
    
    // MARK: - 重置指标
    private func resetMetrics() {
        currentHeartRate = 0
        activeEnergyBurned = 0
        distanceCovered = 0
    }
    
    // MARK: - 手动保存锻炼记录（如果HealthKit不可用）
    func saveManualWorkout(startTime: Date, endTime: Date, workoutType: HKWorkoutActivityType, totalEnergyBurned: Double, totalDistance: Double) async throws {
        let workout = HKWorkout(
            activityType: workoutType,
            start: startTime,
            end: endTime,
            duration: endTime.timeIntervalSince(startTime),
            totalEnergyBurned: HKQuantity(unit: .kilocalorie(), doubleValue: totalEnergyBurned),
            totalDistance: HKQuantity(unit: .meter(), doubleValue: totalDistance),
            metadata: [HKMetadataKeyExternalUUID: UUID().uuidString]
        )
        
        try await healthStore.save(workout)
        logger.info("手动锻炼记录已保存")
    }
}

// MARK: - HKLiveWorkoutBuilderDelegate
extension HealthKitService: HKLiveWorkoutBuilderDelegate {
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectSample sample: HKSample) {
        guard let quantitySample = sample as? HKQuantitySample else { return }
        
        DispatchQueue.main.async {
            let quantityType = quantitySample.quantityType
            
            if quantityType == self.heartRateType {
                self.currentHeartRate = quantitySample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                self.logger.info("心率更新: \(self.currentHeartRate) BPM")
            } else if quantityType == self.activeEnergyType {
                self.activeEnergyBurned = quantitySample.quantity.doubleValue(for: .kilocalorie())
                self.logger.info("消耗热量更新: \(self.activeEnergyBurned) kcal")
            } else if quantityType == self.distanceType {
                self.distanceCovered = quantitySample.quantity.doubleValue(for: .meter())
                self.logger.info("距离更新: \(self.distanceCovered) m")
            }
        }
    }
    
    func workoutBuilderDidUpdateEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        // 处理锻炼事件更新
    }
}

// MARK: - 错误类型
enum HealthKitError: LocalizedError {
    case notAvailable
    case notAuthorized
    case builderNotFound
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKit不可用"
        case .notAuthorized:
            return "未获得HealthKit授权"
        case .builderNotFound:
            return "锻炼构建器未找到"
        }
    }
}

// MARK: - 锻炼类型转换
extension HealthKitService {
    static func mapIntervalTypeToActivityType(workout: Workout) -> HKWorkoutActivityType {
        // 根据训练内容推断活动类型
        let hasWorkoutPhases = workout.cycles.contains { cycle in
            cycle.phases.contains { phase in phase.type == .work }
        }
        
        if hasWorkoutPhases {
            return .functionalStrengthTraining
        } else {
            return .running
        }
    }
}