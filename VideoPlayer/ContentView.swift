//
//  ContentView.swift
//  VideoPlayer
//
//  Created by alexander on 18.01.26.
//

import SwiftUI
import AVKit

struct ContentView: View {
    
    @StateObject private var videoManager = VideoManager()
    
    var body: some View {
        
        NavigationStack {
            
            ZStack(alignment: .bottom) {
                
                VideoPlayerView(videoManager: videoManager, videoNames: ["video1", "video2", "video3"])
                
                NavigationLink("Second View") {
                    SecondView()
                }
                .foregroundColor(.white)
                .frame(width: 180, height: 50)
                .background(Color.blue)
                .cornerRadius(25)
            }
        }
    }
}


#Preview {
    ContentView()
}
