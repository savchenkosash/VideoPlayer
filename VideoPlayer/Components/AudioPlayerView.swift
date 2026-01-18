//
//  AudioPlayerView.swift
//  VideoPlayer
//
//  Created by alexander on 18.01.26.
//

import SwiftUI
import AVFoundation

struct AudioPlayerView: View {
    
    @ObservedObject var audioManager: AudioManager

    var body: some View {
        VStack {
            Image(systemName: "music.note")
                .font(.title)
        }
        .onAppear {
            // Настроим аудио при появлении view
            print("Start playing sound")
            audioManager.setupAudio()
            audioManager.playAudio()
        }
        .onDisappear {
            // Очищаем аудио при исчезновении view
            audioManager.cleanupAudio()
            print("Cleanup sound")
        }
    }
}

#Preview {
    AudioPlayerView(audioManager: AudioManager())
}

