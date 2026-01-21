//
//  VideoManager.swift
//  VideoPlayer
//
//  Created by alexander on 18.01.26.
//

import AVKit
import Foundation

@MainActor
final class VideoManager: ObservableObject {

    @Published var player: AVPlayer?

    private var playerItems: [AVPlayerItem] = []
    private var videoNames: [String] = []
    private var currentIndex: Int = 0
    private var loopTask: Task<Void, Never>?

    private let lastVideoIndexKey = "VideoManager.lastVideoIndex"
    private let lastVideoTimeKey  = "VideoManager.lastVideoTime"

    // 🔹 Задаём список видео
    func setVideoList(_ videos: [String]) {
        self.videoNames = videos
        self.playerItems = videos.compactMap { name in
            guard let url = urlForVideoAsset(named: name) else { return nil }
            return AVPlayerItem(url: url)
        }
    }

    func setupPlayer() {
        // 🔹 Если плеер уже есть, ничего не делаем
        guard player == nil else {
            print("⚠️ AVPlayer уже создан — пропускаем setup")
            return
        }

        guard !playerItems.isEmpty else {
            print("❌ VideoManager: нет видео для воспроизведения")
            return
        }
        
        // Воспроизведение с сохранённой позиции
        let savedIndex = UserDefaults.standard.integer(forKey: lastVideoIndexKey)
        let savedTime  = UserDefaults.standard.double(forKey: lastVideoTimeKey)
        currentIndex = min(savedIndex, playerItems.count - 1)

        let item = playerItems[currentIndex]
        let player = AVPlayer(playerItem: item)
        self.player = player

        print("▶️ Setup video: \(videoNames[currentIndex]), saved time: \(String(format: "%.2f", savedTime)) sec")

        startObservingEndOfItem(item: item)
        restorePlaybackPosition(for: item, savedTime: savedTime)
    }

    private func restorePlaybackPosition(for item: AVPlayerItem, savedTime: Double) {
        item.asset.loadValuesAsynchronously(forKeys: ["duration"]) {
            Task { @MainActor in
                let duration = item.asset.duration.seconds
                let safeTime = min(savedTime, max(duration - 0.5, 0))
                let time = CMTime(seconds: safeTime, preferredTimescale: 600)
                self.player?.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
                self.player?.play()
                print("▶️ Playing video: \(self.videoNames[self.currentIndex]), start time: \(String(format: "%.2f", safeTime)) / \(String(format: "%.2f", duration)) sec")
            }
        }
    }

    private func urlForVideoAsset(named name: String) -> URL? {
        guard let asset = NSDataAsset(name: name) else { return nil }
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(name).mp4")
        try? asset.data.write(to: tempURL, options: .atomic)
        return tempURL
    }

    private func startObservingEndOfItem(item: AVPlayerItem) {
        loopTask?.cancel()
        loopTask = Task {
            for await _ in NotificationCenter.default.notifications(
                named: .AVPlayerItemDidPlayToEndTime,
                object: item
            ) {
                guard !Task.isCancelled else { return }
                await MainActor.run { self.playNextVideo() }
            }
        }
    }

    private func playNextVideo() {
        let previousName = videoNames[currentIndex]
        currentIndex = (currentIndex + 1) % playerItems.count
        let nextItem = playerItems[currentIndex]
        let nextName = videoNames[currentIndex]

        print("⏹ Finished video: \(previousName)")
        print("⏭ Switching to video: \(nextName)")

        player?.replaceCurrentItem(with: nextItem)
        startObservingEndOfItem(item: nextItem)
        restorePlaybackPosition(for: nextItem, savedTime: 0)
    }

    func cleanupPlayer() {
        let time = player?.currentTime().seconds ?? 0
        print("⏹ Cleanup video: \(videoNames.indices.contains(currentIndex) ? videoNames[currentIndex] : "unknown"), saved time: \(String(format: "%.2f", time)) sec")

        UserDefaults.standard.set(currentIndex, forKey: lastVideoIndexKey)
        UserDefaults.standard.set(time, forKey: lastVideoTimeKey)

        loopTask?.cancel()
        loopTask = nil
        player?.pause()
        player = nil
        playerItems.removeAll()
        videoNames.removeAll()
        currentIndex = 0
    }
}
