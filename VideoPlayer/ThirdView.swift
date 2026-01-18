//
//  ThirdView.swift
//  VideoPlayer
//
//  Created by alexander on 18.01.26.
//

import SwiftUI

struct ThirdView: View {
    
    @StateObject private var audioManager = AudioManager()
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        Text("Third view with audio")
        
        AudioPlayerView(audioManager: audioManager)
            .padding()
        
        Button("Back to second screen") {
            presentationMode.wrappedValue.dismiss()
        }
    }
        
}

#Preview {
    ThirdView()
}
