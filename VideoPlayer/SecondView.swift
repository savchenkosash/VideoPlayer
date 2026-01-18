//
//  SecondView.swift
//  VideoPlayer
//
//  Created by alexander on 18.01.26.
//

import SwiftUI

struct SecondView: View {
    var body: some View {
        Text("Second (silent) view")
            .padding()
        NavigationLink("Go to third (music) view") {
            ThirdView()
        }
    }
}

#Preview {
    SecondView()
}
