//
//  ContentView.swift
//  VideoAdTest
//
//  Created by schmidtt on 7/25/23.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack {
                NavigationLink {
                    VideoPlayerWrapper()
                } label: {
                    Text("Play Video")
                }
            }
            .padding()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
