//
//  VideoPlayListPlugin.swift
//  BilibiliLive
//
//  Created by yicheng on 2024/5/26.
//

import AVKit

class VideoPlayListPlugin: NSObject, CommonPlayerPlugin {
    var onPlayEnd: (() -> Void)?
    var onPlayNextWithInfo: ((PlayInfo) -> Void)?

    let nextProvider: VideoNextProvider?

    init(nextProvider: VideoNextProvider?) {
        self.nextProvider = nextProvider
    }

    func addMenuItems(current: inout [UIMenuElement]) -> [UIMenuElement] {
        let loopImage = UIImage(systemName: "infinity")
        let loopAction = UIAction(title: "循环播放", image: loopImage, state: Settings.loopPlay ? .on : .off) {
            action in
            action.state = (action.state == .off) ? .on : .off
            Settings.loopPlay = action.state == .on
        }
        if let setting = current.compactMap({ $0 as? UIMenu })
            .first(where: { $0.identifier == UIMenu.Identifier(rawValue: "setting") })
        {
            var child = setting.children
            child.append(loopAction)
            if let index = current.firstIndex(of: setting) {
                current[index] = setting.replacingChildren(child)
            }
            return []
        }
        return [loopAction]
    }

    func playerDidEnd(player: AVPlayer) {
        if !playNext() {
            if Settings.loopPlay {
                nextProvider?.reset()
                if !playNext() {
                    player.currentItem?.seek(to: .zero, completionHandler: nil)
                    player.play()
                }
                return
            }
            onPlayEnd?()
        }
    }

    private func playNext() -> Bool {
        if let next = nextProvider?.getNext() {
            onPlayNextWithInfo?(next)
            return true
        }
        return false
    }
}
