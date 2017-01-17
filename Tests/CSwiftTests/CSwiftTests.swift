import XCTest
@testable import CSwift

class CSwiftTests: XCTestCase {
    func testExample() {
        let three = c_add(1, 2)
        XCTAssertEqual(three, 3)
        XCTAssertEqual(C_TEN, 10)
    }


    static var allTests : [(String, (CSwiftTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
        ]
    }
}
