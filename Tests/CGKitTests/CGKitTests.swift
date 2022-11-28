import XCTest
@testable import CGKit

final class CGKitTests: XCTestCase {
  func testExample() throws {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct
    // results.
    
    
    //        XCTAssertEqual(CGKit().text, "Hello, World!")
  }
  
  
  
  //-------------------------------------------------------------------------
  // test the code
  
  private func toPoints2DArray(_ a : [[Double]]) -> [CGPoint]  {
    return a.map { aa in return CGPoint(x: aa[0], y: aa[1])
    }
  }
  
  private func trial(_ a : [[Double]], _ b : [[Double]]) -> (Double, Double)   {
    let A = toPoints2DArray(a);
    let B = toPoints2DArray(b);
    
    
    return (intersectionArea(A, B), intersectionArea(A, A))
  }
  
  func testIntersectArea() throws {
    let a1 : [[Double]] = [[2,3], [2,3], [2,3], [2,4], [3,3], [2,3], [2,3]]
    let b1 : [[Double]] = [[1,1], [1,4], [4,4], [4,1], [1,1]] // 1/2, 1/2
    // The redundant vertices above are to provoke errors
    // as good test cases should.
    // It is not necessary to duplicate the first vertex at the end.
    
    let a2 : [[Double]] = [[1,7], [4,7], [4, 6], [2,6], [2, 3], [4,3], [4,2], [1,2]]
    let b2 : [[Double]] = [[3,1], [5,1], [5,4], [3,4], [3,5], [6,5], [6,0], [3,0]] // 0, 9
    
    let a3 : [[Double]] = [[1,1], [1,2], [2,1], [2,2]]
    let b3 : [[Double]] = [[0,0], [0,4], [4,4], [4,0]] // 0, 1/2
    
    let a4 : [[Double]] = [[0,0], [3,0], [3,2], [1,2], [1,1], [2,1], [2,3], [0,3]]
    let b4 : [[Double]] = [[0,0], [0,4], [4,4], [4,0]] // -9, 11
    
    let a5 : [[Double]] = [[0,0], [1,0], [0,1]]
    let b5 : [[Double]] = [[0,0], [0,1], [1,1], [1,0]] // -1/2, 1/2
    
    let a6 : [[Double]] = [[1, 3] , [2, 3] , [2, 0] , [1, 0] ]
    let b6 : [[Double]] = [[0, 1] , [3, 1] , [3, 2] , [0, 2] ] // -1, 3
    
    let a7 : [[Double]] = [[0,0], [0,2], [2,2], [2,0]]
    let b7 : [[Double]] = [[1, 1], [3, 1], [3, 3], [1, 3]] // -1, 4
    
    let a8 : [[Double]] = [[0,0], [0,4], [4,4], [4,0]]
    let b8 : [[Double]] = [[1,1], [1,2], [2,2], [2,1]] // 1, 16
    
    let (r1a, r1b) = trial(a1, b1)
    XCTAssertEqual(r1a, 0.5, accuracy: 0.0001, "r1a")
    XCTAssertEqual(r1b, 0.5, accuracy: 0.0001, "r1b")
    let (r2a, r2b) = trial(a2, b2)
    XCTAssertEqual(r2a, 0, accuracy: 0.0001,  "r2a")
    XCTAssertEqual(r2b, 9, accuracy: 0.0001, "r2b")
    let (r3a, r3b) = trial(a3, b3)
    XCTAssertEqual(r3a, 0, accuracy: 0.0001, "r3a")
    XCTAssertEqual(r3b, 0.5, accuracy: 0.0001, "r3b")
    let (r4a, r4b) = trial(a4, b4)
    XCTAssertEqual(r4a, -9, accuracy: 0.0001, "r4a")
    XCTAssertEqual(r4b, 11, accuracy: 0.0001, "r4b")
    let (r5a, r5b) = trial(a5, b5)
    XCTAssertEqual(r5a, -0.5, accuracy: 0.0001, "r5a")
    XCTAssertEqual(r5b, 0.5, accuracy: 0.0001, "r5b")
    let (r6a, r6b) = trial(a6, b6)
    XCTAssertEqual(r6a, -1, accuracy: 0.0001, "r6a")
    XCTAssertEqual(r6b, 3, accuracy: 0.0001, "r6b")
    let (r7a, r7b) = trial(a7, b7)
    XCTAssertEqual(r7a, -1, accuracy: 0.0001, "r7a")
    XCTAssertEqual(r7b, 4, accuracy: 0.0001, "r7b")
    let (r8a, r8b) = trial(a8, b8)
    XCTAssertEqual(r8a, 1, accuracy: 0.0001, "r8a")
    XCTAssertEqual(r8b, 16, accuracy: 0.0001, "r8b")
  }
  
  func testConvexHull() throws {
    let p = [ CGPoint(x: 0, y: 3), CGPoint(x: 1, y: 1), CGPoint(x: 2, y: 2),
              CGPoint(x: 4, y: 4), CGPoint(x: 0, y: 0), CGPoint(x: 1, y: 2),
              CGPoint(x: 3, y: 1), CGPoint(x: 3, y: 3) ]
    let q = CGPolygon(p).convexHull
    let res = [ CGPoint(x: 0, y: 0), CGPoint(x: 3, y: 1),  CGPoint(x: 4, y: 4), CGPoint(x: 0, y: 3) ]
    XCTAssertEqual(q, res, "convex hull")
  }
}
