//
//  VideoView.swift
//  VideoAdTest
//
//  Created by schmidtt on 7/25/23.
//

import SwiftUI
import AVFoundation
import _AVKit_SwiftUI

struct VideoView: View {
    var body: some View {
        let url = URL(string: "https://video-api.shdsvc.dowjones.io/api/hls-captions/manifest/9F7AF9B6-88BC-4AB6-B4C8-E0CF0C68E116.m3u8")
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
            VideoPlayer(player: AVPlayer(url: url!))
        } else {
            Text("Video preview")
        }
    }
}

struct VideoView_Previews: PreviewProvider {
    static var previews: some View {
        VideoView()
    }
}
