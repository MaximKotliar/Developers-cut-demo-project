//
//  UVMapping.swift
//  VideoEditor-Demo
//
//  Created by Maxim Kotliar on 13.10.2020.
//

import QuartzCore

public extension CGAffineTransform {

    var scaleX: CGFloat { sqrt(a * a + c * c) }
    var scaleY: CGFloat { sqrt(b * b + d * d) }
    var rotation: CGFloat { atan2(b, a) }

    /// - parameter tx:  translation on x axis.
    /// - parameter ty:  translation on y axis.
    /// - parameter sx:  scale factor for width.
    /// - parameter sy:  scale factor for height.
    /// - parameter deg: degrees.
    init(tx: CGFloat, ty: CGFloat, sx: CGFloat, sy: CGFloat, rotation: CGFloat) {
        let translationTransform = CGAffineTransform(translationX: tx, y: ty)
        let scaleTransform = CGAffineTransform(scaleX: sx, y: sy)
        let rotationTransform = CGAffineTransform(rotationAngle: rotation)
        self = rotationTransform.concatenating(scaleTransform).concatenating(translationTransform)
    }
}

public extension CGAffineTransform {

    func toUV(relativeTo size: CGSize) -> CGAffineTransform {
        let uv = CGPoint(x: tx, y: ty).toUV(relativeTo: size)
        return CGAffineTransform(a: self.a, b: self.b, c: self.c, d: self.d, tx: uv.x, ty: uv.y)
    }

    func toLocal(forFrame size: CGSize) -> CGAffineTransform {
        let local = CGPoint(x: tx, y: ty).toLocal(relativeTo: size)
        return CGAffineTransform(a: self.a, b: self.b, c: self.c, d: self.d, tx: local.x, ty: local.y)
    }

    func toCILocal(forFrame size: CGSize) -> CGAffineTransform {
        var transform = CGAffineTransform.identity
        transform = transform.translatedBy(x: 0.5 * size.width, y: 0.5 * size.height)
        transform = transform.translatedBy(x: (tx - 0.5) * size.width, y: (-ty + 0.5) * size.height)
        transform = transform.rotated(by: -rotation)
        transform = transform.scaledBy(x: scaleX, y: scaleY)
        transform = transform.translatedBy(x: -0.5 * size.width, y: -0.5 * size.height)
        return transform
    }

    func settingOrigin(_ point: CGPoint) -> CGAffineTransform {
        var transform = self
        transform.tx = point.x
        transform.ty = point.y
        return transform
    }

    func settingScale(x: CGFloat, y: CGFloat) -> CGAffineTransform {
        CGAffineTransform(tx: tx, ty: ty, sx: x, sy: y, rotation: rotation)
    }

    func settingRotation(_ angle: CGFloat) -> CGAffineTransform {
        CGAffineTransform(tx: tx, ty: ty, sx: scaleX, sy: scaleY, rotation: angle)
    }
}

public extension CGPoint {

    func toUV(relativeTo size: CGSize) -> CGPoint {
        let u = self.x / size.width + 0.5
        let v = self.y / size.height + 0.5
        return CGPoint(x: u, y: v)
    }

    func toLocal(relativeTo size: CGSize) -> CGPoint {
        let x = size.width * (self.x - 0.5)
        let y = size.height * (self.y - 0.5)
        return CGPoint(x: x, y: y)
    }
}

extension CGAffineTransform {

    static let uvIdentity = CGAffineTransform.identity.translatedBy(x: 0.5, y: 0.5)
}

extension CGPoint {

    func distance(to otherPoint: CGPoint) -> CGPoint {
        CGPoint(x: otherPoint.x - x, y: otherPoint.y - y)
    }

    var inverted: CGPoint {
        self * -1
    }

    static func * (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
        CGPoint(x: lhs.x * rhs, y: lhs.y * rhs)
    }
}

extension CGRect {

    var center: CGPoint {
        CGPoint(x: midX, y: midY)
    }

    func transform(forCenteringIn otherRect: CGRect) -> CGAffineTransform {
        let offset = center.distance(to: otherRect.center)
        return CGAffineTransform(translationX: offset.x, y: offset.y)
    }
}
