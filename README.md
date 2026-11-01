# AI 聚合客户端（iOS）

SwiftUI 原生 iOS AI 聊天客户端，聚合 OpenAI / DeepSeek / 通义千问。

## 特性
- SwiftUI + iOS 26，跟随系统深浅色
- 三家 OpenAI 兼容服务商，流式输出、停止、重新生成
- API Key 存于 Keychain
- 会话本地持久化
- GitHub Actions macOS runner 云编译

## 本地构建
```
brew install xcodegen
xcodegen generate
open AIAggregate.xcodeproj
```

## CI
推送到 main 自动在 macOS runner 上编译、跑测试、产出未签名 IPA。
用户在 iPhone 上用「全能签」重签后安装。
