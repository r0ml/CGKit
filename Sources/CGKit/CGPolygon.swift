
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import CoreGraphics

public struct CGPolygon {
  var points : [CGPoint]
  
  public init(_ p : [CGPoint]) {
    self.points = p
  }
  
  public func intersectionArea(_ o : CGPolygon) -> CGFloat {
    return CGKit.intersectionArea(points, o.points)
  }
  
  public var area : CGFloat { get {
    let first = points[0]
    var last = first
    var area : CGFloat = 0
    for p in points.dropFirst() {
      area += p.x * last.y - last.x * p.y
      last = p
     }
     area += first.x * last.y - last.x * first.y;
     return area / 2;
    }}

  public var convexHull : [CGPoint] {
    let (bottomPointIdx, _) = points.enumerated().min(by: { if $0.element.y < $1.element.y { return true} else if $0.element.y == $1.element.y { return $0.element.x < $1.element.x } else { return false } })! // smallest y
    var p = bottomPointIdx
    let pp = points[p]
    var q = 0
    let k = points.compactMap { (m : CGPoint) -> (CGPoint, CGFloat)? in
      let d = m.distance(to: pp)
      if d == 0 { return nil } else { return (m, (m.x - pp.x) / d ) }
    }
    let kk = k.sorted(by:  { if $0.1 > $1.1 { return true} else if $0.1 == $1.1 { return $0.0.distance(to: pp) < $1.0.distance(to: pp) } else { return false} } )
    var kj = [CGPoint]()
    for i in 0..<kk.count-1 {
      if kk[i].1 == kk[i+1].1 { continue }
      kj.append(kk[i].0)
    }
    kj.append(kk.last!.0)
    // now I have the non-colinear points

    var hull = [pp, kj[0], kj[1]]

    for jj in kj.dropFirst(2) {
      while true {
        let mm = [ hull[hull.count-2], hull[hull.count-1], jj ]
        let oo = calculateOrientation(mm[0], mm[1], mm[2])
        if oo != .counterClockwise { hull.removeLast() }
        else { hull.append(jj); break }
      }
    }
    // now I have the points sorted by angle (I used cosine)
    // The comparator algorithm that uses cross product has to compute the cross product on every compare.
    // The division is more expensive, but it only needs to be done once for each point

    return hull
  }
  
  public var boundingBox : CGRect { get {
    var origin = points[0]
    var fp = points[0]
    for p in points.dropFirst() {
      origin = CGPoint(x: min(origin.x, p.x), y: min(origin.y, p.y))
      fp = CGPoint(x: max(fp.x, p.x), y: max(fp.y, p.y))
    }
    let extent = CGSize(width: fp.x - origin.x, height: fp.y - origin.y)
    return CGRect(origin: origin, size: extent)
  }}

  
}



private enum Orientation {
  case straight, clockwise, counterClockwise
}

private func calculateOrientation(_ p: CGPoint, _ q: CGPoint, _ r: CGPoint) -> Orientation {
  let val = (q.y - p.y) * (r.x - q.x) - (q.x - p.x) * (r.y - q.y)

  if val == 0 {
    return .straight
  } else if val > 0 {
    return .clockwise
  } else {
    return .counterClockwise
  }
}
