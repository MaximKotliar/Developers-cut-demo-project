//
//  DemoAssets.swift
//  VideoEditor-Demo
//
//  Created by Maxim Kotliar on 16.10.2020.
//

import AVFoundation
import CoreImage
import UIKit.UIImage

extension AVURLAsset {

    // 1080p video
    static var video1: AVURLAsset { AVURLAsset(url: Bundle.main.url(forResource: "video1", withExtension: "mov")!) }
    // 720p video
    static var video2: AVURLAsset { AVURLAsset(url: Bundle.main.url(forResource: "video2_720", withExtension: "mov")!) }
    static var audio1: AVURLAsset { AVURLAsset(url: Bundle.main.url(forResource: "audio1", withExtension: "m4a")!) }
    static var audio2: AVURLAsset { AVURLAsset(url: Bundle.main.url(forResource: "audio2", withExtension: "m4a")!) }
}

extension CIImage {
    static let watermark: CIImage = CIImage(image: UIImage(named: "watermark")!)!
}
