//
//  AudioManager.swift
//  VideoPlayer
//
//  Created by alexander on 18.01.26.
//

import AVKit
import Foundation

@MainActor
final class AudioManager: ObservableObject {

    @Published var audioPlayer: AVAudioPlayer?

    private var audioFileURL: URL?

    // MARK: - Setup

    func setupAudio() {
        // Пытаемся найти файл в Bundle
        guard let url = Bundle.main.url(forResource: "audio", withExtension: "mp3") else {
            print("Аудиофайл не найден!")
            return
        }

        self.audioFileURL = url

        do {
            // Создаем аудиоплеер с выбранным аудиофайлом
            let player = try AVAudioPlayer(contentsOf: url)
            self.audioPlayer = player

            // Включаем цикл, если нужно (Зацикливаем аудио)
//            player.numberOfLoops = -1

            // Применяем настройки громкости или других параметров
//            player.prepareToPlay()

        } catch {
            print("Не удалось создать плеер для аудио: \(error)")
        }
    }

    // MARK: - Control Audio Playback

    func playAudio() {
        audioPlayer?.play()
    }

    func pauseAudio() {
        audioPlayer?.pause()
    }

    func stopAudio() {
        audioPlayer?.stop()
        audioPlayer = nil
    }

    // MARK: - Cleanup

    func cleanupAudio() {
        audioPlayer?.stop()
        audioPlayer = nil
    }
}
