//
//  MaskViewPugin.swift
//  BilibiliLive
//
//  Created by yicheng on 2024/5/25.
//

import AVKit
import UIKit

class MaskViewPugin: NSObject, CommonPlayerPlugin {
    weak var maskView: UIView?
    var maskProvider: MaskProvider
    private var observer: Any?
    private var videoOutput: AVPlayerItemVideoOutput?

    init(maskView: UIView, maskProvider: MaskProvider) {
        self.maskView = maskView
        self.maskProvider = maskProvider
    }

    func playerDidChange(player: AVPlayer) {
        if maskProvider.needVideoOutput() {
            setUpOutput(player: player)
        }

        let timePerFrame = CMTime(value: 1, timescale: CMTimeScale(maskProvider.preferFPS()))
        observer = player.addPeriodicTimeObserver(forInterval: timePerFrame, queue: .main) {
            [weak self] time in
            guard let self, let maskView, !maskView.isHidden else { return }
            maskProvider.getMask(for: time, frame: maskView.frame) {
                [weak maskView] maskLayer in
                maskView?.layer.mask = maskLayer
            }
        }
    }

    func playerDidCleanUp(player: AVPlayer) {
        if let observer {
            player.removeTimeObserver(observer)
        }
    }

    private func setUpOutput(player: AVPlayer) {
        guard videoOutput == nil, let videoItem = player.currentItem else { return }
        let pixelBuffAttributes = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange,
        ]
        let videoOutput = AVPlayerItemVideoOutput(pixelBufferAttributes: pixelBuffAttributes)
        videoItem.add(videoOutput)
        self.videoOutput = videoOutput
        maskProvider.setVideoOutout(ouput: videoOutput)
    }
}
