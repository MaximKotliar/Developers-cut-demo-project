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

    private let pixelBufferAttributes: [String: Any] = {
        [String(kCVPixelBufferPixelFormatTypeKey): kCVPixelFormatType_420YpCbCr8BiPlanarFullRange,
         String(kCVPixelBufferMetalCompatibilityKey): true,
         String(kCVPixelBufferOpenGLCompatibilityKey): true]
    }()

    public let ciContext: CIContext = CIContext()

    public var sourcePixelBufferAttributes: [String: Any]? { pixelBufferAttributes }
    public var requiredPixelBufferAttributesForRenderContext: [String: Any] { pixelBufferAttributes }

    func startRequest(_ asyncVideoCompositionRequest: AVAsynchronousVideoCompositionRequest) {
        let request = asyncVideoCompositionRequest
        if let resultPixels = renderPixelBuffer(for: request) {
            request.finish(withComposedVideoFrame: resultPixels)
        } else {
            request.finish(with: Error.noPixelBuffer)
        }
    }

    func renderPixelBuffer(for request: AVAsynchronousVideoCompositionRequest) -> CVPixelBuffer? {
        let renderContext = request.renderContext
        guard let outputPixels = renderContext.newPixelBuffer() else { return nil }

        var image = CIImage(cvPixelBuffer: outputPixels)

        // Add solid color background
        let backgroundImage = CIImage(color: .white).cropped(to: image.extent)
        image = backgroundImage.composited(over: image)

        if let id = request.sourceTrackIDs.first,
           let sourceBuffer = request.sourceFrame(byTrackID: id.int32Value) {

            image = CIImage(cvPixelBuffer: sourceBuffer)
                .fitted(in: renderContext)
                .composited(over: image)

            // Render transition
            if request.sourceTrackIDs.count > 1,
               let underlayImageBuffer =
                request.sourceFrame(byTrackID: request.sourceTrackIDs.last!.int32Value) {
                let range = request.videoCompositionInstruction.timeRange
                let transitionProgress = range.fraction(of: request.compositionTime)
//                let scaleProgress = CGFloat(transitionProgress)
                let scaleProgress = CGFloat(simd_smoothstep(0, 1, Float(transitionProgress)))
                let underlayImage = CIImage(cvPixelBuffer: underlayImageBuffer)
                    .fitted(in: renderContext)
                    {
                        $0.settingScale(x: scaleProgress, y: scaleProgress)
                            .settingRotation(.pi / 4 * (1 - scaleProgress))
                    }
                    .settingAlphaComponent(to: CGFloat(transitionProgress))
                    .blurred(30 * (1 - transitionProgress))

                image = underlayImage
                    .composited(over: image)

            }
        }

        // Filters
        //image = image.grayscale()

        // Add watermark
        let watermark = CIImage
            .watermark
            .addingShadow(radius: 30, opacity: 1)
            .fitted(in: renderContext) { $0
                .settingOrigin(CGPoint(x: 0.15, y: 0.15))
                .settingScale(x: 0.3, y: 0.3)
            }
        image = watermark.composited(over: image, blendingMode: .difference)

        ciContext.render(image, to: outputPixels)

        return outputPixels
    }
}

private extension CMTimeRange {

    func fraction(of time: CMTime) -> Float64 {
        (time - start).seconds / (end - start).seconds
    }
}

extension CustomVideoCompositor {
    func renderContextChanged(_ newRenderContext: AVVideoCompositionRenderContext) {
        // We need to handle context change here, omitted for simplifying purposes.
    }
}
