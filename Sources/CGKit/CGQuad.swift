
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import CoreGraphics
import Vision
import CoreImage

public struct CGQuad {
  
  public var points : [CGPoint]

  public var topLeft : CGPoint { get { points[0] }}
  public var topRight : CGPoint { get { points[1] }}
  public var bottomRight : CGPoint { get { points[2] }}
  public var bottomLeft : CGPoint { get { points[3] }}
  
  public init( _ v : VNRecognizedTextObservation, _ o : CGImagePropertyOrientation = .up ) {
    let p = [v.topLeft, v.topRight, v.bottomRight, v.bottomLeft]
    
    let angle = atan2((v.topRight.y - v.topLeft.y), (v.topRight.x - v.topLeft.x))
    if abs(angle) < (Double.pi / 8) {
      // orientation is right side up
    } else if angle < -(Double.pi / 8) {
      // text is rotated left
    } else {
      // text is rotated right
    }

        switch o {
    case .up: points = p.map { CGPoint(x: $0.x, y: 1-$0.y)  }
    case .right: points = p.map { CGPoint(x: 1-$0.y, y: 1-$0.x )  }
    case .left: points = p.map { CGPoint(x : $0.y, y: $0.x) }
    default: points = p
    }
  }
  
  public init(_ v : VNRectangleObservation) {
    let p = [v.topLeft, v.topRight, v.bottomRight, v.bottomLeft]
    points = p
  }
  
  public init(topLeft tl : CGPoint, topRight tr: CGPoint, bottomRight br : CGPoint, bottomLeft bl : CGPoint) {
    points = [tl, tr, br, bl]
  }
  
  public init(points p: [CGPoint]) {
    points = p
  }
  
  public init(_ r : CGRect) {
    points = [CGPoint(x: r.minX, y:r.minY ),
              CGPoint(x: r.maxX, y: r.minY),
              CGPoint(x: r.maxX, y: r.maxY),
              CGPoint(x: r.minX, y: r.maxY)]
  }
  
  // FIXME: this isn't right -- it's just a placeholder until I do it right
  public var boundingBox : CGRect { get {
    let origin = CGPoint(x: min(topLeft.x, topRight.x, bottomLeft.x, bottomRight.x),
                         y: min(topLeft.y, topRight.y, bottomLeft.y, bottomRight.y))
    let xx = CGPoint(x: max(topLeft.x, topRight.x, bottomLeft.x, bottomRight.x),
                     y: max(topLeft.y, topRight.y, bottomLeft.y, bottomRight.y))
    let extent = CGSize(width: xx.x - origin.x, height: xx.y - origin.y)
    return CGRect(origin: origin, size: extent)
  }}

  public func intersects(_ other : CGQuad) -> Bool {
    let a = self.contains(other.topLeft) || self.contains(other.topRight) || self.contains(other.bottomLeft) || self.contains(other.bottomRight)
    let b = other.contains(self.topLeft) || other.contains(self.topRight) || other.contains(self.bottomLeft) || other.contains(self.bottomRight)

    return a || b ||
    linesIntersect( (topLeft, topRight), (other.topLeft,    other.bottomLeft)) ||
    linesIntersect( (topLeft, topRight), (other.topRight,   other.bottomRight)) ||
    linesIntersect( (topLeft, topRight), (other.topLeft,    other.topRight)) ||
    linesIntersect( (topLeft, topRight), (other.bottomLeft, other.bottomRight)) ||

    linesIntersect( (bottomLeft, bottomRight), (other.topLeft,    other.bottomLeft)) ||
    linesIntersect( (bottomLeft, bottomRight), (other.topRight,   other.bottomRight)) ||
    linesIntersect( (bottomLeft, bottomRight), (other.topLeft,    other.topRight)) ||
    linesIntersect( (bottomLeft, bottomRight), (other.bottomLeft, other.bottomRight)) ||

    linesIntersect( (topLeft, bottomLeft), (other.topLeft,    other.bottomLeft)) ||
    linesIntersect( (topLeft, bottomLeft), (other.topRight,   other.bottomRight)) ||
    linesIntersect( (topLeft, bottomLeft), (other.topLeft,    other.topRight)) ||
    linesIntersect( (topLeft, bottomLeft), (other.bottomLeft, other.bottomRight)) ||

    linesIntersect( (topRight, bottomRight), (other.topLeft,    other.bottomLeft)) ||
    linesIntersect( (topRight, bottomRight), (other.topRight,   other.bottomRight)) ||
    linesIntersect( (topRight, bottomRight), (other.topLeft,    other.topRight)) ||
    linesIntersect( (topRight, bottomRight), (other.bottomLeft, other.bottomRight))

  }

  public func contains(_ other : CGPoint) -> Bool {
    return other.contained(in: [bottomLeft, bottomRight, topRight, topLeft] )
  }

  public var isRectangle : Bool {
    let eps = CGFloat(1e-5)
    
    let a = atan2(topLeft.y - topRight.y, topLeft.x - topRight.x)
    let b = atan2(bottomLeft.y - bottomRight.y, bottomLeft.x - bottomRight.x)

    let c = atan2(topLeft.y - bottomLeft.y, topLeft.x - bottomLeft.x)
    let d = atan2(topRight.y - bottomRight.y, topRight.x - bottomRight.x)

    return abs(a-b) < eps && abs(c-d) < eps
  }

  public var width : CGFloat {
    return topLeft.distance(to: topRight)
  }

  public var height : CGFloat {
    return topLeft.distance(to: bottomLeft)
  }

  public var angle : CGFloat {
    return atan2(topRight.y - topLeft.y, topRight.x - topLeft.x)
  }
  
  public var area : CGFloat {
    return width * height
  }

  public func intersectionArea(_ o : CGQuad) -> CGFloat {
    return CGKit.intersectionArea(points, o.points)
  }
  
  public func extended() -> CGQuad {
    var tl = self.topLeft
    var tr = self.topRight
    var br = self.bottomRight
    var bl = self.bottomLeft
    
    let eps = CGFloat(1e-10)

    if ( abs(tl.y - tr.y) > abs(tl.x - tr.x)) { // height > width -- spine is vertical
      let ext = CGFloat(0.25)
      tl.y = tl.y + ext
      tr.y = tr.y - ext

      let d1 = self.topRight.x - self.topLeft.x
      if abs(d1) > eps {
        let m1 = (self.topRight.y - self.topLeft.y) / d1 // slope
        let b1 = self.topRight.y - m1 * self.topRight.x // y = mx+b
        tl.x = (tl.y - b1) / m1
        tr.x = (tr.y - b1) / m1
      }

      bl.y = bl.y + ext
      br.y = br.y - ext

      let d2 = self.bottomRight.x - self.bottomLeft.x
      if abs(d2) > eps {
        let m2 = (self.bottomRight.y - self.bottomLeft.y) / d2 // slope
        let b2 = self.bottomRight.y - m2 * self.bottomRight.x // y = mx+b

        bl.x = (bl.y - b2) / m2
        br.x = (br.y - b2) / m2
      }

      //        let sz = theImage.extent.size
      //        kk.stroke(path3, size: sz)

    } else {
      print("don't extend horizontally")
    }
    return CGQuad.init(topLeft: tl, topRight: tr, bottomRight: br, bottomLeft: bl)
  }

  public func applying(_ t : CGAffineTransform) -> CGQuad {
    return CGQuad(points: points.map { $0.applying(t) } )
  }

  public func rotated(_ angle: CGFloat, around: CGPoint? = nil) -> CGQuad {
    let a = around == nil ? center : around!
    let transform = CGAffineTransform(translationX: -a.x, y: -a.y).concatenating(CGAffineTransform(rotationAngle: angle))
      .concatenating(CGAffineTransform(translationX: a.x, y: a.y))
    return self.applying(transform)
  }
  
  /*
  public func rotatedAroundCenter(_ angle : CGFloat) -> CGQuad {
    let ctr = center
    let transform = CGAffineTransform(translationX: -ctr.x, y: -ctr.y).concatenating(CGAffineTransform(rotationAngle: angle)).concatenating(CGAffineTransform(translationX: ctr.x, y: ctr.y))

    return self.applying(transform)
  //  res.bookCandidates = bookCandidates
  }
   */
    
  public func expanded() -> CGQuad {
    let kk = self.rotated(CGFloat.pi-self.angle)
    let yx = CGFloat(0.01)
    let tly = kk.topLeft.y + yx
    let tryy = kk.topRight.y + yx
    let bry = kk.bottomRight.y - yx
    let bly = kk.bottomLeft.y - yx

    let xx = CGFloat(0.05)
    let tlx = kk.topLeft.x - xx
    let blx = kk.bottomLeft.x - xx
    let trx = kk.topRight.x + xx
    let brx = kk.bottomRight.x + xx

    return CGQuad(topLeft: CGPoint(x: tlx, y: tly),
                  topRight: CGPoint(x: trx, y: tryy),
                  bottomRight: CGPoint(x: brx, y: bry),
                  bottomLeft: CGPoint(x: blx, y: bly)
    ).rotated(self.angle-CGFloat.pi)
  }

  public var center : CGPoint {
    let g = boundingBox
    return CGPoint(x: g.origin.x + g.width / 2, y: g.origin.y + g.height / 2)

//    return CGPoint(x: (self.topLeft.x + self.bottomRight.x)/2, y: (self.topLeft.y + self.bottomRight.y)/2 )
  }

  public func getImage(_ theImage : CIImage)  -> CIImage   {
      let width = theImage.extent.width
      let height = theImage.extent.height
/*
    let newimage = theImage.applyingFilter("CIPerspectiveCorrection",
                                            parameters: [
                                              "inputTopLeft": CIVector(cgPoint: CGPoint(x: topLeft.x * width, y: topLeft.y * height)),
                                              "inputTopRight": CIVector(cgPoint: CGPoint(x: topRight.x * width, y: topRight.y * height)),
                                              "inputBottomLeft": CIVector(cgPoint: CGPoint(x: bottomLeft.x * width, y: bottomLeft.y * height)),
                                              "inputBottomRight": CIVector(cgPoint: CGPoint(x: bottomRight.x * width, y: bottomRight.y * height))
                                            ])

  */
    
    let newimage = theImage.oriented(.downMirrored).applyingFilter("CIPerspectiveCorrection",
                                            parameters: [
                                              "inputTopLeft": CIVector(cgPoint: CGPoint(x: topLeft.x * width, y: topLeft.y * height)),
                                              "inputTopRight": CIVector(cgPoint: CGPoint(x: topRight.x * width, y: topRight.y * height)),
                                              "inputBottomLeft": CIVector(cgPoint: CGPoint(x: bottomLeft.x * width, y: bottomLeft.y * height)),
                                              "inputBottomRight": CIVector(cgPoint: CGPoint(x: bottomRight.x * width, y: bottomRight.y * height))
                                            ])

    
    
    // perhaps this is specific to spine vs. cover?
      // if r.boundingBox.width < 0.7  { return }

      //      let newm = newimage.oriented(.right)
      let newm = newimage.oriented( newimage.extent.height > newimage.extent.width ? .left : .up)
    return newm
  }
  

  
  public func coalesce(_ other : CGQuad) -> CGQuad {
    let a = self.angle
    let b = self.rotated(-a, around: CGPoint.zero)
    let c = other.rotated(-a, around: CGPoint.zero)
    
    /*
    let tl = CGPoint(x: min(b.topLeft.x, c.topLeft.x), y: max(b.topLeft.y, c.topLeft.y))
    let tr = CGPoint(x: max(b.topRight.x, c.topRight.x), y: max(b.topRight.y, c.topRight.y))
    let br = CGPoint(x: max(b.bottomRight.x, c.bottomRight.x), y: min(b.bottomRight.y, c.bottomRight.y))
    let bl = CGPoint(x: min(b.bottomLeft.x, c.bottomLeft.x), y: min(b.bottomLeft.y, c.bottomLeft.y))
    // let r = CGQuad(topLeft: tl, topRight: tr, bottomRight: br, bottomLeft: bl)
    */
    
    let k = CGPolygon( (b.points + c.points) )
    return CGQuad(k.boundingBox).rotated(a, around: CGPoint.zero)
  }
}



public func linesIntersect( _ a : (CGPoint, CGPoint), _ b : (CGPoint, CGPoint) ) -> Bool {
let d1 = a.0.isLeft(b.0, b.1)
let d2 = a.1.isLeft(b.0, b.1)
let d3 = b.0.isLeft(a.0, a.1)
let d4 = b.1.isLeft(a.0, a.1)

return ((d1 > 0 && d2 < 0) || (d1 < 0 && d2 > 0)) && ((d3 > 0 && d4 < 0) || (d3 < 0 && d4 > 0))
}

extension CGPoint {
public func rotated(around center: CGPoint, angle: CGFloat) -> CGPoint {
  let transform = CGAffineTransform(translationX: -center.x, y: -center.y).concatenating(CGAffineTransform(rotationAngle: angle)).concatenating(CGAffineTransform(translationX: center.x, y: center.y))
  return applying(transform)
}
}



