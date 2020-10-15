//
//  VideoCompositionInstruction.swift
//  VideoEditor-Demo
//
//  Created by Maxim Kotliar on 13.10.2020.
//

import AVFoundation
import CoreImage

open class VideoCompositionInstruction: NSObject, AVVideoCompositionInstructionProtocol {

    public var timeRange: CMTimeRange
    public var enablePostProcessing: Bool
    public var containsTweening: Bool
    public var requiredSourceTrackIDs: [NSValue]?
    public var passthroughTrackID: CMPersistentTrackID = kCMPersistentTrackID_Invalid

    init(timeRange: CMTimeRange,
                  enablePostProcessing: Bool,
                  containsTweening: Bool,
                  requiredSourceTrackIDs: [NSValue]? = nil,
                  passthroughTrackID: CMPersistentTrackID = kCMPersistentTrackID_Invalid) {
        self.timeRange = timeRange
        self.enablePostProcessing = enablePostProcessing
        self.containsTweening = containsTweening
        self.requiredSourceTrackIDs = requiredSourceTrackIDs
        self.passthroughTrackID = passthroughTrackID
    }
}
