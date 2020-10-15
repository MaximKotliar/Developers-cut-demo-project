//
//  CustomVideoCompositor.swift
//  VideoEditor-Demo
//
//  Created by Maxim Kotliar on 13.10.2020.
//

import AVFoundation
import CoreImage
import Accelerate


final class CustomVideoCompositor: NSObject, AVVideoCompositing {

    enum Error: Swift.Error {
        case missingTrackID
        case noPixelBuffer
    }

    // What is PB?
    private let pixelBufferAttributes: [String: Any] = {
        [String(kCVPixelBufferPixelFormatTypeKey): kCVPixelFormatType_420YpCbCr8BiPlanarFullRange,
         String(kCVPixelBufferMetalCompatibilityKey): true,
         String(kCVPixelBufferOpenGLCompatibilityKey): true]
    }()

    public let ciContext: CIContext = CIContext()
    private let renderContextQueue: DispatchQueue = DispatchQueue(label: "renderContextSwitchQueue")
    private let renderingQueue: DispatchQueue = DispatchQueue(label: "renderQueue")
    private var renderContext: AVVideoCompositionRenderContext?
    public var sourcePixelBufferAttributes: [String: Any]? { pixelBufferAttributes }
    public var requiredPixelBufferAttributesForRenderContext: [String: Any] { pixelBufferAttributes }
    private var shouldCancelAllRequests = false

    func renderContextChanged(_ newRenderContext: AVVideoCompositionRenderContext) {
        renderContextQueue.sync { [weak self] in
            guard let self = self else { return }
            self.shouldCancelAllRequests = true
            self.renderContext = newRenderContext
            self.shouldCancelAllRequests = false
        }
    }

    func startRequest(_ asyncVideoCompositionRequest: AVAsynchronousVideoCompositionRequest) {
        let request = asyncVideoCompositionRequest
        renderingQueue.async(execute: { [weak self] in
            guard let self = self else { return }
            if self.shouldCancelAllRequests {
                request.finishCancelledRequest()
            } else {
                autoreleasepool {
                    if let resultPixels = self.renderPixelBuffer(for: request) {
                        request.finish(withComposedVideoFrame: resultPixels)
                    } else {
                        request.finish(with: Error.noPixelBuffer)
                    }
                }
            }
        })
    }

    func renderPixelBuffer(for request: AVAsynchronousVideoCompositionRequest) -> CVPixelBuffer? {
        guard let renderContext = renderContext,
              let outputPixels = renderContext.newPixelBuffer() else { return nil }

        var image = CIImage(cvPixelBuffer: outputPixels)

        // Add solid color background
        let backgroundImage = CIImage(color: .white).cropped(to: image.extent)
        image = backgroundImage.composited(over: image)

        if let id = request.sourceTrackIDs.first,
           let sourceBuffer = request.sourceFrame(byTrackID: id.int32Value) {

            image = CIImage(cvPixelBuffer: sourceBuffer)
                // Show UV system
                //.fitted(in: renderContext)
                .composited(over: image)

            // Render transition
//            if request.sourceTrackIDs.count > 1,
//               let underlayImageBuffer =
//                request.sourceFrame(byTrackID: request.sourceTrackIDs.last!.int32Value) {
//                let range = request.videoCompositionInstruction.timeRange
//                let transitionProgress = range.fraction(of: request.compositionTime)
////                let scaleProgress = CGFloat(transitionProgress)
////                let scaleProgress = CGFloat(simd_smoothstep(0, 1, Float(transitionProgress)))
//                let underlayImage = CIImage(cvPixelBuffer: underlayImageBuffer)
//                    .fitted(in: renderContext)
////                    {
////                        $0.settingScale(x: scaleProgress, y: scaleProgress)
////                            .settingRotation(.pi / 4 * (1 - scaleProgress))
////                    }
//                    //.settingAlphaComponent(to: CGFloat(transitionProgress))
//                    //.blurred(30 * (1 - transitionProgress))
//
//                image = underlayImage
//                    .composited(over: image)
//
//            }
        }

        // Filters
        //image = image.grayscale()

        // Add watermark
//        let watermark = CIImage
//            .watermark
//            .addingShadow(radius: 30, opacity: 1)
//            .fitted(in: renderContext)
////            { $0
////                .settingOrigin(CGPoint(x: 0.15, y: 0.15))
////                .settingScale(x: 0.3, y: 0.3)
////            }
//
//        image = watermark.composited(over: image)
    //    image = watermark.composited(over: image, blendingMode: .colorBurn)

        ciContext.render(image, to: outputPixels)

        return outputPixels
    }
}

private extension CMTimeRange {

    func fraction(of time: CMTime) -> Float64 {
        (time - start).seconds / (end - start).seconds
    }
}
