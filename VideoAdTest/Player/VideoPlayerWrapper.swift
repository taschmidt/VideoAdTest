//
//  VideoPlayerWrapper.swift
//  WSJVideo
//
//  Created by schmidtt on 4/21/23.
//  Copyright © 2023 Dow Jones. All rights reserved.
//

import Foundation
import AVFoundation
import SwiftUI

struct VideoPlayerWrapper: UIViewControllerRepresentable {
    typealias UIViewControllerType = VideoPlayerViewController

    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> VideoPlayerViewController {
        let vc = VideoPlayerViewController()
        vc.url = URL(string: "https://video-api.shdsvc.dowjones.io/api/hls-captions/manifest/9F7AF9B6-88BC-4AB6-B4C8-E0CF0C68E116.m3u8")
        return vc
    }
    
    func updateUIViewController(_ uiViewController: VideoPlayerViewController, context: Context) {}
}
