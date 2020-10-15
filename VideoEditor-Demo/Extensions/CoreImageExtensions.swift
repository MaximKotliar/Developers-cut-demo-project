//
//  CoreImageExtensions.swift
//  VideoEditor-Demo
//
//  Created by Maxim Kotliar on 13.10.2020.
//

import CoreImage
import UIKit.UIImage
import AVFoundation

extension CIImage {
    func flipYCoordinate() -> CIImage {
        let flipYTransform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: extent.origin.y * 2 + extent.height)
        return transformed(by: flipYTransform)
    }

    func settingAlphaComponent(to alpha: CGFloat) -> CIImage {
        let overlayFilter: CIFilter = CIFilter(name: "CIColorMatrix")!
        let overlayRgba: [CGFloat] = [0, 0, 0, alpha]
        let alphaVector: CIVector = CIVector(values: overlayRgba, count: 4)
        overlayFilter.setValue(self, forKey: kCIInputImageKey)
        overlayFilter.setValue(alphaVector, forKey: "inputAVector")
        return overlayFilter.outputImage!
    }

    func grayscale() -> CIImage {
        applyingFilter("CIPhotoEffectNoir")
    }

    static let watermark: CIImage = CIImage(image: UIImage(named: "watermark")!)!

    func transform(forCenteredAspectFitIn size: CGSize) -> CGAffineTransform {
        let xScale = size.width / extent.width
        let yScale = size.height / extent.height
        var transform: CGAffineTransform = .identity
        if xScale != 1 || yScale != 1 {
            if xScale < yScale {
                transform = transform
                    .translatedBy(x: 0, y: (size.height - (extent.height * xScale)) * 0.5)
                    .scaledBy(x: xScale, y: xScale)
            } else {
                transform = transform
                    .translatedBy(x: (size.width - (extent.width * yScale)) * 0.5, y: 0)
                    .scaledBy(x: yScale, y: yScale)
            }
        }
        return transform
    }

    func centered(in size: CGSize) -> CIImage {
        return transformed(by: transform(forCenteredAspectFitIn: size))
    }

    func croppedToExtent() -> CIImage {
        cropped(to: extent)
    }

    func blurred(_ radius: Double) -> CIImage {
        let extent = self.extent
        return clampedToExtent()
            .applyingGaussianBlur(sigma: radius)
            .cropped(to: extent)
    }

    func fitted(in context: AVVideoCompositionRenderContext,
                       uvTransform: (CGAffineTransform) -> CGAffineTransform = { $0 }) -> CIImage {
        let transform = self.transform(forCenteredAspectFitIn: context.size)
            .concatenating(uvTransform(.uvIdentity)
                            .toCILocal(forFrame: context.size))

        return self.transformed(by:transform,
                                highQualityDownsample: context.highQualityRendering)
    }


    func composited(over image: CIImage, blendingMode: BlendingMode) -> CIImage {
        applyingFilter(blendingMode.filterName, parameters: [kCIInputImageKey: self,
                                                             kCIInputBackgroundImageKey: image])
    }

    func crushedToBlack() -> CIImage {
        applyingFilter("CIColorClamp", parameters: ["inputMaxComponents": CIVector(x: 0, y: 0, z: 0, w: 1)])
    }

    func addingShadow(radius: Double = 30, opacity: CGFloat = 1) -> CIImage {
        let background = self
            .applyingGaussianBlur(sigma: radius)
            .settingAlphaComponent(to: opacity)
            .crushedToBlack()
        let foreground = self.transformed(by: self.extent.transform(forCenteringIn: background.extent))
        return foreground.composited(over: background)
    }
}

extension CIImage {

    enum BlendingMode {
        case add
        case color
        case colorBurn
        case colorDodge
        case darken
        case difference
        case divide
        case exclusion
        case hardLight
        case hue
        case lighten
        case linearBurn
        case linearDodge
        case luminocity
        case max
        case min
        case multiplyBlend
        case multiplyCompose
        case overlay
        case pinlight
        case saturation
        case screen
        case softLight
        case sourceOver

        var filterName: String {
            switch self {
            case .add:
                return "CIAdditionCompositing"
            case .color:
                return "CIColorBlendMode"
            case .colorBurn:
                return "CIColorBurnBlendMode"
            case .colorDodge:
                return "CIColorDodgeBlendMode"
            case .darken:
                return "CIDarkenBlendMode"
            case .difference:
                return "CIDifferenceBlendMode"
            case .divide:
                return "CIDivideBlendMode"
            case .exclusion:
                return "CIExclusionBlendMode"
            case .hardLight:
                return "CIHardLightBlendMode"
            case .hue:
                return "CIHueBlendMode"
            case .lighten:
                return "CILightenBlendMode"
            case .linearBurn:
                return "CILinearBurnBlendMode"
            case .linearDodge:
                return "CILinearDodgeBlendMode"
            case .luminocity:
                return "CILuminosityBlendMode"
            case .max:
                return "CIMaximumCompositing"
            case .min:
                return "CIMinimumCompositing"
            case .multiplyBlend:
                return "CIMultiplyBlendMode"
            case .multiplyCompose:
                return "CIMultiplyCompositing"
            case .overlay:
                return "CIOverlayBlendMode"
            case .pinlight:
                return "CIPinLightBlendMode"
            case .saturation:
                return "CISaturationBlendMode"
            case .screen:
                return  "CIScreenBlendMode"
            case .softLight:
                return "CISoftLightBlendMode"
            case .sourceOver:
                return "CISourceOverCompositing"
            }
        }
    }
}


extension CMTime {

    static func * (lhs: CMTime, rhs: Float64) -> CMTime {
        CMTimeMultiplyByFloat64(lhs, multiplier: rhs)
    }
    
}
