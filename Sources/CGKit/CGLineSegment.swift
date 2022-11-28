
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import CoreGraphics

public struct CGLineSegment {
  var p1 : CGPoint
  var p2 : CGPoint
  
  public init(_ a : CGPoint, _ b : CGPoint) {
    p1 = a
    p2 = b
  }
  
  public var length : CGFloat { get {
    return p1.distance(to: p2)
  }}
  
  public func distance(to p3: CGPoint) -> CGFloat {
    let px = p2.x - p1.x
    let py = p2.y - p1.y
    let pp = px * px + py * py
    if pp == 0 { return p3.distance(to: p1) }
    let u = ((p3.x - p1.x) * (p2.x - p1.x)+(p3.y - p1.y) * (p2.y - p1.y)) / pp
    if u < 0 { return p1.distance(to: p3) }
    if u > 1 { return p2.distance(to: p3) }
    return CGPoint(x: p1.x + u * (p2.x - p1.x), y: p1.y + u * (p2.y - p1.y)).distance(to: p3)
  }
}
