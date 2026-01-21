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






/* FINAL CODE FOR VIDEO FILES IN PROJECT

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

 */

/* import AVKit
 import Foundation

 @MainActor
 final class VideoManager: ObservableObject {

     @Published var player: AVPlayer?

     private var playerItems: [AVPlayerItem] = []
     private var currentIndex: Int = 0
     private var loopTask: Task<Void, Never>?

     // MARK: - Setup

     func setupPlayer() {
         // Имена видео без расширения
         let videoNames = ["video1", "video2", "video3"]

         let items = videoNames.compactMap { name -> AVPlayerItem? in
             guard let url = Bundle.main.url(forResource: name, withExtension: "mp4") else {
                 print("Видео \(name).mp4 не найдено")
                 return nil
             }
             return AVPlayerItem(url: url)
         }

         guard !items.isEmpty else { return }

         self.playerItems = items
         self.currentIndex = 0

         let player = AVPlayer(playerItem: items[0])
         self.player = player

         startObservingEndOfItem(item: items[0])
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

         // 🔁 ВАРИАНТ 1: начать сначала
 //        if currentIndex >= playerItems.count {
 //            currentIndex = 0
 //        }

         // ❌ ВАРИАНТ 2: остановиться в конце
          if currentIndex >= playerItems.count {
              player?.pause()
              return
          }

         let nextItem = playerItems[currentIndex]
         player?.replaceCurrentItem(with: nextItem)
         startObservingEndOfItem(item: nextItem)
         player?.play()
     }

     // MARK: - Cleanup

     func cleanupPlayer() {
         loopTask?.cancel()
         loopTask = nil
         player?.pause()
         player = nil
         playerItems.removeAll()
         currentIndex = 0
     }
 }








 import AVKit
 import Foundation

 @MainActor
 final class VideoManager: ObservableObject {

     @Published var player: AVPlayer?

     private var playerItem: AVPlayerItem?
     private var loopTask: Task<Void, Never>?

     // MARK: - Setup

     func setupPlayer() {
         guard let url = Bundle.main.url(forResource: "video", withExtension: "mp4") else {
             print("Видео не найдено")
             return
         }

         let item = AVPlayerItem(url: url)
         let player = AVPlayer(playerItem: item)

         self.playerItem = item
         self.player = player

         startLooping()
     }

     // MARK: - Loop logic (async / await)

     private func startLooping() {
         guard let item = playerItem else { return }

         loopTask = Task {
             for await _ in NotificationCenter.default.notifications(
                 named: .AVPlayerItemDidPlayToEndTime,
                 object: item
             ) {
                 guard !Task.isCancelled else { return }

                 await MainActor.run {
                     self.player?.seek(to: .zero)
                     self.player?.play()
                 }
             }
         }
     }

     // MARK: - Cleanup

     func cleanupPlayer() {
         loopTask?.cancel()
         loopTask = nil

         player?.pause()
         player = nil
         playerItem = nil
     }
 }
 */


