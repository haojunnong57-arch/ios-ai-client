import Foundation
import AVFoundation
import Speech

enum VoiceCallState: Equatable {
    case idle
    case connecting
    case listening
    case recognizing
    case thinking
    case speaking
    case muted
    case error(String)

    var statusText: String {
        switch self {
        case .idle: return "等待开始"
        case .connecting: return "连接中"
        case .listening: return "正在聆听"
        case .recognizing: return "正在识别"
        case .thinking: return "正在思考"
        case .speaking: return "正在回答"
        case .muted: return "麦克风已关闭"
        case .error(let s): return s
        }
    }
}

@MainActor
final class VoiceSessionController: NSObject, ObservableObject {
    @Published var state: VoiceCallState = .idle
    @Published var liveUserText: String = ""
    @Published var finalUserText: String = ""
    @Published var assistantText: String = ""
    @Published var audioLevel: CGFloat = 0.08
    @Published var isMuted = false

    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
        ?? SFSpeechRecognizer()
    private let synthesizer = AVSpeechSynthesizer()
    private var levelTimer: Timer?
    private var llmTask: Task<Void, Never>?
    private var settings: AppSettings?
    private var store: SessionStore?
    private var session: ChatSession?

    private let client = OpenAIStreamingClient()

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func configure(session: ChatSession, store: SessionStore, settings: AppSettings) {
        self.session = session
        self.store = store
        self.settings = settings
    }

    func start() {
        state = .connecting
        requestPermissions { [weak self] ok in
            guard let self else { return }
            Task { @MainActor in
                if ok {
                    self.beginListening()
                } else {
                    self.state = .error("需要麦克风和语音识别权限")
                }
            }
        }
    }

    func stopEverything() {
        llmTask?.cancel()
        stopListening()
        synthesizer.stopSpeaking(at: .immediate)
        levelTimer?.invalidate()
        levelTimer = nil
        audioLevel = 0.08
        state = .idle
    }

    func toggleMute() {
        isMuted.toggle()
        if isMuted {
            stopListening()
            state = .muted
            audioLevel = 0.05
        } else {
            beginListening()
        }
    }

    func interruptSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
        llmTask?.cancel()
        if !isMuted {
            beginListening()
        } else {
            state = .muted
        }
    }

    // MARK: - Permissions

    private func requestPermissions(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            AVAudioSession.sharedInstance().requestRecordPermission { mic in
                DispatchQueue.main.async {
                    completion(status == .authorized && mic)
                }
            }
        }
    }

    // MARK: - Listening

    private func beginListening() {
        stopListening()
        synthesizer.stopSpeaking(at: .immediate)

        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            state = .error("语音识别不可用")
            return
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            state = .error("无法启动麦克风")
            return
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.taskHint = .dictation

        let input = audioEngine.inputNode
        let format = input.outputFormat(forBus: 0)
        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
            self?.updateLevel(from: buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            state = .error("音频引擎启动失败")
            return
        }

        liveUserText = ""
        finalUserText = ""
        state = .listening

        recognitionTask = recognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self else { return }
            Task { @MainActor in
                if let result {
                    let text = result.bestTranscription.formattedString
                    self.liveUserText = text
                    self.state = result.isFinal ? .recognizing : .listening
                    if result.isFinal {
                        self.finalUserText = text
                        self.handleFinalUtterance(text)
                    }
                }
                if error != nil {
                    // 超时或静音结束时，用当前部分结果提交
                    let text = self.liveUserText.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !text.isEmpty && self.state == .listening {
                        self.finalUserText = text
                        self.handleFinalUtterance(text)
                    } else if self.state == .listening {
                        self.beginListening()
                    }
                }
            }
        }

        // 简易端点：用户停顿约 1.6s 后用当前文字提交（部分识别结果）
        levelTimer?.invalidate()
        var silence: TimeInterval = 0
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                guard self.state == .listening || self.state == .recognizing else { return }
                if self.audioLevel < 0.12 {
                    silence += 0.2
                } else {
                    silence = 0
                }
                let text = self.liveUserText.trimmingCharacters(in: .whitespacesAndNewlines)
                if silence >= 1.6 && text.count >= 2 {
                    silence = 0
                    self.finalUserText = text
                    self.handleFinalUtterance(text)
                }
            }
        }
    }

    private func stopListening() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        levelTimer?.invalidate()
        levelTimer = nil
    }

    private func updateLevel(from buffer: AVAudioPCMBuffer) {
        guard let channel = buffer.floatChannelData?[0] else { return }
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return }
        var sum: Float = 0
        for i in 0..<frameLength {
            let v = channel[i]
            sum += v * v
        }
        let rms = sqrt(sum / Float(frameLength))
        let level = min(1, CGFloat(rms) * 8)
        Task { @MainActor in
            self.audioLevel = max(0.06, level)
        }
    }

    // MARK: - LLM + TTS

    private func handleFinalUtterance(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            beginListening()
            return
        }
        guard let settings, let store, var session else { return }

        stopListening()
        state = .thinking
        assistantText = ""

        // 写入用户消息
        session.messages.append(ChatMessage(role: .user, content: trimmed, createdAt: Date()))
        if !settings.systemPrompt.isEmpty,
           !session.messages.contains(where: { $0.role == .system }) {
            session.messages.insert(ChatMessage(role: .system, content: settings.systemPrompt, createdAt: Date()), at: 0)
        }
        session.messages.append(ChatMessage(role: .assistant, content: "", createdAt: Date(), isStreaming: true))
        self.session = session
        store.update(session)

        let config = settings.currentConfig()
        if config.apiKey.trimmingCharacters(in: .whitespaces).isEmpty {
            state = .error("请先配置 API Key")
            return
        }

        llmTask?.cancel()
        llmTask = Task {
            do {
                let stream = try await client.streamChat(messages: session.messages, config: config)
                var full = ""
                for try await part in stream {
                    if Task.isCancelled { break }
                    full += part
                    assistantText = full
                    if let i = self.session?.messages.lastIndex(where: { $0.role == .assistant }) {
                        self.session?.messages[i].content = full
                    }
                }
                if let i = self.session?.messages.lastIndex(where: { $0.isStreaming }) {
                    self.session?.messages[i].isStreaming = false
                    self.session?.messages[i].content = full
                }
                if let s = self.session { store.update(s) }
                self.speak(full)
            } catch {
                if !Task.isCancelled {
                    self.state = .error(error.localizedDescription)
                    if !self.isMuted { self.beginListening() }
                }
            }
        }
    }

    private func speak(_ text: String) {
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else {
            if !isMuted { beginListening() }
            return
        }
        state = .speaking
        audioLevel = 0.35
        let utterance = AVSpeechUtterance(string: clean)
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
            ?? AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        synthesizer.speak(utterance)
    }
}

extension VoiceSessionController: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.audioLevel = 0.08
            if !self.isMuted {
                self.liveUserText = ""
                self.finalUserText = ""
                self.beginListening()
            } else {
                self.state = .muted
            }
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.audioLevel = 0.08
        }
    }
}
