import Foundation
import Combine

// MARK: - SchedulerService Protocol

protocol SchedulerServiceProtocol: AnyObject {
    var taskWillTriggerPublisher: AnyPublisher<ScheduledTask, Never> { get }
    var taskTriggeredPublisher: AnyPublisher<ScheduledTask, Never> { get }
    var tasksDidChangePublisher: AnyPublisher<[ScheduledTask], Never> { get }

    func schedule(_ task: ScheduledTask) -> AnyPublisher<ScheduledTask, SchedulerError>
    func cancel(_ taskId: UUID) -> AnyPublisher<Void, SchedulerError>
    func updateTask(_ task: ScheduledTask) -> AnyPublisher<ScheduledTask, SchedulerError>
    func listAllTasks() -> AnyPublisher<[ScheduledTask], Never>
    func getTask(_ taskId: UUID) -> AnyPublisher<ScheduledTask?, Never>
    func setTaskEnabled(_ taskId: UUID, enabled: Bool) -> AnyPublisher<Void, SchedulerError>
    func triggerNow(_ taskId: UUID) -> AnyPublisher<ScheduledTask, SchedulerError>
    func start()
    func stop()
}

// MARK: - Internal Subjects Container
// 解决：Protocol 要求 AnyPublisher，但实现用 PassthroughSubject
// 方案：SubjectHolder 提供 PassthroughSubject，SchedulerServiceImpl 通过计算属性暴露 AnyPublisher

final class SubjectHolder {
    let taskWillTrigger = PassthroughSubject<ScheduledTask, Never>()
    let taskTriggered = PassthroughSubject<ScheduledTask, Never>()
    let tasksDidChange = PassthroughSubject<[ScheduledTask], Never>()

    var taskWillTriggerPublisher: AnyPublisher<ScheduledTask, Never> {
        taskWillTrigger.eraseToAnyPublisher()
    }
    var taskTriggeredPublisher: AnyPublisher<ScheduledTask, Never> {
        taskTriggered.eraseToAnyPublisher()
    }
    var tasksDidChangePublisher: AnyPublisher<[ScheduledTask], Never> {
        tasksDidChange.eraseToAnyPublisher()
    }
}

// MARK: - SchedulerServiceImpl

final class SchedulerServiceImpl: SchedulerServiceProtocol {

    // Protocol requires AnyPublisher, so use computed properties
    var taskWillTriggerPublisher: AnyPublisher<ScheduledTask, Never> { subjects.taskWillTriggerPublisher }
    var taskTriggeredPublisher: AnyPublisher<ScheduledTask, Never> { subjects.taskTriggeredPublisher }
    var tasksDidChangePublisher: AnyPublisher<[ScheduledTask], Never> { subjects.tasksDidChangePublisher }

    private weak var recordingEngine: RecordingEngineProtocol?
    private let notificationService: NotificationServiceProtocol
    private let storage: SchedulerStorageProtocol
    private let subjects = SubjectHolder()

    private var tasks: [UUID: ScheduledTask] = [:]
    private var reminderTimers: [UUID: DispatchSourceTimer] = [:]
    private var triggerTimers: [UUID: DispatchSourceTimer] = [:]
    private var cancellables = Set<AnyCancellable>()
    private var isRunning = false
    private let queue = DispatchQueue(label: "com.screenkite.scheduler", qos: .userInitiated)

    init(
        recordingEngine: RecordingEngineProtocol,
        notificationService: NotificationServiceProtocol,
        storage: SchedulerStorageProtocol
    ) {
        self.recordingEngine = recordingEngine
        self.notificationService = notificationService
        self.storage = storage
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true
        storage.loadAll()
            .receive(on: queue)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] loaded in
                    guard let self = self else { return }
                    self.tasks = Dictionary(uniqueKeysWithValues: loaded.map { ($0.id, $0) })
                    self.scheduleTimersForAllTasks()
                    self.subjects.tasksDidChange.send(Array(self.tasks.values))
                }
            )
            .store(in: &cancellables)
    }

    func stop() {
        isRunning = false
        cancelAllTimers()
        cancellables.removeAll()
    }

    func schedule(_ task: ScheduledTask) -> AnyPublisher<ScheduledTask, SchedulerError> {
        guard isRunning else {
            return Fail(error: .invalidConfiguration("调度服务未启动")).eraseToAnyPublisher()
        }
        guard tasks[task.id] == nil else {
            return Fail(error: .alreadyScheduled(task.id)).eraseToAnyPublisher()
        }
        guard task.isEnabled, let nextDate = task.nextTriggerDate() else {
            return Fail(error: .taskExpired).eraseToAnyPublisher()
        }

        tasks[task.id] = task
        scheduleTimers(for: task, nextDate: nextDate)
        subjects.tasksDidChange.send(Array(tasks.values))

        return storage.save(task)
            .map { task }
            .mapError { err in SchedulerError.storageFailed(underlying: err) }
            .eraseToAnyPublisher()
    }

    func cancel(_ taskId: UUID) -> AnyPublisher<Void, SchedulerError> {
        guard tasks[taskId] != nil else {
            return Fail(error: .taskNotFound(taskId)).eraseToAnyPublisher()
        }
        cancelTimers(for: taskId)
        tasks.removeValue(forKey: taskId)
        subjects.tasksDidChange.send(Array(tasks.values))
        return storage.delete(taskId)
            .mapError { err in SchedulerError.storageFailed(underlying: err) }
            .eraseToAnyPublisher()
    }

    func updateTask(_ task: ScheduledTask) -> AnyPublisher<ScheduledTask, SchedulerError> {
        guard tasks[task.id] != nil else {
            return Fail(error: .taskNotFound(task.id)).eraseToAnyPublisher()
        }
        cancelTimers(for: task.id)
        tasks[task.id] = task
        if task.isEnabled, let nextDate = task.nextTriggerDate() {
            scheduleTimers(for: task, nextDate: nextDate)
        }
        subjects.tasksDidChange.send(Array(tasks.values))
        return storage.save(task)
            .map { task }
            .mapError { err in SchedulerError.storageFailed(underlying: err) }
            .eraseToAnyPublisher()
    }

    func listAllTasks() -> AnyPublisher<[ScheduledTask], Never> {
        Just(Array(tasks.values)).eraseToAnyPublisher()
    }

    func getTask(_ taskId: UUID) -> AnyPublisher<ScheduledTask?, Never> {
        Just(tasks[taskId]).eraseToAnyPublisher()
    }

    func setTaskEnabled(_ taskId: UUID, enabled: Bool) -> AnyPublisher<Void, SchedulerError> {
        guard var task = tasks[taskId] else {
            return Fail(error: .taskNotFound(taskId)).eraseToAnyPublisher()
        }
        task.isEnabled = enabled
        return updateTask(task).map { _ in () }.eraseToAnyPublisher()
    }

    func triggerNow(_ taskId: UUID) -> AnyPublisher<ScheduledTask, SchedulerError> {
        guard let task = tasks[taskId] else {
            return Fail(error: .taskNotFound(taskId)).eraseToAnyPublisher()
        }
        return executeTask(task)
    }

    // MARK: - Private

    private func scheduleTimersForAllTasks() {
        for (_, task) in tasks where task.isEnabled {
            if let nextDate = task.nextTriggerDate() {
                scheduleTimers(for: task, nextDate: nextDate)
            }
        }
    }

    private func scheduleTimers(for task: ScheduledTask, nextDate: Date) {
        let now = Date()
        let delta = nextDate.timeIntervalSince(now)
        guard delta > 0 else {
            _ = executeTask(task)
            return
        }

        let reminderDelta = max(0, delta - 60)

        let reminderTimer = DispatchSource.makeTimerSource(queue: queue)
        reminderTimer.schedule(deadline: .now() + reminderDelta)
        reminderTimer.setEventHandler { [weak self] in
            guard let self = self else { return }
            self.notificationService.scheduleRecordingReminder(
                taskName: task.name, secondsBefore: 60, taskId: task.id
            )
            self.subjects.taskWillTrigger.send(task)
        }
        reminderTimers[task.id] = reminderTimer
        reminderTimer.resume()

        let triggerTimer = DispatchSource.makeTimerSource(queue: queue)
        triggerTimer.schedule(deadline: .now() + delta)
        triggerTimer.setEventHandler { [weak self] in
            guard let self = self,
                  let current = self.tasks[task.id],
                  current.isEnabled else { return }
            _ = self.executeTask(current)
        }
        triggerTimers[task.id] = triggerTimer
        triggerTimer.resume()
    }

    @discardableResult
    private func executeTask(_ task: ScheduledTask) -> AnyPublisher<ScheduledTask, SchedulerError> {
        guard let engine = recordingEngine else {
            return Fail(error: .recordingEngineUnavailable).eraseToAnyPublisher()
        }
        var updated = task
        updated.lastTriggeredAt = Date()
        tasks[task.id] = updated

        storage.save(updated)
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)

        do {
            try engine.start(with: task.recordingConfig)
            subjects.taskTriggered.send(updated)
        } catch {
            notificationService.notifyRecordingFailed(reason: error.localizedDescription)
        }

        if task.triggerType != .once, let next = updated.nextTriggerDate() {
            scheduleTimers(for: updated, nextDate: next)
        }

        return Just(updated)
            .setFailureType(to: SchedulerError.self)
            .eraseToAnyPublisher()
    }

    private func cancelTimers(for taskId: UUID) {
        reminderTimers[taskId]?.cancel()
        reminderTimers.removeValue(forKey: taskId)
        triggerTimers[taskId]?.cancel()
        triggerTimers.removeValue(forKey: taskId)
    }

    private func cancelAllTimers() {
        for t in reminderTimers.values { t.cancel() }
        for t in triggerTimers.values { t.cancel() }
        reminderTimers.removeAll()
        triggerTimers.removeAll()
    }
}

// MARK: - UserDefaultsSchedulerStorage

final class UserDefaultsSchedulerStorage: SchedulerStorageProtocol {

    private let key = "com.screenkite.scheduled_tasks.v1"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadAll() -> AnyPublisher<[ScheduledTask], Error> {
        return Future { [weak self] promise in
            guard let self = self else { promise(.success([])); return }
            guard let data = self.defaults.data(forKey: self.key) else {
                promise(.success([])); return
            }
            do {
                let tasks = try JSONDecoder().decode([ScheduledTask].self, from: data)
                promise(.success(tasks))
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }

    func save(_ task: ScheduledTask) -> AnyPublisher<Void, Error> {
        return loadAll()
            .flatMap { [weak self] (existing: [ScheduledTask]) -> AnyPublisher<Void, Error> in
                guard let self = self else { return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher() }
                var all = existing.filter { $0.id != task.id }
                all.append(task)
                return self.saveAll(all)
            }
            .eraseToAnyPublisher()
    }

    func delete(_ taskId: UUID) -> AnyPublisher<Void, Error> {
        return loadAll()
            .flatMap { [weak self] (existing: [ScheduledTask]) -> AnyPublisher<Void, Error> in
                guard let self = self else { return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher() }
                return self.saveAll(existing.filter { $0.id != taskId })
            }
            .eraseToAnyPublisher()
    }

    func saveAll(_ tasks: [ScheduledTask]) -> AnyPublisher<Void, Error> {
        return Future { [weak self] promise in
            guard let self = self else { promise(.success(())); return }
            do {
                self.defaults.set(try JSONEncoder().encode(tasks), forKey: self.key)
                promise(.success(()))
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
}
