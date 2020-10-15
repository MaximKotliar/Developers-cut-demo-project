//
//  ViewController.swift
//  VideoEditor-Demo
//
//  Created by Maxim Kotliar on 13.10.2020.
//

import Foundation
import CoreImage
import AVKit
import AVFoundation
import Accelerate
import Combine

extension AVURLAsset {

    // 1080p video
    static var video1: AVURLAsset { AVURLAsset(url: Bundle.main.url(forResource: "video1", withExtension: "mov")!) }
    // 720p video
    static var video2: AVURLAsset { AVURLAsset(url: Bundle.main.url(forResource: "video2_720", withExtension: "mov")!) }
    static var audio1: AVURLAsset { AVURLAsset(url: Bundle.main.url(forResource: "audio1", withExtension: "m4a")!) }
    static var audio2: AVURLAsset { AVURLAsset(url: Bundle.main.url(forResource: "audio2", withExtension: "m4a")!) }
}

class ViewController: AVPlayerViewController {

    private var timer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        run()
    }

    func play(item: AVPlayerItem) {
        self.player = AVPlayer(playerItem: item)
        player?.play()
    }
}



// MARK: Run
extension ViewController {
    func run() {
        runAVCompositionDemo()
        //runAVVideoCompositionDemo()
        //runAVAudioMixDemo()
        //runAVExportSessionDemo()
    }
}

// MARK: AVComposition Demo
extension ViewController {

    func runAVCompositionDemo() {
        let composition = try! composition3()
        let item = AVPlayerItem(asset: composition)
        play(item: item)
    }

    /// Simple two video join
    func composition1() throws -> AVComposition {
        let assets: [AVURLAsset] = [.video1, .video2]
        let composition = AVMutableComposition()
        let videoTrack = composition.addMutableTrack(withMediaType: .video,
                                                           preferredTrackID: kCMPersistentTrackID_Invalid)
        for asset in assets {
            if let assetTrack = asset.tracks(withMediaType: .video).first {
                try videoTrack?.insertTimeRange(assetTrack.timeRange, of: assetTrack, at: composition.duration)
            }
        }
        return composition.copy() as! AVComposition
    }

    /// Two videos join with scale
    func composition2() throws -> AVComposition {
        let assets: [AVURLAsset] = [.video1, .video2]
        let speed: Float64 = 5
        let scale = 1 / speed
        let composition = AVMutableComposition()
        let videoTrack = composition.addMutableTrack(withMediaType: .video,
                                                           preferredTrackID: kCMPersistentTrackID_Invalid)
        for asset in assets {
            if let assetTrack = asset.tracks(withMediaType: .video).first {
                let insertTimeRange = CMTimeRange(start: composition.duration, duration: assetTrack.timeRange.duration)
                try videoTrack?.insertTimeRange(assetTrack.timeRange, of: assetTrack, at: insertTimeRange.start)
                videoTrack?.scaleTimeRange(insertTimeRange, toDuration: CMTimeMultiplyByFloat64(assetTrack.timeRange.duration, multiplier: scale))
            }
        }
        return composition.copy() as! AVComposition
    }

    /// With audio
    func composition3() throws -> AVComposition {
        let videos: [AVURLAsset] = [.video1, .video2]
        let audios: [AVURLAsset] = [.audio1, .audio2]
        let composition = AVMutableComposition()

        // Insert videos into video track
        let videoTrack = composition.addMutableTrack(withMediaType: .video,
                                                     preferredTrackID: kCMPersistentTrackID_Invalid)!
        for video in videos {
            if let assetTrack = video.tracks(withMediaType: .video).first {
                try videoTrack.insertTimeRange(assetTrack.timeRange, of: assetTrack, at: composition.duration)
            }
        }

        // Insert videos into video track
        var nextAudioStart: CMTime = .zero
        for audio in audios {
            if let audioTrack = audio.tracks(withMediaType: .audio).first {
                let compositionTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)!
                try compositionTrack.insertTimeRange(audioTrack.timeRange, of: audioTrack, at: nextAudioStart)
                nextAudioStart = compositionTrack.timeRange.end
            }
        }
        return composition.copy() as! AVComposition
    }
}


// MARK: AVVideoComposition Demo
extension ViewController {

    /// Two videos transition (overlapped video tracks)
    func composition4() throws -> AVComposition {
        let assets: [AVURLAsset] = [.video1, .video2]
        let transitionDuration = CMTime(seconds: 2, preferredTimescale: 1)
        let composition = AVMutableComposition()
        var nextVideoStartTime: CMTime = .zero
        for asset in assets {
            let videoTrack = composition.addMutableTrack(withMediaType: .video,
                                                         preferredTrackID: kCMPersistentTrackID_Invalid)
            if let assetTrack = asset.tracks(withMediaType: .video).first {
                try videoTrack?.insertTimeRange(assetTrack.timeRange, of: assetTrack, at: nextVideoStartTime)
                nextVideoStartTime = composition.duration - transitionDuration
            }
        }
        return composition.copy() as! AVComposition
    }

    func runAVVideoCompositionDemo() {
        let composition = try! composition3()
       // let composition = try! composition4()
        let item = AVPlayerItem(asset: composition)
        item.videoComposition = try! videoComposition1(composition)
        //item.videoComposition = try! videoComposition2(composition)
        play(item: item)
    }


    func videoComposition1(_ asset: AVAsset) throws -> AVVideoComposition {
        let composition = AVVideoComposition(asset: asset) { request in
            let finalImage = request.sourceImage.blurred(30)
            request.finish(with: finalImage, context: nil)
        }
        return composition
    }

    func videoComposition2(_ asset: AVAsset) throws -> AVVideoComposition {
        let composition = AVMutableVideoComposition(propertiesOf: asset)
        //composition.renderSize = CGSize(width: 1920, height: 1400)
        composition.customVideoCompositorClass = CustomVideoCompositor.self
        return composition.copy() as! AVVideoComposition
    }
}



// MARK: AVAudioMix Demo
extension ViewController {

    func runAVAudioMixDemo() {
        let audioMix = AVMutableAudioMix()
        let composition = try! composition5(audioMix)
        let item = AVPlayerItem(asset: composition)
        item.videoComposition = try! videoComposition2(composition)
        item.audioMix = audioMix.copy() as? AVAudioMix
        play(item: item)
    }


    /// With audio
    func composition5(_ audioMix: AVMutableAudioMix) throws -> AVComposition {
        let audios: [AVURLAsset] = [.audio1, .audio2]
        let composition = try composition4().mutableCopy() as! AVMutableComposition

        // Insert videos into video track
        var nextAudioStart: CMTime = .zero
        let audioOverlap: CMTime = CMTime(value: 6, timescale: 4)
        for audio in audios {
            if let audioTrack = audio.tracks(withMediaType: .audio).first {
                let compositionTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)!
                let insertRange = CMTimeRange(start: nextAudioStart, duration: audioTrack.timeRange.duration)
                try compositionTrack.insertTimeRange(audioTrack.timeRange, of: audioTrack, at: insertRange.start)
                let audioParameters = AVMutableAudioMixInputParameters(track: compositionTrack)
                audioParameters.setVolumeRamp(fromStartVolume: 0,
                                              toEndVolume: 1,
                                              timeRange: CMTimeRange(start: insertRange.start,
                                                                     duration: insertRange.start + audioOverlap))
                audioParameters.setVolumeRamp(fromStartVolume: 1,
                                              toEndVolume: 0,
                                              timeRange: CMTimeRange(start: insertRange.end - audioOverlap,
                                                                     duration: audioOverlap))
                audioMix.inputParameters.append(audioParameters)
                nextAudioStart = compositionTrack.timeRange.end - audioOverlap
            }
        }
        return composition.copy() as! AVComposition
    }
}


// MARK: AVExportSession Demo
extension ViewController {

    func runAVExportSessionDemo() {
        let audioMix = AVMutableAudioMix()
        let composition = try! composition5(audioMix)
        let videoComposition = try! videoComposition2(composition)
        try? export(asset: composition, audioMix: audioMix, videoComposition: videoComposition)
    }

    /// Export
    func export(asset: AVAsset, audioMix: AVAudioMix, videoComposition: AVVideoComposition) throws {

        /// Get free disk space
        let attributes = try FileManager.default.attributesOfFileSystem(forPath: NSTemporaryDirectory())
        guard let freeDiskSpace = attributes[.systemFreeSize] as? Int64 else { return }

        let desiredType: AVFileType = .mp4
        let outputFolder = URL(fileURLWithPath: NSTemporaryDirectory())

        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPreset1920x1080) else { return }
        exportSession.videoComposition = videoComposition
        exportSession.audioMix = audioMix
        exportSession.audioTimePitchAlgorithm = .spectral

        let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak exportSession] _ in
            exportSession.map { debugPrint($0.progress) }
        }
        self.timer = timer

        exportSession.determineCompatibleFileTypes { types in
            guard types.contains(desiredType) else {
                debugPrint("Desired type: \(desiredType) unsupported")
                return
            }

            exportSession.outputFileType = desiredType
            exportSession.outputURL = outputFolder.appendingPathComponent("\(UUID().uuidString).mp4")


            exportSession.estimateOutputFileLength { (length, error) in
                guard freeDiskSpace > length else {
                    debugPrint("Not enough free disk space for export")
                    return
                }

                exportSession.exportAsynchronously {
                    timer.invalidate()
                    if let error = exportSession.error {
                        debugPrint("Error while exporting: \(error)")
                    } else {
                        debugPrint("Export finished, output dir: \(exportSession.outputURL!.path)")
                    }
                }
            }
        }
    }
}
