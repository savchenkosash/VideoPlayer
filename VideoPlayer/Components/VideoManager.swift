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

    // MARK: - Setup

    func setupPlayer() {
        let names = ["video1", "video2", "video3"]
        self.videoNames = names

        let items = names.compactMap { name -> AVPlayerItem? in
            guard let url = Bundle.main.url(forResource: name, withExtension: "mp4") else {
                print("❌ Видео \(name).mp4 не найдено")
                return nil
            }
            return AVPlayerItem(url: url)
        }

        guard !items.isEmpty else { return }

        self.playerItems = items

        let savedIndex = UserDefaults.standard.integer(forKey: lastVideoIndexKey)
        let savedTime  = UserDefaults.standard.double(forKey: lastVideoTimeKey)

        self.currentIndex = min(savedIndex, items.count - 1)

        print("""
        ▶️ VideoManager setup
        ▶️ Start video: \(videoNames[currentIndex])
        ▶️ Start time: \(String(format: "%.2f", savedTime)) sec
        """)

        let item = items[currentIndex]
        let player = AVPlayer(playerItem: item)
        self.player = player

        startObservingEndOfItem(item: item)

        if savedTime > 0 {
            let time = CMTime(seconds: savedTime, preferredTimescale: 600)
            player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
        }

        player.play()
    }

    // MARK: - Video switching logic

    private func startObservingEndOfItem(item: AVPlayerItem) {
        loopTask?.cancel()

        loopTask = Task {
            for await _ in NotificationCenter.default.notifications(
                named: .AVPlayerItemDidPlayToEndTime,
                object: item
            ) {
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    self.playNextVideo()
                }
            }
        }
    }

    private func playNextVideo() {
        currentIndex += 1

        if currentIndex >= playerItems.count {
            currentIndex = 0
        }

        UserDefaults.standard.set(0.0, forKey: lastVideoTimeKey)

        let nextName = videoNames[currentIndex]
        print("⏭ Переключение на следующее видео: \(nextName)")

        let nextItem = playerItems[currentIndex]
        player?.replaceCurrentItem(with: nextItem)
        startObservingEndOfItem(item: nextItem)
        player?.play()
    }

    // MARK: - Cleanup

    func cleanupPlayer() {
        let time = player?.currentTime().seconds ?? 0

        print("""
        ⏹ VideoManager cleanup
        ⏹ Closed video: \(videoNames.indices.contains(currentIndex) ? videoNames[currentIndex] : "unknown")
        ⏹ Closed at time: \(String(format: "%.2f", time)) sec
        """)

        UserDefaults.standard.set(currentIndex, forKey: lastVideoIndexKey)
        UserDefaults.standard.set(time, forKey: lastVideoTimeKey)

        loopTask?.cancel()
        loopTask = nil

        player?.pause()
        player = nil

        playerItems.removeAll()
        currentIndex = 0
    }
}





//import AVKit
//import Foundation
//
//@MainActor
//final class VideoManager: ObservableObject {
//
//    @Published var player: AVPlayer?
//
//    private var playerItems: [AVPlayerItem] = []
//    private var currentIndex: Int = 0
//    private var loopTask: Task<Void, Never>?
//
//    // MARK: - Setup
//
//    func setupPlayer() {
//        // Имена видео без расширения
//        let videoNames = ["video1", "video2", "video3"]
//
//        let items = videoNames.compactMap { name -> AVPlayerItem? in
//            guard let url = Bundle.main.url(forResource: name, withExtension: "mp4") else {
//                print("Видео \(name).mp4 не найдено")
//                return nil
//            }
//            return AVPlayerItem(url: url)
//        }
//
//        guard !items.isEmpty else { return }
//
//        self.playerItems = items
//        self.currentIndex = 0
//
//        let player = AVPlayer(playerItem: items[0])
//        self.player = player
//
//        startObservingEndOfItem(item: items[0])
//        player.play()
//    }
//
//    // MARK: - Video switching logic
//
//    private func startObservingEndOfItem(item: AVPlayerItem) {
//        loopTask?.cancel()
//
//        loopTask = Task {
//            for await _ in NotificationCenter.default.notifications(
//                named: .AVPlayerItemDidPlayToEndTime,
//                object: item
//            ) {
//                guard !Task.isCancelled else { return }
//
//                await MainActor.run {
//                    self.playNextVideo()
//                }
//            }
//        }
//    }
//
//    private func playNextVideo() {
//        currentIndex += 1
//
//        // 🔁 ВАРИАНТ 1: начать сначала
////        if currentIndex >= playerItems.count {
////            currentIndex = 0
////        }
//
//        // ❌ ВАРИАНТ 2: остановиться в конце
//         if currentIndex >= playerItems.count {
//             player?.pause()
//             return
//         }
//
//        let nextItem = playerItems[currentIndex]
//        player?.replaceCurrentItem(with: nextItem)
//        startObservingEndOfItem(item: nextItem)
//        player?.play()
//    }
//
//    // MARK: - Cleanup
//
//    func cleanupPlayer() {
//        loopTask?.cancel()
//        loopTask = nil
//        player?.pause()
//        player = nil
//        playerItems.removeAll()
//        currentIndex = 0
//    }
//}








//import AVKit
//import Foundation
//
//@MainActor
//final class VideoManager: ObservableObject {
//
//    @Published var player: AVPlayer?
//
//    private var playerItem: AVPlayerItem?
//    private var loopTask: Task<Void, Never>?
//
//    // MARK: - Setup
//
//    func setupPlayer() {
//        guard let url = Bundle.main.url(forResource: "video", withExtension: "mp4") else {
//            print("Видео не найдено")
//            return
//        }
//
//        let item = AVPlayerItem(url: url)
//        let player = AVPlayer(playerItem: item)
//
//        self.playerItem = item
//        self.player = player
//
//        startLooping()
//    }
//
//    // MARK: - Loop logic (async / await)
//
//    private func startLooping() {
//        guard let item = playerItem else { return }
//
//        loopTask = Task {
//            for await _ in NotificationCenter.default.notifications(
//                named: .AVPlayerItemDidPlayToEndTime,
//                object: item
//            ) {
//                guard !Task.isCancelled else { return }
//
//                await MainActor.run {
//                    self.player?.seek(to: .zero)
//                    self.player?.play()
//                }
//            }
//        }
//    }
//
//    // MARK: - Cleanup
//
//    func cleanupPlayer() {
//        loopTask?.cancel()
//        loopTask = nil
//
//        player?.pause()
//        player = nil
//        playerItem = nil
//    }
//}
