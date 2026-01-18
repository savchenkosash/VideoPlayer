//
//  VideoPlayerView.swift
//  VideoPlayer
//
//  Created by alexander on 18.01.26.
//

import SwiftUI
import AVKit

struct VideoPlayerView: View {
    
    @ObservedObject var videoManager: VideoManager
    
    var body: some View {
        
        VideoPlayer(player: videoManager.player)
                .onAppear {
                    print("Appear")
                    videoManager.setupPlayer()
                    videoManager.player?.play()
                    
                }
                .onDisappear {
                    print("Disappear")
                    // Очищаем плеер через менеджер
                    videoManager.cleanupPlayer()
                    print("Cleanup")
                }
                .scaleEffect(1.2)
                .disabled(true)
                .ignoresSafeArea()
                .edgesIgnoringSafeArea(.all)
                .overlay(Color.white.opacity(0.3))
        
    }
    
}

#Preview {
    VideoPlayerView(videoManager: VideoManager())
}
