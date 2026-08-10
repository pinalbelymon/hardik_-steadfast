import AVFoundation
import AVKit
import SwiftUI

struct TreeGrowthVideoPlayer: UIViewControllerRepresentable {
    let onFinished: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onFinished: onFinished)
    }

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.showsPlaybackControls = false
        controller.videoGravity = .resizeAspect
        controller.view.backgroundColor = .black

        guard let url = Bundle.main.url(
            forResource: "Tree_growth_time_lapse_animation_202608101137",
            withExtension: "mp4"
        ) else {
            DispatchQueue.main.async { onFinished() }
            return controller
        }

        VideoPlaybackAudio.activateForPlayback()

        let item = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: item)
        player.isMuted = false
        player.volume = 1
        player.automaticallyWaitsToMinimizeStalling = true

        controller.player = player
        context.coordinator.start(player: player, item: item)
        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}

    static func dismantleUIViewController(_ uiViewController: AVPlayerViewController, coordinator: Coordinator) {
        coordinator.stop()
    }

    final class Coordinator: NSObject {
        private let onFinished: () -> Void
        private var endObserver: NSObjectProtocol?
        private var statusObservation: NSKeyValueObservation?
        private var player: AVPlayer?

        init(onFinished: @escaping () -> Void) {
            self.onFinished = onFinished
        }

        func start(player: AVPlayer, item: AVPlayerItem) {
            self.player = player
            VideoPlaybackAudio.activateForPlayback()
            player.isMuted = false

            endObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: item,
                queue: .main
            ) { [weak self] _ in
                self?.finish()
            }

            if item.status == .readyToPlay {
                player.play()
                return
            }

            statusObservation = item.observe(\.status, options: [.new]) { [weak self] item, _ in
                guard let self else { return }
                switch item.status {
                case .readyToPlay:
                    DispatchQueue.main.async {
                        VideoPlaybackAudio.activateForPlayback()
                        player.isMuted = false
                        player.play()
                    }
                case .failed:
                    DispatchQueue.main.async {
                        self.finish()
                    }
                default:
                    break
                }
            }
        }

        func stop() {
            player?.pause()
            player = nil
            statusObservation?.invalidate()
            statusObservation = nil
            if let endObserver {
                NotificationCenter.default.removeObserver(endObserver)
                self.endObserver = nil
            }
        }

        private func finish() {
            stop()
            VideoPlaybackAudio.deactivate()
            onFinished()
        }

        deinit {
            stop()
        }
    }
}

private enum VideoPlaybackAudio {
    static func activateForPlayback() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .moviePlayback, options: [])
            try session.setActive(true)
        } catch {
            // Best-effort — without this, embedded video is often silent on device.
        }
    }

    static func deactivate() {
        try? AVAudioSession.sharedInstance().setActive(
            false,
            options: .notifyOthersOnDeactivation
        )
    }
}
