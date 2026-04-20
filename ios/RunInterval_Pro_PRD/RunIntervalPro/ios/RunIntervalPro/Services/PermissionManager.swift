import Foundation
import OSLog

@MainActor
final class PermissionManager: ObservableObject {
    private let healthKitService = HealthKitService()
    private let notificationService = NotificationService()
    private let logger = Logger(subsystem: "com.runinterval.pro", category: "Permissions")
    
    @Published var healthKitAuthorized = false
    @Published var notificationsAuthorized = false
    @Published var allPermissionsGranted = false
    
    // MARK: - 初始化
    init() {
        updatePermissionStatus()
    }
    
    // MARK: - 更新权限状态
    private func updatePermissionStatus() {
        healthKitAuthorized = healthKitService.isAuthorized
        notificationsAuthorized = notificationService.isAuthorized
        allPermissionsGranted = healthKitAuthorized && notificationsAuthorized
        
        logger.log("权限状态 - HealthKit: \(healthKitAuthorized), 通知: \(notificationsAuthorized)")
    }
    
    // MARK: - 请求所有权限
    func requestAllPermissions(completion: @escaping (Bool) -> Void) {
        logger.info("开始请求所有权限")
        
        // 首先请求HealthKit
        healthKitService.requestAuthorization { [weak self] success in
            self?.updatePermissionStatus()
            
            // 然后请求通知权限
            self?.notificationService.requestAuthorization { success in
                self?.updatePermissionStatus()
                self?.notificationService.setupNotificationCategories()
                
                completion(self?.allPermissionsGranted ?? false)
            }
        }
    }
    
    // MARK: - 请求特定权限
    func requestHealthKitPermission(completion: @escaping (Bool) -> Void) {
        healthKitService.requestAuthorization { [weak self] success in
            self?.updatePermissionStatus()
            completion(success)
        }
    }
    
    func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
        notificationService.requestAuthorization { [weak self] success in
            self?.updatePermissionStatus()
            completion(success)
        }
    }
    
    // MARK: - 获取服务实例
    func getHealthKitService() -> HealthKitService {
        return healthKitService
    }
    
    func getNotificationService() -> NotificationService {
        return notificationService
    }
    
    // MARK: - 权限描述（用于UI显示）
    func getHealthKitDescription() -> String {
        return "需要HealthKit权限来记录你的锻炼数据、心率、距离和热量消耗。"
    }
    
    func getNotificationDescription() -> String {
        return "需要通知权限来提醒你按时锻炼和阶段变化提醒。"
    }
    
    // MARK: - 检查是否需要显示权限请求UI
    func shouldShowPermissionRequest() -> Bool {
        return !allPermissionsGranted
    }
}

// MARK: - 权限请求视图
import SwiftUI

struct PermissionRequestView: View {
    @StateObject private var permissionManager = PermissionManager()
    @Environment(\.dismiss) private var dismiss
    @State private var isRequesting = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()
                
                // 图标和标题
                VStack(spacing: 16) {
                    Image(systemName: "figure.run")
                        .font(.system(size: 80))
                        .foregroundColor(Color(hex: "FF6B35"))
                    
                    Text("欢迎使用 RunInterval Pro")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("为了提供最佳体验，我们需要一些权限")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // 权限列表
                VStack(spacing: 20, alignment: .leading) {
                    PermissionItem(
                        icon: "heart.fill",
                        title: "HealthKit",
                        description: permissionManager.getHealthKitDescription(),
                        isGranted: permissionManager.healthKitAuthorized
                    )
                    
                    PermissionItem(
                        icon: "bell.fill",
                        title: "通知",
                        description: permissionManager.getNotificationDescription(),
                        isGranted: permissionManager.notificationsAuthorized
                    )
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // 按钮
                VStack(spacing: 16) {
                    Button(action: requestPermissions) {
                        if isRequesting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("允许所有权限")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color(hex: "FF6B35"))
                    .cornerRadius(12)
                    .disabled(isRequesting)
                    
                    Button("稍后设置") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal, 20)
            }
            .padding()
            .navigationBarHidden(true)
        }
    }
    
    private func requestPermissions() {
        isRequesting = true
        permissionManager.requestAllPermissions { success in
            isRequesting = false
            dismiss()
        }
    }
}

// MARK: - 权限项目视图
struct PermissionItem: View {
    let icon: String
    let title: String
    let description: String
    let isGranted: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(isGranted ? .green : Color(hex: "FF6B35"))
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Image(systemName: isGranted ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundColor(isGranted ? .green : .gray.opacity(0.3))
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    PermissionRequestView()
}