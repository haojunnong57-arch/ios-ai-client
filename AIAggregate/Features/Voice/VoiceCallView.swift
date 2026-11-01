import SwiftUI

struct VoiceCallView: View {
    @StateObject private var controller = VoiceSessionController()
    @EnvironmentObject var store: SessionStore
    @EnvironmentObject var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    let session: ChatSession

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.black.opacity(0.92),
                    Color(red: 0.08, green: 0.10, blue: 0.16),
                    Color.black.opacity(0.95)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                Spacer(minLength: 12)

                VoiceOrbView(level: controller.audioLevel, state: controller.state)
                    .frame(height: 240)

                statusLabel
                    .padding(.top, 18)

                captionArea
                    .padding(.horizontal, 28)
                    .padding(.top, 20)
                    .frame(maxHeight: 140)

                Spacer(minLength: 12)
                bottomControls
                    .padding(.bottom, 28)
            }
        }
        .onAppear {
            controller.configure(session: session, store: store, settings: settings)
            controller.start()
        }
        .onDisappear {
            controller.stopEverything()
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                controller.stopEverything()
                dismiss()
            } label: {
                Image(systemName: "chevron.down")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(10)
                    .background(.ultraThinMaterial, in: Circle())
            }
            Spacer()
            Text("语音通话")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.9))
            Spacer()
            Color.clear.frame(width: 40, height: 40)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private var statusLabel: some View {
        Text(controller.state.statusText)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.white.opacity(0.75))
    }

    private var captionArea: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                if !controller.liveUserText.isEmpty || !controller.finalUserText.isEmpty {
                    Text(controller.finalUserText.isEmpty ? controller.liveUserText : controller.finalUserText)
                        .font(.body)
                        .foregroundStyle(controller.finalUserText.isEmpty ? Color.white.opacity(0.55) : Color.white.opacity(0.92))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                if !controller.assistantText.isEmpty {
                    Text(controller.assistantText)
                        .font(.body)
                        .foregroundStyle(Color.white.opacity(0.88))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private var bottomControls: some View {
        HStack(spacing: 36) {
            Button {
                controller.toggleMute()
            } label: {
                VStack(spacing: 8) {
                    Image(systemName: controller.isMuted ? "mic.slash.fill" : "mic.fill")
                        .font(.title2)
                        .frame(width: 58, height: 58)
                        .background(.ultraThinMaterial, in: Circle())
                        .foregroundStyle(controller.isMuted ? Color.red : Color.white)
                    Text(controller.isMuted ? "已静音" : "静音")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }

            Button {
                controller.interruptSpeaking()
            } label: {
                VStack(spacing: 8) {
                    Image(systemName: "hand.raised.fill")
                        .font(.title2)
                        .frame(width: 58, height: 58)
                        .background(.ultraThinMaterial, in: Circle())
                        .foregroundStyle(.white)
                    Text("打断")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }

            Button {
                controller.stopEverything()
                dismiss()
            } label: {
                VStack(spacing: 8) {
                    Image(systemName: "xmark")
                        .font(.title2.weight(.bold))
                        .frame(width: 58, height: 58)
                        .background(Color.red.opacity(0.9), in: Circle())
                        .foregroundStyle(.white)
                    Text("结束")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
        }
    }
}
