
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import Foundation

/**
 * Area of Intersection of Polygons
 *
 * Algorithm based on http://cap-lore.com/MathPhys/IP/
 *
 * Adapted 9-May-2006 by Lagado
 */

struct IPoint { var x : Int; var y : Int }

struct Vertex {
  var ip : IPoint
  var rx : ClosedRange<Int>
  var ry : ClosedRange<Int>
  var inx : Int
}


private let gamut : Double = 500000000
private let mid : Double = gamut / 2

//--------------------------------------------------------------------------

private func range(_ points : [CGPoint]) -> CGRect {
  var minx = points[0]
  var maxx = points[0]
  for i in 1 ..< points.count {
    minx = CGPoint(x : min(minx.x, points[i].x), y: min(minx.y, points[i].y))
    maxx = CGPoint(x : max(maxx.x, points[i].x), y: max(maxx.y, points[i].y))
  }
  return CGRect.init(origin: minx, size: CGSize(width: maxx.x - minx.x, height: maxx.y - minx.y))
}


private func area(_ a : IPoint, _ p : IPoint, _ q : IPoint) -> Int {
  let jj = p.x * q.y - p.y * q.x + a.x * (p.y - q.y) + a.y * (q.x - p.x);
  return jj
}

private func cntrib(_ f_x : Int, _ f_y : Int, _ t_x : Int, _ t_y : Int, _ w : Int, _ ssss : inout Int) {
  ssss += w * (t_x - f_x) * (t_y + f_y) / 2;
}

private func clem(_ a : (Int, CGPoint), B: CGRect, sclx : Double, scly : Double, fudge: Int ) -> IPoint {
  let xx : CGPoint = a.1
  let xc : Int = a.0
  let ipx : IPoint = IPoint(x: ( Int((xx.x - B.origin.x) * sclx - mid) & ~7) | fudge | (xc & 1),
                            y: ( Int((xx.y - B.origin.y) * scly - mid) & ~7) | fudge)
  return ipx
}

private func fit(_ xa : [CGPoint], fudge: Int, _ B : CGRect, sclx: Double, scly: Double) -> [Vertex] {
  let xae : [(Int, CGPoint)] = Array(xa.enumerated())
  var ixs : [IPoint] = xae.map { (xxx : (Int,CGPoint) ) -> IPoint in
    return clem(xxx, B: B, sclx: sclx, scly: scly, fudge: fudge)
  }
  
  ixs[0].y += (xa.count) & 1
  ixs += [ixs[0]]
  
  let vr = zip(ixs, ixs.dropFirst()).map { (ip2 : (IPoint, IPoint)) -> Vertex in
    let (ip0, ip1) = ip2
    let rx = ip0.x < ip1.x ? ip0.x...ip1.x : ip1.x...ip0.x
    let ry = ip0.y < ip1.y ? ip0.y...ip1.y : ip1.y...ip0.y
    return Vertex.init(ip: ip0, rx: rx, ry: ry, inx: 0)
  }
  return vr + [vr[0]]
}



private func cross(_ a : inout Vertex, _ b : Vertex, _ c : inout Vertex, _ d : Vertex,
                   _ a1 : Double, _ a2 : Double, _ a3 : Double, _ a4 : Double, _ ssss : inout Int) {
  let r1 = a1 / (a1 + a2)
  let r2 = a3 / (a3 + a4)
  
  cntrib(Int( Double(a.ip.x) + r1 * Double(b.ip.x - a.ip.x)),
         Int( Double(a.ip.y) + r1 * Double(b.ip.y - a.ip.y)),
         b.ip.x, b.ip.y, 1,
         &ssss);
  cntrib(d.ip.x, d.ip.y,
         Int( Double(c.ip.x) + r2 * Double(d.ip.x - c.ip.x)),
         Int( Double(c.ip.y) + r2 * Double(d.ip.y - c.ip.y)),
         1,
         &ssss);
  a.inx += 1;
  c.inx -= 1;
}

private func inness(_ P : [Vertex], _ Q : [Vertex], _ ssss : inout Int) {
  var s = 0;
  let p = P[0].ip
  
  for qe in zip(Q, Q.dropFirst()).reversed() {
    if ( qe.0.rx.lowerBound < p.x && p.x < qe.0.rx.upperBound) {
      let sgn = 0 < area(p, qe.0.ip, qe.1.ip);
      s += (sgn != (qe.0.ip.x < qe.1.ip.x) ) ? 0 : (sgn ? -1 : 1);
    }
  }
  for e in zip(P, P.dropFirst()) {
    if (s != 0) {
      cntrib(e.0.ip.x, e.0.ip.y,
             e.1.ip.x, e.1.ip.y, s,
             &ssss);
    }
    s += e.0.inx;
  }
}

//-------------------------------------------------------------------------

public func intersectionArea(_ a : [CGPoint], _ b : [CGPoint]) -> CGFloat {
  let na = a.count;
  let nb = b.count;
  
  if (na < 3 || nb < 3) {
    return 0
  }
  
  var ssss : Int = 0
  
  let bbox = range(a + b)
  
  let rngx = bbox.maxX - bbox.minX;
  let sclx = gamut / rngx;
  let rngy = bbox.maxY - bbox.minY;
  let scly = gamut / rngy;
  let ascale = sclx * scly;
  
  var ipa = fit(a, fudge: 0, bbox, sclx: sclx, scly: scly);
  var ipb = fit(b, fudge: 2, bbox, sclx: sclx, scly: scly);
  
  for j in 0..<ipa.count-1 {
    for k in 0..<ipb.count-1 {
      if ( ipa[j].rx.overlaps(ipb[k].rx) && ipa[j].ry.overlaps(ipb[k].ry)) {
        let a1 = -area(ipa[j].ip, ipb[k].ip, ipb[k + 1].ip);
        let a2 = area(ipa[j + 1].ip, ipb[k].ip, ipb[k + 1].ip);
        let o = a1 < 0;
        if (o == (a2 < 0) ) {
          let a3 = area(ipb[k].ip, ipa[j].ip, ipa[j + 1].ip);
          let a4 = -area(ipb[k + 1].ip, ipa[j].ip, ipa[j + 1].ip);
          if ( (a3 < 0) == (a4 < 0) ) {
            if (o) {
              cross( &ipa[j], ipa[j + 1], &ipb[k], ipb[k + 1],
                     Double(a1), Double(a2), Double(a3), Double(a4), &ssss)
            } else {
              cross( &ipb[k], ipb[k + 1], &ipa[j], ipa[j + 1],
                     Double(a3), Double(a4), Double(a1), Double(a2), &ssss );
            }
          }
        }
      }
    }
  }
  
  inness(ipa, ipb, &ssss);
  inness(ipb, ipa, &ssss);
  
  return CGFloat(ssss) / CGFloat(ascale);
}

