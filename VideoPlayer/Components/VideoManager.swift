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





//import Foundation
//import Combine
//import AVKit
//
//
//class VideoManager: ObservableObject {
//    
//    @Published var player: AVPlayer?
//    
//    private var playerItem: AVPlayerItem?
//    private var playerObserver: AnyCancellable?
//
//    // Функция для создания нового AVPlayer
//    func setupPlayer() {
//        guard let url = Bundle.main.url(forResource: "video", withExtension: "mp4") else {
//            print("Видео не найдено!")
//            return
//        }
//        
//        // Создаем AVPlayerItem и передаем его в AVPlayer
//        playerItem = AVPlayerItem(url: url)
//        player = AVPlayer(playerItem: playerItem)
//        
//        // Наблюдаем за окончанием видео и зацикливаем его
//        playerObserver = NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: playerItem)
//            .sink { _ in
//                self.player?.seek(to: .zero)
//                self.player?.play()
//            }
//    }
//    
//    // Функция для очистки плеера
//    func cleanupPlayer() {
//        player?.pause()
//        player = nil
//        playerItem = nil
//        playerObserver?.cancel() // Отменяем подписку на уведомление
//        playerObserver = nil
//    }
    
    
    
//    @Published var player: AVPlayer?
//
//    // Функция для создания нового AVPlayer
//    func setupPlayer() {
//        guard let url = Bundle.main.url(forResource: "video", withExtension: "mp4") else {
//            print("Видео не найдено!")
//            return
//        }
//        self.player = AVPlayer(url: url)
//    }
//
//    // Функция для очистки плеера
//    func cleanupPlayer() {
//        player?.pause()
//        player = nil
//    }

