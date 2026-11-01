# AI 聚合客户端（iOS）

SwiftUI 原生 iOS AI 聊天客户端，聚合 OpenAI / DeepSeek / 通义千问 + **本地/局域网 7B 级模型**。

## 特性
- SwiftUI + iOS 26/27，跟随系统深浅色，针对 **iPhone Air 6.5\" (2736×1260)** 自适应
- 云端：OpenAI / DeepSeek / 通义千问（OpenAI 兼容流式）
- **内置本地 / 局域网服务商**：支持 Ollama、LM Studio、vLLM 等运行的 7B 无对齐模型（DeepSeek-R1-Distill、Qwen2.5-7B-Abliterated 等）
- API Key 存于 Keychain，本地模型 Key 可留空
- 已声明 **本地网络权限**、ATS 允许局域网 HTTP、麦克风/相机/相册权限
- 会话本地持久化
- GitHub Actions macOS runner 云编译，产出未签名 IPA

## 本地 7B 模型使用
1. 电脑安装 Ollama：`ollama run deepseek-r1:7b` 或 `qwen2.5:7b`
2. 无对齐模型可从 HuggingFace 搜索 abliterated / uncensored 后导入
3. 在 App「模型」页选择「本地 / 局域网 (7B级)」
4. 真机把 Base URL 改成 `http://电脑局域网IP:11434/v1`
5. 首次弹出本地网络权限时点「允许」

## 本地构建
```
brew install xcodegen
xcodegen generate
open AIAggregate.xcodeproj
```

## CI
推送到 main 自动在 macOS runner 上编译、跑测试、产出未签名 IPA。
用户在 iPhone 上用「全能签」重签后安装。

## 版本
- 2.1：修复联网/局域网权限、新增本地 7B 支持、iPhone Air 适配说明
