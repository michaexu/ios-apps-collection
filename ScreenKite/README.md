# ScreenKite

ScreenKite 是一款原生 macOS 屏幕录制工具，基于 Swift + ScreenCaptureKit + Metal 构建。

## 功能特性

- **定时录制** - 支持一次性、每日、每周定时任务
- **全局快捷键** - F9-F12 快速控制录制（开始/暂停/停止/标记）
- **静默录制模式** - 自动开启勿扰模式，避免通知干扰
- **自动运镜** - 录制时根据鼠标点击自动放大关键区域
- **Metal 高速导出** - Apple Silicon 上几秒完成视频导出

## 技术栈

- Swift 5.10
- ScreenCaptureKit (macOS 12.3+)
- Combine 响应式编程
- Carbon Events (全局快捷键)
- SwiftUI 界面

## 项目结构

```
ScreenKite/
├── Sources/
│   ├── App/              # 应用入口 & SwiftUI 视图
│   ├── Core/             # 核心服务 (录制引擎、调度器、通知)
│   ├── Features/         # 功能模块 (快捷键、DND模式)
│   └── Tests/            # 单元测试
├── Resources/            # 资源文件
├── docs/                 # 架构文档 & 接口规格
└── SPEC.md               # 需求规格说明书
```

## 构建要求

- macOS 12.3+
- Xcode 15+
- Swift 5.10+

## 安装

```bash
# 使用 XcodeGen 生成项目
cd ScreenKite
xcodegen generate

# 打开 Xcode 构建
open ScreenKite.xcodeproj
```

## 许可证

MIT License
