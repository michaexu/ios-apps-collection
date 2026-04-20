import AppKit

// MARK: - Application Entry Point

// 手动启动 Application，避免 @main 注解与 XCTest 冲突
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
