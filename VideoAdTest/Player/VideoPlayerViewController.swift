//
//  VideoPlayerViewController.swift
//  WSJVideo
//
//  Created by Tim Schmidt on 6/10/19.
//  Copyright © 2019 Dow Jones. All rights reserved.
//

import UIKit
import AdSupport
import AppTrackingTransparency
import AVFoundation
import AVKit
import GoogleInteractiveMediaAds
import SwiftUI

class VideoPlayerViewController: UIViewController, AVPlayerViewControllerDelegate, IMAAdsLoaderDelegate, IMAAdsManagerDelegate {
    var url: URL!
    
    private var adCountdownLabel: UILabel?
    private var adDisplayContainer: IMAAdDisplayContainer?
    private var adsLoader: IMAAdsLoader?
    private var adsManager: IMAAdsManager?
    var contentPlayerViewController: AVPlayerViewController?
    private var contentPlayhead: IMAAVPlayerContentPlayhead?
    private var firstVideo: Bool = true
    private var isPlayingAd: Bool = false
    private var playerRateObservation: NSKeyValueObservation?
    private var playerStatusObservation: NSKeyValueObservation?
    private var playerItemStatusObservation: NSKeyValueObservation?
    private var sessionStarted: Bool = false

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        startPlayback(autoPlay: !firstVideo)
        
        // disable the screen saver while video is playing
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        NotificationCenter.default.removeObserver(self)
        playerRateObservation?.invalidate()
        playerStatusObservation?.invalidate()
        playerItemStatusObservation?.invalidate()
        
        hideContentPlayer()
        
        // make SURE the player doesn't keep playing in the background!
        contentPlayerViewController?.player?.replaceCurrentItem(with: nil)

        // re-enable the screen saver now that video is going away
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    func setupAdsLoader() {
        adsLoader = IMAAdsLoader()
        adsLoader?.delegate = self
    }
    
    func setupContentPlayer() {
        guard contentPlayerViewController == nil else {
            print("Content player already created")
            return
        }
        
        let player = AVPlayer()
        contentPlayerViewController = AVPlayerViewController()
        contentPlayerViewController?.player = player
        contentPlayerViewController?.view.frame = view.bounds
        contentPlayerViewController?.delegate = self
        contentPlayhead = IMAAVPlayerContentPlayhead(avPlayer: player)
    }
    
    func startPlayback(autoPlay: Bool) {
        guard contentPlayerViewController?.player == nil || !contentPlayerViewController!.player!.isPlaying else {
            print("Player already playing")
            return
        }

        setupAdsLoader()
        setupContentPlayer()

        let playerItem = AVPlayerItem(url: url)
        contentPlayerViewController?.player?.replaceCurrentItem(with: playerItem)
        
        playerStatusObservation = contentPlayerViewController?.player?.observe(\.status) { (player, change) in
            if let error = player.error {
                self.showCriticalError(error: error)
            }
        }
        
        playerItemStatusObservation = playerItem.observe(\.status) { (item, change) in
            if let error = item.error {
                self.showCriticalError(error: error)
            }
        }
        
        NotificationCenter.default.removeObserver(self)
        NotificationCenter.default.addObserver(self, selector: #selector(didPlayToEndTime), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: playerItem)
            
        loadAds(adURL: "https://pubads.g.doubleclick.net/gampad/ads?iu=/21775744923/external/vmap_ad_samples&sz=640x480&cust_params=sample_ar%3Dpreonly&ciu_szs=300x250%2C728x90&gdfp_req=1&ad_rule=1&output=vmap&unviewed_position_start=1&env=vp&impl=s&correlator=")
    }
    
    func loadAds(adURL: String) {
        adDisplayContainer = IMAAdDisplayContainer(adContainer: view, viewController: self)
        let adsRequest = IMAAdsRequest(adTagUrl: adURL, adDisplayContainer: adDisplayContainer!, contentPlayhead: contentPlayhead, userContext: nil)
        print("Ad url: \(adsRequest.adTagUrl ?? "")")
        adsLoader?.requestAds(with: adsRequest)
    }
    
    func showCriticalError(error: Error?) {
        hideContentPlayer()
        
        var message = "An error has occurred"
        if error != nil {
            message += ": \(error!.localizedDescription)"
        }
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            self.dismiss(animated: true)
        }))
        present(alert, animated: true)
    }
    
    func playVideo() {
        adsManager?.pause()
        isPlayingAd = false
        showContentPlayer()
        contentPlayerViewController?.player?.play()

//        for testing autochain behavior, skip to end-5 seconds
//        if let duration = contentPlayerViewController?.player?.currentItem?.asset.duration.seconds {
//            contentPlayerViewController?.player?.seek(to: CMTimeMakeWithSeconds(duration - 5, preferredTimescale: 1),
//                                                      toleranceBefore: .zero, toleranceAfter: .zero)
//        }
    }
    
    func showContentPlayer() {
        hideCountdown()
        addChild(contentPlayerViewController!)
        contentPlayerViewController?.view.frame = view.bounds
        view.insertSubview(contentPlayerViewController!.view, at: 0)
        contentPlayerViewController?.didMove(toParent: self)
    }
    
    func hideContentPlayer() {
        hideCountdown()
        contentPlayerViewController?.player?.pause()
        contentPlayerViewController?.willMove(toParent: nil)
        contentPlayerViewController?.view.removeFromSuperview()
        contentPlayerViewController?.removeFromParent()
    }
    
    private func hideCountdown() {
        adCountdownLabel?.removeFromSuperview()
        adCountdownLabel = nil
    }
    
    func adsLoader(_ loader: IMAAdsLoader, adsLoadedWith adsLoadedData: IMAAdsLoadedData) {
        adsManager = adsLoadedData.adsManager
        adsManager?.delegate = self
        adsManager?.initialize(with: nil)
    }
    
    func adsLoader(_ loader: IMAAdsLoader, failedWith adErrorData: IMAAdLoadingErrorData) {
        print("Error loading ads: \(adErrorData.adError.message ?? "none")")
        playVideo()
    }
    
    func adsManager(_ adsManager: IMAAdsManager, didReceive event: IMAAdEvent) {
        switch (event.type) {
        case .LOADED:
            isPlayingAd = true
            adsManager.start()
        default:
            break
        }
    }
    
    func adsManager(_ adsManager: IMAAdsManager, didReceive error: IMAAdError) {
        print("AdsManager error: \(error.message ?? "none")")
        playVideo()
    }
    
    func adsManagerDidRequestContentPause(_ adsManager: IMAAdsManager) {
        hideContentPlayer()
    }
    
    func adsManagerDidRequestContentResume(_ adsManager: IMAAdsManager) {
        playVideo()
    }
    
    func adsManager(_ adsManager: IMAAdsManager, adDidProgressToTime mediaTime: TimeInterval, totalTime: TimeInterval) {
        // Check if we've already added the countdown view
        if adCountdownLabel == nil {
            adCountdownLabel = UILabel()
            adCountdownLabel!.font = .systemFont(ofSize: 28)
            adCountdownLabel!.textColor = .white
            adCountdownLabel!.shadowColor = .black
            adCountdownLabel!.shadowOffset = .init(width: 2, height: 2)
            adCountdownLabel!.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(adCountdownLabel!)
            adCountdownLabel!.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20).isActive = true
            adCountdownLabel!.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20).isActive = true
        }

        adCountdownLabel!.text = "Ad : (\(TimeInterval(round(totalTime - mediaTime)))"
    }
    
    @objc func didPlayToEndTime(notification: Notification) {
        guard let playerItem = notification.object as? AVPlayerItem,
            playerItem == contentPlayerViewController?.player?.currentItem,
            // this is to get around an apparent bug where we get this notification at the START of a video
            abs(CMTimeGetSeconds(playerItem.duration) - CMTimeGetSeconds(playerItem.currentTime())) < 1.0 else {
                return
        }

        hideContentPlayer()
        dismiss(animated: true)
    }
}

extension AVPlayer {
    var isPlaying: Bool {
        return rate != 0 && error == nil
    }
}
